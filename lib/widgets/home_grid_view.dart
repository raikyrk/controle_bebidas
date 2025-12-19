// lib/widgets/home_grid_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../produto.dart';

class HomeGridView extends StatelessWidget {
  // === DADOS E LÓGICA (Mantidos) ===
  final Map<String, List<Produto>> categoriasMap;
  final int totalFardos;
  final int totalAvulsas;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onCategorySelected;
  
  // === PARÂMETROS DE LAYOUT (Mantidos) ===
  final AnimationController shimmerController;
  final AnimationController pulseController;
  final double scaleFactor;
  final int Function(double) getCrossAxisCount;
  final double Function(int) getChildAspectRatio;
  
  // === SERVIÇOS (Mantidos) ===
  final IconData Function(String) getCategoryIcon;
  // O map 'colors' antigo será ignorado em favor da nova paleta Fire Mode,
  // mas mantive no construtor para não quebrar quem chama o widget.
  final Map<String, Color> colors; 

  const HomeGridView({
    super.key,
    required this.categoriasMap,
    required this.totalFardos,
    required this.totalAvulsas,
    required this.isLoading,
    required this.onRefresh,
    required this.onCategorySelected,
    required this.shimmerController,
    required this.pulseController,
    required this.scaleFactor,
    required this.getCrossAxisCount,
    required this.getChildAspectRatio,
    required this.colors, // Mantido apenas para compatibilidade
    required this.getCategoryIcon,
  });

  // === PALETA FIRE MODE ===
  static const Color pureBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color brightOrange = Color(0xFFFF4500);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color softOrange = Color(0xFFFF8C42);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color grayText = Color(0xFFAAAAAA);
  static const Color borderGray = Color(0xFF333333);

