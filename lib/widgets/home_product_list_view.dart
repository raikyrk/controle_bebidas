// lib/widgets/home_product_list_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';

import '../produto.dart';

class HomeProductListView extends StatelessWidget {
  final String categoria;
  final List<Produto> itens;
  final VoidCallback onBack;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Function(int, String, String) onQuantidadeChanged;
  final Map<int, TextEditingController> fardosControllers;
  final Map<int, TextEditingController> avulsasControllers;
  final AnimationController shimmerController;
  final AnimationController pulseController;
  final double scaleFactor;
  final Map<String, Color> colors; // Mantido para compatibilidade, mas ignorado visualmente
  final IconData Function(String) getCategoryIcon;

  const HomeProductListView({
    super.key,
    required this.categoria,
    required this.itens,
    required this.onBack,
    required this.isLoading,
    required this.onRefresh,
    required this.onQuantidadeChanged,
    required this.fardosControllers,
    required this.avulsasControllers,
    required this.shimmerController,
    required this.pulseController,
    required this.scaleFactor,
    required this.colors,
    required this.getCategoryIcon,
  });

  // === PALETA FIRE MODE (Igual ao Grid) ===
  static const Color pureBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color brightOrange = Color(0xFFFF4500);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color grayText = Color(0xFFAAAAAA);
  static const Color borderGray = Color(0xFF333333);
  static const Color inputBg = Color(0xFF111111); // Fundo dos inputs

