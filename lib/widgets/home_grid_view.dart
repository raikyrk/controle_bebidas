// lib/widgets/home_grid_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../produto.dart'; // Importa a classe Produto

class HomeGridView extends StatelessWidget {
  // Parâmetros de Dados e Lógica (recebidos do Orquestrador/State Holder)
  final Map<String, List<Produto>> categoriasMap;
  final int totalFardos;
  final int totalAvulsas;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onCategorySelected;
  
  // Parâmetros de Animação e Layout
  final AnimationController shimmerController;
  final AnimationController pulseController;
  final double scaleFactor;
  final int Function(double) getCrossAxisCount;
  final double Function(int) getChildAspectRatio;
  
  // Parâmetros de Serviço
  final Map<String, Color> colors;
  final IconData Function(String) getCategoryIcon;

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
    required this.colors,
    required this.getCategoryIcon,
  });

  // Helpers para Cores (para simplificar o código de build)
  Color get primaryOrange => colors['primaryOrange']!;
  Color get lightOrange => colors['lightOrange']!;
  Color get deepOrange => colors['deepOrange']!;
  Color get accentBlue => colors['accentBlue']!;
  Color get accentPurple => colors['accentPurple']!;
  Color get lightGray => colors['lightGray']!;
  Color get borderGray => colors['borderGray']!;
  Color get textDark => colors['textDark']!;
  Color get textLight => colors['textLight']!;
  Color get cardShadow => colors['cardShadow']!;
  Color get successGreen => colors['successGreen']!;
  Color get warningOrange => colors['warningOrange']!;
  Color get warningYellow => colors['warningYellow']!;
  Color get zeroStock => colors['zeroStock']!;
  Color get backgroundGradientStart => colors['backgroundGradientStart']!;
  Color get backgroundGradientEnd => colors['backgroundGradientEnd']!;

  // ===================================
  // 🔨 WIDGET PRINCIPAL (VIEW DE GRID)
  // ===================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundGradientStart, backgroundGradientEnd],
        ),
      ),
      child: Column(
        children: [
          // HEADER DE VISÃO GERAL
          _buildGeneralHeader(),

          // GRID DE CATEGORIAS
          Expanded(
            child: isLoading
                ? _buildShimmerGrid(context)
                : categoriasMap.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: onRefresh,
                        color: primaryOrange,
                        backgroundColor: Colors.white,
                        strokeWidth: 3.5,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
                            final childAspectRatio = getChildAspectRatio(crossAxisCount);
                            final padding = constraints.maxWidth < 500 ? 20.0 : 28.0;

                            return GridView.builder(
                              padding: EdgeInsets.all(padding),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: categoriasMap.length,
                              itemBuilder: (context, index) {
                                final categoria = categoriasMap.keys.elementAt(index);
                                final itens = categoriasMap[categoria]!;
                                final totalItens = itens.fold(0, (s, p) => s + p.fardos + p.avulsas);
                                final emEstoque = itens.where((p) => p.fardos > 0 || p.avulsas > 0).length;

                                return _buildCategoriaCardModerno(
                                  categoria,
                                  itens.length,
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
  // 🏗️ WIDGETS DE CONSTRUÇÃO
  // ===================================

  Widget _buildGeneralHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24 * scaleFactor,
              32 * scaleFactor,
              24 * scaleFactor,
              28 * scaleFactor,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
            ),
            child: Row(
              children: [
                // Ícone principal com animação
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(18 * scaleFactor),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          // Removido 'const' pois cores são variáveis (embora estáticas)
                          colors: [primaryOrange, deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryOrange.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 32 * scaleFactor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20 * scaleFactor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestão de Estoque',
                        style: GoogleFonts.poppins(
                          fontSize: 28 * scaleFactor,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scaleFactor,
                          vertical: 6 * scaleFactor,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryOrange.withOpacity(0.1),
                              lightOrange.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryOrange.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 16 * scaleFactor,
                              color: primaryOrange,
                            ),
                            SizedBox(width: 6 * scaleFactor),
                            Text(
                              '${categoriasMap.length} categorias',
                              style: GoogleFonts.inter(
                                fontSize: 13 * scaleFactor,
                                color: primaryOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 12 * scaleFactor),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12 * scaleFactor),
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 16 * scaleFactor,
                              color: accentBlue,
                            ),
                            SizedBox(width: 6 * scaleFactor),
                            Text(
                              '$totalFardos fardos • $totalAvulsas avulsas',
                              style: GoogleFonts.inter(
                                fontSize: 13 * scaleFactor,
                                color: accentBlue,
                                fontWeight: FontWeight.w700,
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

  Widget _buildCategoriaCardModerno(
    String categoria,
    int totalProdutos,
    int totalItens,
    int emEstoque,
    int index,
  ) {
    final semEstoque = totalItens == 0;
    final baixoEstoque = totalItens > 0 && totalItens < 8;
    final estoqueOk = !semEstoque && !baixoEstoque;

    Color primaryColor = estoqueOk ? successGreen : (semEstoque ? this.primaryOrange : warningOrange);
    Color secondaryColor = estoqueOk ? const Color(0xFF00D2AB) : (semEstoque ? lightOrange : warningOrange); 

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 40.0 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onCategorySelected(categoria),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.white.withOpacity(0.95)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 8,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.all(18 * scaleFactor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Ícone Principal da Categoria
                            Container(
                              padding: EdgeInsets.all(12 * scaleFactor),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow( // CORRIGIDO: Removido 'BoxBoxShadow'
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                getCategoryIcon(categoria),
                                color: Colors.white,
                                size: 24 * scaleFactor,
                              ),
                            ),
                            
                            // Badge de Status (Pulsação)
                            if (semEstoque || baixoEstoque)
                              AnimatedBuilder(
                                animation: pulseController,
                                builder: (context, child) => Transform.scale(
                                  scale: 1.0 + (pulseController.value * 0.1),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scaleFactor,
                                      vertical: 5 * scaleFactor,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      semEstoque ? Icons.warning_rounded : Icons.info_rounded,
                                      color: Colors.white,
                                      size: 14 * scaleFactor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        SizedBox(height: 12 * scaleFactor),
                        
                        // Título da Categoria
                        Flexible(
                          child: Text(
                            categoria,
                            style: GoogleFonts.poppins(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        SizedBox(height: 12 * scaleFactor),
                        
                        // Cartão de Estatísticas
                        Container(
                          padding: EdgeInsets.all(12 * scaleFactor),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                lightGray,
                                lightGray.withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderGray.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatRowModerno(
                                '$totalItens',
                                'Total Itens',
                                Icons.inventory_2_rounded,
                                semEstoque ? zeroStock : textDark,
                              ),
                              SizedBox(height: 8 * scaleFactor),
                              Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      borderGray.withOpacity(0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 8 * scaleFactor),
                              _buildStatRowModerno(
                                '$emEstoque',
                                'Em Estoque',
                                Icons.check_circle_rounded,
                                primaryColor,
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
      ),
    );
  }

  Widget _buildStatRowModerno(String value, String label, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(5 * scaleFactor),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14 * scaleFactor, color: color),
              ),
              SizedBox(width: 8 * scaleFactor),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8 * scaleFactor),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scaleFactor,
            vertical: 3 * scaleFactor,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14 * scaleFactor,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ===================================
  // 👻 SHIMMER E EMPTY STATE
  // ===================================

  Widget _buildShimmerGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = getChildAspectRatio(crossAxisCount);
        final padding = constraints.maxWidth < 500 ? 20.0 : 28.0;

        return GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: childAspectRatio,
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
        padding: EdgeInsets.all(20 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderGray.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(52.0, 52.0, 16.0),
                _shimmerBox(36.0, 28.0, 10.0),
              ],
            ),
            SizedBox(height: 16 * scaleFactor),
            _shimmerBox(140.0, 20.0, 10.0),
            const Spacer(),
            _shimmerBox(double.infinity, 80.0, 16.0),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, [double r = 8.0]) {
    final effectiveW = w * scaleFactor;
    final effectiveH = h * scaleFactor;

    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) => Container(
        width: effectiveW.isFinite ? effectiveW : null,
        height: effectiveH.isFinite ? effectiveH : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + shimmerController.value * 2, 0),
            end: Alignment(1.0 + shimmerController.value * 2, 0),
            colors: [
              borderGray.withOpacity(0.3),
              lightGray,
              borderGray.withOpacity(0.3),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Container(
                padding: EdgeInsets.all(40 * scaleFactor),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lightGray,
                      lightGray.withOpacity(0.5),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderGray.withOpacity(0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cardShadow,
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 72 * scaleFactor,
                  color: textLight.withOpacity(0.6),
                ),
              ),
            ),
          ),
          SizedBox(height: 32 * scaleFactor),
          Text(
            'Nenhuma categoria encontrada',
            style: GoogleFonts.poppins(
              fontSize: 24 * scaleFactor,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: 12 * scaleFactor),
          Text(
            'Adicione produtos ou verifique a conexão',
            style: GoogleFonts.inter(
              fontSize: 15 * scaleFactor,
              color: textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}