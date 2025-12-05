// lib/widgets/home_product_list_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async'; 

// Ajuste o import para sua estrutura correta
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
  final Map<String, Color> colors;
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
  Color get warningOrange => colors['warningOrange']!;
  Color get warningYellow => colors['warningYellow']!;
  Color get successGreen => colors['successGreen']!;
  Color get zeroStock => colors['zeroStock']!;
  Color get backgroundGradientStart => colors['backgroundGradientStart']!;
  Color get backgroundGradientEnd => colors['backgroundGradientEnd']!;
  

  // ===================================
  // 🔨 WIDGET PRINCIPAL (VIEW DE DETALHE)
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
          // HEADER (O cabeçalho detalhado da categoria)
          _buildDetailHeader(context),

          // LISTA DE PRODUTOS
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: primaryOrange,
              backgroundColor: Colors.white,
              strokeWidth: 3.5,
              child: isLoading
                  ? _buildShimmerLista()
                  : itens.isEmpty
                      ? _buildEmptyState(context)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final padding = constraints.maxWidth < 500 ? 20.0 : 28.0;
                            final spacing = constraints.maxWidth < 500 ? 20.0 : 24.0;

                            return ListView.builder(
                              padding: EdgeInsets.all(padding),
                              itemCount: itens.length,
                              itemBuilder: (context, i) => Padding(
                                padding: EdgeInsets.only(bottom: spacing),
                                child: _buildProdutoCardModerno(context, itens[i], i), // Passa context
                              ),
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

  Widget _buildDetailHeader(BuildContext context) {
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
                // BOTÃO DE VOLTAR para o GRID
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBack, // CHAMA O CALLBACK PARA VOLTAR AO GRID
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: EdgeInsets.all(14 * scaleFactor),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryOrange.withOpacity(0.15),
                            lightOrange.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primaryOrange.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: primaryOrange,
                        size: 26 * scaleFactor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 18 * scaleFactor),
                
                // ÍCONE DA CATEGORIA
                Container(
                  padding: EdgeInsets.all(18 * scaleFactor),
                  decoration: BoxDecoration(
                    // CORRIGIDO: Removido 'const' do LinearGradient
                    gradient: LinearGradient(
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
                    getCategoryIcon(categoria),
                    color: Colors.white,
                    size: 28 * scaleFactor,
                  ),
                ),
                SizedBox(width: 20 * scaleFactor),
                
                // TÍTULO DA CATEGORIA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria,
                        style: GoogleFonts.poppins(
                          fontSize: 26 * scaleFactor,
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
                              accentBlue.withOpacity(0.15),
                              accentPurple.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentBlue.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${itens.length} produto${itens.length != 1 ? 's' : ''}',
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

  Widget _buildProdutoCardModerno(BuildContext context, Produto p, int index) {
    final isZero = p.fardos == 0 && p.avulsas == 0;
    final isLow = !isZero && ((p.fardos > 0 && p.fardos <= 2) || (p.avulsas > 0 && p.avulsas <= 5));
    final isOk = !isZero && !isLow;

    Color statusColor = isOk ? successGreen : (isZero ? primaryOrange : warningOrange);
    Color statusColorSecondary = isOk ? const Color(0xFF00D2AB) : (isZero ? lightOrange : warningYellow);

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white.withOpacity(0.95)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.15),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              // Área superior (Nome e Status)
              Container(
                padding: EdgeInsets.all(24 * scaleFactor),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withOpacity(0.08),
                      statusColorSecondary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Ícone Status
                    Container(
                      padding: EdgeInsets.all(14 * scaleFactor),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColorSecondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        isZero
                            ? Icons.remove_shopping_cart_rounded
                            : isLow
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 26 * scaleFactor,
                      ),
                    ),
                    SizedBox(width: 18 * scaleFactor),
                    
                    // Nome do Produto
                    Expanded(
                      child: Text(
                        p.nome,
                        style: GoogleFonts.poppins(
                          fontSize: 20 * scaleFactor,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Status Badge (Pulsação)
                    if (isZero || isLow)
                      AnimatedBuilder(
                        animation: pulseController,
                        builder: (context, child) => Transform.scale(
                          scale: 1.0 + (pulseController.value * 0.08),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14 * scaleFactor,
                              vertical: 8 * scaleFactor,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [statusColor, statusColorSecondary],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              isZero ? 'SEM ESTOQUE' : 'BAIXO',
                              style: GoogleFonts.inter(
                                fontSize: 11 * scaleFactor,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Divisor
              Container(
                height: 2,
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
              
              // Editores de Quantidade
              Padding(
                padding: EdgeInsets.all(24 * scaleFactor),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuantidadeEditavelModerna(
                        context, // Passa context para o método
                        label: 'FARDOS',
                        controller: fardosControllers[p.id]!,
                        produtoId: p.id,
                        tipo: 'f',
                        color: primaryOrange,
                        secondaryColor: deepOrange,
                      ),
                    ),
                    SizedBox(width: 24 * scaleFactor),
                    Expanded(
                      child: _buildQuantidadeEditavelModerna(
                        context, // Passa context para o método
                        label: 'AVULSAS',
                        controller: avulsasControllers[p.id]!,
                        produtoId: p.id,
                        tipo: 'a',
                        color: accentBlue,
                        secondaryColor: accentPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildQuantidadeEditavelModerna(
    BuildContext context, // ⬅️ Recebe o BuildContext
    {
    required String label,
    required TextEditingController controller,
    required int produtoId,
    required String tipo,
    required Color color,
    required Color secondaryColor,
  }) {
    // CORRIGIDO: O acesso ao MediaQuery agora está seguro
    final isSmall = MediaQuery.of(context).size.width < 400; 
    final padding = isSmall ? 16.0 : 20.0;
    final fontSizeLabel = isSmall ? 11.0 : 12.0;
    final fontSizeValue = isSmall ? 34.0 : 38.0;

    final currentValue = int.tryParse(controller.text) ?? 0;
    final isLow = currentValue > 0 && currentValue <= (label == 'FARDOS' ? 2 : 5);
    final isZero = currentValue == 0;

    return Container(
      padding: EdgeInsets.all(padding * scaleFactor),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightGray,
            lightGray.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLow
              ? warningOrange.withOpacity(0.4)
              : isZero
                  ? borderGray.withOpacity(0.5)
                  : color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLow
                ? warningOrange.withOpacity(0.1)
                : color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scaleFactor,
              vertical: 6 * scaleFactor,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, secondaryColor],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSizeLabel * scaleFactor,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          SizedBox(height: 16 * scaleFactor),
          
          // TextField para entrada de quantidade
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scaleFactor,
              vertical: 8 * scaleFactor,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderGray.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: fontSizeValue * scaleFactor,
                fontWeight: FontWeight.w900,
                color: isZero ? textLight : color,
                height: 1,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: GoogleFonts.poppins(
                  fontSize: fontSizeValue * scaleFactor,
                  fontWeight: FontWeight.w900,
                  color: textLight.withOpacity(0.3),
                ),
              ),
              onChanged: (value) {
                onQuantidadeChanged(produtoId, tipo, value); // Chama a função no State Holder (home_screen.dart)
              },
              enableInteractiveSelection: true,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
          
          SizedBox(height: 12 * scaleFactor),
          
          if (isLow)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_down_rounded,
                  size: 14 * scaleFactor,
                  color: warningOrange,
                ),
                SizedBox(width: 4 * scaleFactor),
                Text(
                  'Estoque baixo',
                  style: GoogleFonts.inter(
                    fontSize: 10 * scaleFactor,
                    fontWeight: FontWeight.w700,
                    color: warningOrange,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ... (métodos _buildShimmerLista, _shimmerBox e _buildEmptyState permanecem, mas sem a necessidade de correções adicionais no context)

  Widget _buildShimmerLista() {
    // ... (Mantido o código original)
    return ListView.builder(
      padding: const EdgeInsets.all(28),
      itemCount: 5,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderGray.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  _shimmerBox(56.0, 56.0, 18.0),
                  const SizedBox(width: 18),
                  Expanded(child: _shimmerBox(160.0, 24.0, 12.0)),
                  const SizedBox(width: 12),
                  _shimmerBox(90.0, 32.0, 12.0),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 2,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _shimmerBox(double.infinity, 100.0, 20.0)),
                  const SizedBox(width: 24),
                  Expanded(child: _shimmerBox(double.infinity, 100.0, 20.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ... (restante do código)

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