  // ===================================
  // 🔨 WIDGET PRINCIPAL
  // ===================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pureBlack, // Fundo Preto Absoluto
      child: Column(
        children: [
          // HEADER DARK
          _buildDetailHeader(context),

          // LISTA DE PRODUTOS
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: pureBlack,
              backgroundColor: brightOrange, // Laranja no refresh
              strokeWidth: 3.0,
              child: isLoading
                  ? _buildShimmerLista()
                  : itens.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            20 * scaleFactor, 
                            20 * scaleFactor, 
                            20 * scaleFactor, 
                            100 * scaleFactor // Espaço extra no fim para não cortar
                          ),
                          itemCount: itens.length,
                          itemBuilder: (context, i) => Padding(
                            padding: EdgeInsets.only(bottom: 20 * scaleFactor),
                            child: _buildProdutoCardFire(context, itens[i], i),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================
  // 🏗️ HEADER (DARK GLASS)
  // ===================================

  Widget _buildDetailHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: deepBlack.withOpacity(0.85),
        border: Border(bottom: BorderSide(color: borderGray, width: 1)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20 * scaleFactor,
              32 * scaleFactor, // SafeArea top aproximado
              20 * scaleFactor,
              20 * scaleFactor,
            ),
            child: Row(
              children: [
                // BOTÃO VOLTAR
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: EdgeInsets.all(12 * scaleFactor),
                      decoration: BoxDecoration(
                        color: cardBlack,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderGray),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: pureWhite,
                        size: 22 * scaleFactor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16 * scaleFactor),

                // ÍCONE + TÍTULO
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10 * scaleFactor),
                        decoration: BoxDecoration(
                           color: brightOrange.withOpacity(0.15),
                           borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getCategoryIcon(categoria),
                          color: brightOrange,
                          size: 20 * scaleFactor,
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
                        child: Text(
                          categoria,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 22 * scaleFactor,
                            fontWeight: FontWeight.w700,
                            color: pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // CONTADOR
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderGray),
                  ),
                  child: Text(
                    '${itens.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 14 * scaleFactor,
                      fontWeight: FontWeight.w700,
                      color: grayText,
                    ),
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
  // 🔥 CARD DO PRODUTO (FIRE MODE)
  // ===================================

  Widget _buildProdutoCardFire(BuildContext context, Produto p, int index) {
    // Pegando valores atuais
    final valFardos = int.tryParse(fardosControllers[p.id]?.text ?? '0') ?? 0;
    final valAvulsas = int.tryParse(avulsasControllers[p.id]?.text ?? '0') ?? 0;
    
    final isZero = valFardos == 0 && valAvulsas == 0;
    final isLow = !isZero && (valFardos <= 2 && valAvulsas <= 5); // Lógica simples de baixo estoque

    // Cores de estado
    Color statusBorder = isZero ? borderGray : (isLow ? neonOrange : Colors.greenAccent);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20.0 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isZero ? borderGray : statusBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            if (!isZero)
              BoxShadow(
                color: statusBorder.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            // PARTE SUPERIOR: NOME E STATUS
            Padding(
              padding: EdgeInsets.fromLTRB(20 * scaleFactor, 20 * scaleFactor, 20 * scaleFactor, 10 * scaleFactor),
              child: Row(
                children: [
                  // Indicador Visual (Bolinha)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 12 * scaleFactor,
                    height: 12 * scaleFactor,
                    decoration: BoxDecoration(
                      color: isZero ? borderGray : statusBorder,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if(!isZero)
                           BoxShadow(color: statusBorder.withOpacity(0.6), blurRadius: 8)
                      ]
                    ),
                  ),
                  SizedBox(width: 16 * scaleFactor),
                  
                  // Nome do Produto
                  Expanded(
                    child: Text(
                      p.nome,
                      style: GoogleFonts.poppins(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: isZero ? grayText : pureWhite,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // LINHA DIVISÓRIA SUAVE
            Divider(color: borderGray.withOpacity(0.5), height: 1),

            // PARTE INFERIOR: INPUTS
            Padding(
              padding: EdgeInsets.all(16 * scaleFactor),
              child: Row(
                children: [
                  // Input Fardos (Laranja)
                  Expanded(
                    child: _buildFireInput(
                      context,
                      label: 'FARDOS',
                      controller: fardosControllers[p.id]!,
                      produtoId: p.id,
                      tipo: 'f',
                      accentColor: brightOrange,
                    ),
                  ),
                  
                  SizedBox(width: 16 * scaleFactor),
                  
                  // Input Avulsas (Branco/Cinza para contraste)
                  Expanded(
                    child: _buildFireInput(
                      context,
                      label: 'AVULSAS',
                      controller: avulsasControllers[p.id]!,
                      produtoId: p.id,
                      tipo: 'a',
                      accentColor: pureWhite, // Diferente para não confundir
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================
  // ⌨️ INPUT FIRE MODE (SLOT DIGITAL)
  // ===================================

  Widget _buildFireInput(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required int produtoId,
    required String tipo,
    required Color accentColor,
  }) {
    // Verifica se tem valor para acender a cor
    final hasValue = (int.tryParse(controller.text) ?? 0) > 0;
    final activeColor = hasValue ? accentColor : grayText;

    return Container(
      decoration: BoxDecoration(
        color: inputBg, // Fundo bem escuro
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue ? accentColor.withOpacity(0.3) : borderGray,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // LABEL PEQUENA NO TOPO
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: hasValue ? accentColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10 * scaleFactor,
                fontWeight: FontWeight.w800,
                color: activeColor,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          // CAMPO DE TEXTO (NÚMERO GRANDE)
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono( // Fonte monoespaçada fica top para números
              fontSize: 28 * scaleFactor,
              fontWeight: FontWeight.w700,
              color: hasValue ? pureWhite : grayText.withOpacity(0.5),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
              hintText: '0',
              hintStyle: TextStyle(color: borderGray),
            ),
            onChanged: (value) {
              onQuantidadeChanged(produtoId, tipo, value);
            },
            // Configurações para teclado numérico limpo
            enableInteractiveSelection: true,
            cursorColor: accentColor,
          ),
        ],
      ),
    );
  }

  // ===================================
  // 💀 SHIMMER LOADING (DARK)
  // ===================================

  Widget _buildShimmerLista() {
    return ListView.builder(
      padding: EdgeInsets.all(20 * scaleFactor),
      itemCount: 6,
      itemBuilder: (context, i) => Container(
        margin: EdgeInsets.only(bottom: 20 * scaleFactor),
        height: 140 * scaleFactor,
        decoration: BoxDecoration(
          color: cardBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderGray),
        ),
        child: Padding(
          padding: EdgeInsets.all(20 * scaleFactor),
          child: Column(
            children: [
              Row(
                children: [
                  _shimmerBox(20, 20, 20), // Bolinha
                  SizedBox(width: 16),
                  Expanded(child: _shimmerBox(double.infinity, 20, 6)), // Nome
                ],
              ),
              Spacer(),
              Row(
                children: [
                  Expanded(child: _shimmerBox(double.infinity, 50, 16)), // Input 1
                  SizedBox(width: 16),
                  Expanded(child: _shimmerBox(double.infinity, 50, 16)), // Input 2
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, double r) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) => Container(
        width: w == double.infinity ? null : w * scaleFactor,
        height: h * scaleFactor,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + shimmerController.value * 2, 0),
            end: Alignment(1.0 + shimmerController.value * 2, 0),
            colors: [
              borderGray,
              Color(0xFF333333),
              borderGray,
            ],
          ),
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
          Icon(
            Icons.inventory_2_outlined,
            size: 60 * scaleFactor,
            color: borderGray,
          ),
          SizedBox(height: 24 * scaleFactor),
          Text(
            'Nenhum produto aqui',
            style: GoogleFonts.poppins(
              fontSize: 20 * scaleFactor,
              fontWeight: FontWeight.w700,
              color: pureWhite,
            ),
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
            'Essa categoria está vazia.',
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