  // ===================================
  // 🔨 WIDGET PRINCIPAL
  // ===================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pureBlack, // Fundo Totalmente Preto
      child: Column(
        children: [
          // HEADER DE VISÃO GERAL (Dark)
          _buildGeneralHeader(),

          // GRID DE CATEGORIAS
          Expanded(
            child: isLoading
                ? _buildShimmerGrid(context)
                : categoriasMap.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: onRefresh,
                        color: pureBlack,
                        backgroundColor: brightOrange, // Laranja no refresh
                        strokeWidth: 3.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
                            final childAspectRatio = getChildAspectRatio(crossAxisCount);
                            final padding = constraints.maxWidth < 500 ? 20.0 : 28.0;

                            return GridView.builder(
                              padding: EdgeInsets.all(padding),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20, // Espaçamento levemente reduzido
                                mainAxisSpacing: 20,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: categoriasMap.length,
                              itemBuilder: (context, index) {
                                final categoria = categoriasMap.keys.elementAt(index);
                                final itens = categoriasMap[categoria]!;
                                final totalItens = itens.fold(0, (s, p) => s + p.fardos + p.avulsas);
                                final emEstoque = itens.where((p) => p.fardos > 0 || p.avulsas > 0).length;

                                return _buildCategoriaCardFire(
                                  categoria,
                                  totalItens,
                                  emEstoque,
                                  index,
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ===================================
  // 🏗️ HEADER FIRE MODE
  // ===================================

  Widget _buildGeneralHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: deepBlack.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: borderGray, width: 1)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24 * scaleFactor,
              32 * scaleFactor,
              24 * scaleFactor,
              24 * scaleFactor,
            ),
            child: Row(
              children: [
                // Ícone Principal (Dashboard)
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [brightOrange, neonOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: brightOrange.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.dashboard_rounded,
                    color: pureWhite,
                    size: 28 * scaleFactor,
                  ),
                ),
                SizedBox(width: 20 * scaleFactor),
                
                // Textos do Header
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visão Geral',
                        style: GoogleFonts.poppins(
                          fontSize: 26 * scaleFactor,
                          fontWeight: FontWeight.w700,
                          color: pureWhite,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 6 * scaleFactor),
                      
                      // Chip de Resumo
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scaleFactor,
                          vertical: 6 * scaleFactor,
                        ),
                        decoration: BoxDecoration(
                          color: cardBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderGray),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_rounded, size: 14 * scaleFactor, color: brightOrange),
                            SizedBox(width: 8 * scaleFactor),
                            Text(
                              '$totalFardos fardos  |  $totalAvulsas avulsas',
                              style: GoogleFonts.poppins(
                                fontSize: 13 * scaleFactor,
                                color: grayText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================
  // 🔥 CARDS DO GRID (FIRE MODE)
  // ===================================

  Widget _buildCategoriaCardFire(
    String categoria,
    int totalItens,
    int emEstoque,
    int index,
  ) {
    final semEstoque = totalItens == 0;
    final baixoEstoque = totalItens > 0 && totalItens < 8;

    // Cores (Mantidas)
    Color mainColor = semEstoque ? grayText : (baixoEstoque ? softOrange : brightOrange);
    
    // Pegamos o ícone atual
    IconData iconData = getCategoryIcon(categoria);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 30.0 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onCategorySelected(categoria);
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            clipBehavior: Clip.antiAlias, // Importante para cortar o ícone vazado
            decoration: BoxDecoration(
              color: cardBlack,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: semEstoque ? borderGray : borderGray.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                if (!semEstoque)
                  BoxShadow(
                    color: mainColor.withOpacity(0.15), // Glow reduzido e mais difuso
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Stack(
              children: [
                // 1. ÍCONE DE FUNDO (WATERMARK)
                // Ele fica gigante, rotacionado e no canto direito inferior
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Transform.rotate(
                    angle: -0.2, // Leve inclinação
                    child: Icon(
                      iconData,
                      size: 100 * scaleFactor, // MUITO GRANDE
                      color: mainColor.withOpacity(0.07), // QUASE TRANSPARENTE
                    ),
                  ),
                ),

                // 2. CONTEÚDO
                Padding(
                  padding: EdgeInsets.all(20 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: Badge de Status (Se necessário) e Título
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              categoria,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18 * scaleFactor, // Aumentei a fonte
                                fontWeight: FontWeight.w700,
                                color: pureWhite,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (baixoEstoque || semEstoque)
                             Container(
                               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                 color: semEstoque ? borderGray : brightOrange.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(6),
                               ),
                               child: Text(
                                 semEstoque ? 'ZERADO' : 'BAIXO',
                                 style: GoogleFonts.poppins(
                                   fontSize: 10 * scaleFactor,
                                   fontWeight: FontWeight.w900,
                                   color: semEstoque ? grayText : brightOrange,
                                 ),
                               ),
                             ),
                        ],
                      ),

                      const Spacer(), // Empurra os stats para baixo

                      // Rodapé: Estatísticas Limpas
                      Row(
                        children: [
                          // Total
                          _buildCleanStat(
                             value: '$totalItens', 
                             label: 'Total', 
                             color: grayText
                          ),
                          
                          SizedBox(width: 16 * scaleFactor),
                          
                          // Ativos
                          _buildCleanStat(
                             value: '$emEstoque', 
                             label: 'Ativos', 
                             color: semEstoque ? grayText : brightOrange
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para stats mais limpos (sem ícones pequenos)
  Widget _buildCleanStat({required String value, required String label, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20 * scaleFactor, // Número grande
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.0,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11 * scaleFactor,
            color: grayText.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12 * scaleFactor, color: color.withOpacity(0.7)),
        SizedBox(width: 6 * scaleFactor),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13 * scaleFactor,
                fontWeight: FontWeight.w700,
                color: pureWhite,
                height: 1.0,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10 * scaleFactor,
                color: grayText,
                height: 1.0,
              ),
            ),
          ],
        )
      ],
    );
  }

  // ===================================
  // 💀 SHIMMER LOADING (DARK MODE)
  // ===================================

  Widget _buildShimmerGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          padding: EdgeInsets.all(constraints.maxWidth < 500 ? 20.0 : 28.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: getChildAspectRatio(crossAxisCount),
          ),
          itemCount: 6,
          itemBuilder: (context, i) => _shimmerCard(),
        );
      },
    );
  }

  Widget _shimmerCard() {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          color: cardBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderGray),
        ),
        child: Padding(
          padding: EdgeInsets.all(18 * scaleFactor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(45, 45, 14),
                  _shimmerBox(40, 20, 8),
                ],
              ),
              Spacer(),
              _shimmerBox(100, 20, 6),
              SizedBox(height: 10),
              _shimmerBox(double.infinity, 40, 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, double r) {
    return Container(
      width: w * scaleFactor,
      height: h * scaleFactor,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + shimmerController.value * 2, 0),
          end: Alignment(1.0 + shimmerController.value * 2, 0),
          colors: [
            deepBlack,
            Color(0xFF2A2A2A), // Um cinza um pouco mais claro para o brilho
            deepBlack,
          ],
        ),
      ),
    );
  }
  
  // ===================================
  // 📭 EMPTY STATE (DARK)
  // ===================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30 * scaleFactor),
            decoration: BoxDecoration(
              color: cardBlack,
              shape: BoxShape.circle,
              border: Border.all(color: borderGray),
              boxShadow: [
                 BoxShadow(
                   color: brightOrange.withOpacity(0.05),
                   blurRadius: 30,
                   spreadRadius: 10,
                 )
              ]
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60 * scaleFactor,
              color: borderGray,
            ),
          ),
          SizedBox(height: 24 * scaleFactor),
          Text(
            'Nada por aqui',
            style: GoogleFonts.poppins(
              fontSize: 22 * scaleFactor,
              fontWeight: FontWeight.w700,
              color: pureWhite,
            ),
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
            'Adicione produtos para começar.',
            style: GoogleFonts.poppins(
              fontSize: 14 * scaleFactor,
              color: grayText,
            ),
          ),
        ],
      ),
    );
  }
}