// lib/expedicao/checagem_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../api_service.dart';
import '../produto.dart';
import 'carrinho_expedicao.dart';
import 'dart:math' as math;

class ChecagemScreen extends StatefulWidget {
  final int lojaId;
  final String lojaNome;

  const ChecagemScreen({required this.lojaId, required this.lojaNome, super.key});

  @override
  State<ChecagemScreen> createState() => _ChecagemScreenState();
}

class _ChecagemScreenState extends State<ChecagemScreen>
    with TickerProviderStateMixin {
  bool isSending = false;
  AnimationController? _fabController;
  AnimationController? _headerController;
  AnimationController? _refreshController;

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color darkOrange = Color(0xFFE85A2A);
  static const Color lightOrange = Color(0xFFFFE5DC);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController?.dispose();
    _headerController?.dispose();
    _refreshController?.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    _refreshController?.forward().then((_) {
      _refreshController?.reverse();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (CarrinhoExpedicao.itens.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: _buildModernAppBar(context),
        body: _buildEmptyState(),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(context),
      body: FutureBuilder<List<Produto>>(
        future: ApiService.getEstoque(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          final estoque = snapshot.data!;
          final entradas = CarrinhoExpedicao.itens.entries.toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Espaço para o AppBar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              
              // Header com estatísticas
              SliverToBoxAdapter(child: _buildStatisticsHeader(entradas.length)),
              
              // Lista de produtos
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = entradas[i];
                      final produto = estoque.firstWhere(
                        (p) => p.id == entry.key,
                        orElse: () => Produto(
                          id: entry.key,
                          nome: 'Produto não encontrado',
                          categoria: '',
                          fardos: 0,
                          avulsas: 0,
                        ),
                      );

                      return Column(
                        children: [
                          // Fardos
                          if ((entry.value['f'] ?? 0) > 0 && _headerController != null)
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-0.3, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _headerController!,
                                curve: Interval(i * 0.08, (i * 0.08) + 0.5, curve: Curves.easeOutCubic),
                              )),
                              child: FadeTransition(
                                opacity: _headerController!,
                                child: ModernProductCard(
                                  key: ValueKey('${entry.key}-f'),
                                  produto: produto,
                                  quantidadeInicial: entry.value['f']!,
                                  tipo: 'Fardo',
                                  tipoPlural: 'Fardos',
                                  color: primaryOrange,
                                  icon: Icons.inventory_2_rounded,
                                  produtoId: entry.key,
                                  tipoCarrinho: 'f',
                                  onChanged: _triggerRefresh,
                                ),
                              ),
                            ),

                          // Avulsas
                          if ((entry.value['a'] ?? 0) > 0 && _headerController != null)
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(-0.3, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _headerController!,
                                curve: Interval(i * 0.08, (i * 0.08) + 0.5, curve: Curves.easeOutCubic),
                              )),
                              child: FadeTransition(
                                opacity: _headerController!,
                                child: ModernProductCard(
                                  key: ValueKey('${entry.key}-a'),
                                  produto: produto,
                                  quantidadeInicial: entry.value['a']!,
                                  tipo: 'Avulsa',
                                  tipoPlural: 'Avulsas',
                                  color: const Color(0xFF3B82F6),
                                  icon: Icons.widgets_rounded,
                                  produtoId: entry.key,
                                  tipoCarrinho: 'a',
                                  onChanged: _triggerRefresh,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),
                        ],
                      );
                    },
                    childCount: entradas.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildModernFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cardBackground.withValues(alpha: 0.95),
                  cardBackground.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checagem de Produtos',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: primaryOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.lojaNome,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(int totalProdutos) {
    if (_headerController == null || _refreshController == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _refreshController!,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_refreshController!.value * 0.05),
          child: FadeTransition(
            opacity: _headerController!,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _headerController!,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryOrange, darkOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.shopping_cart_rounded,
                            label: 'Total de Itens',
                            value: '${CarrinhoExpedicao.totalItens}',
                            isLarge: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.category_rounded,
                            label: 'Produtos',
                            value: '$totalProdutos',
                            isLarge: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(value * -10, 0),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: const Icon(Icons.swipe, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Deslize para remover itens',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      lightOrange,
                      lightOrange.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: primaryOrange.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 40),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Text(
                    'Carrinho Vazio',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Adicione produtos na tela de\nExpedição para começar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          lightOrange,
                          lightOrange.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryOrange.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: primaryOrange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Voltar para Expedição',
                          style: GoogleFonts.inter(
                            color: primaryOrange,
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightOrange, lightOrange.withValues(alpha: 0.6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: primaryOrange,
                  strokeWidth: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Text(
              'Carregando estoque...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    if (_fabController == null) return const SizedBox.shrink();
    
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fabController!,
          curve: Curves.elasticOut,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.5),
              blurRadius: 35,
              offset: const Offset(0, 14),
              spreadRadius: 3,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSending ? null : () => _confirmarEnvio(context),
            borderRadius: BorderRadius.circular(28),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSending
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSending)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(value * 5, 0),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    isSending ? 'Enviando...' : 'Confirmar Envio',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: 0.5,
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

  Future<void> _confirmarEnvio(BuildContext context) async {
    setState(() => isSending = true);
    
    try {
      await ApiService.expedirParaLoja(widget.lojaId, CarrinhoExpedicao.carrinhoParaEnvio);
      CarrinhoExpedicao.limpar();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Expedido com sucesso!',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Os produtos foram enviados',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
          elevation: 8,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Erro ao expedir',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 4),
          elevation: 8,
        ),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }
}

// ============================================
// COMPONENTE: Card de Estatística
// ============================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLarge;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLarge,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: isLarge ? 36 : 32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// COMPONENTE: Card de Produto Moderno
// ============================================
class ModernProductCard extends StatefulWidget {
  final Produto produto;
  final int quantidadeInicial;
  final String tipo;
  final String tipoPlural;
  final Color color;
  final IconData icon;
  final int produtoId;
  final String tipoCarrinho;
  final VoidCallback onChanged;

  const ModernProductCard({
    super.key,
    required this.produto,
    required this.quantidadeInicial,
    required this.tipo,
    required this.tipoPlural,
    required this.color,
    required this.icon,
    required this.produtoId,
    required this.tipoCarrinho,
    required this.onChanged,
  });

  @override
  State<ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<ModernProductCard>
    with TickerProviderStateMixin {
  late int quantidade = widget.quantidadeInicial;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _alterar(int delta) {
    if (delta > 0) {
      for (int i = 0; i < delta; i++) {
        CarrinhoExpedicao.adicionar(widget.produtoId, widget.tipoCarrinho);
      }
    } else {
      for (int i = 0; i < -delta; i++) {
        CarrinhoExpedicao.removerOuDiminuir(widget.produtoId, widget.tipoCarrinho);
      }
    }
    
    final novaQuantidade = (CarrinhoExpedicao.itens[widget.produtoId]?[widget.tipoCarrinho] ?? 0);
    
    if (novaQuantidade != quantidade) {
      setState(() {
        quantidade = novaQuantidade;
      });
      _pulseController.forward(from: 0);
      widget.onChanged();
    }
  }

  void _removerTudo() {
    while ((CarrinhoExpedicao.itens[widget.produtoId]?[widget.tipoCarrinho] ?? 0) > 0) {
      CarrinhoExpedicao.removerOuDiminuir(widget.produtoId, widget.tipoCarrinho);
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    quantidade = CarrinhoExpedicao.itens[widget.produtoId]?[widget.tipoCarrinho] ?? 0;

    // 🐛 FIX: Se quantidade for 0, não renderiza o widget
    if (quantidade == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final sineValue = math.sin(_shakeAnimation.value * math.pi * 2);
        return Transform.translate(
          offset: Offset(sineValue * 3, 0),
          child: child,
        );
      },
      child: Dismissible(
        key: ValueKey('${widget.produtoId}-${widget.tipoCarrinho}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          _shakeController.forward(from: 0);
          
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  backgroundColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  content: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.red.shade50.withValues(alpha: 0.4)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade400.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Remover Item?',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A1D29),
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            widget.produto.nome,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Remover todos os ${widget.tipoPlural.toLowerCase()}?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.delete_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remover',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
          return result ?? false;
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade400.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 6),
              Text(
                'Remover',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        onDismissed: (_) {
          _removerTudo();
          // Notifica o parent para reconstruir
          Future.microtask(() {
            if (mounted) setState(() {});
          });
        },
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.98).animate(_scaleController),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTapDown: (_) => _scaleController.forward(),
                  onTapUp: (_) => _scaleController.reverse(),
                  onTapCancel: () => _scaleController.reverse(),
                  borderRadius: BorderRadius.circular(24),
                  splashColor: widget.color.withValues(alpha: 0.08),
                  highlightColor: widget.color.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Ícone do produto
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.18),
                                widget.color.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.color.withValues(alpha: 0.35),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(widget.icon, color: widget.color, size: 34),
                        ),
                        const SizedBox(width: 16),

                        // Informações do produto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.produto.nome,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: const Color(0xFF1A1D29),
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.color.withValues(alpha: 0.15),
                                      widget.color.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: widget.color.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: widget.color,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.color.withValues(alpha: 0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.tipoPlural,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        color: widget.color,
                                        fontSize: 12,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Controle de quantidade
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.08).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.color.withValues(alpha: 0.12),
                                  widget.color.withValues(alpha: 0.06),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.color.withValues(alpha: 0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _QuantityButton(
                                  icon: Icons.remove_rounded,
                                  color: widget.color,
                                  onPressed: quantidade > 0 ? () => _alterar(-1) : null,
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 52),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '$quantidade',
                                      key: ValueKey(quantidade),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: widget.color,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                  ),
                                ),
                                _QuantityButton(
                                  icon: Icons.add_rounded,
                                  color: widget.color,
                                  onPressed: () => _alterar(1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// COMPONENTE: Botão de Quantidade
// ============================================
class _QuantityButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _QuantityButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  State<_QuantityButton> createState() => _QuantityButtonState();
}

class _QuantityButtonState extends State<_QuantityButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          borderRadius: BorderRadius.circular(16),
          splashColor: widget.color.withValues(alpha: 0.2),
          highlightColor: widget.color.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              widget.icon,
              color: widget.onPressed != null 
                ? widget.color 
                : widget.color.withValues(alpha: 0.3),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
