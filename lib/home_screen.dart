// home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'produto.dart';

class HomeScreen extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const HomeScreen({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Produto> produtos = [];
  Map<String, List<Produto>> categoriasMap = {};
  int totalFardos = 0;
  int totalAvulsas = 0;
  bool isLoading = true;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color lightOrange = Color(0xFFFF8555);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color borderGray = Color(0xFFE9ECEF);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color zeroStock = Color(0xFFADB5BD);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF00B894);
  static const Color warningYellow = Color(0xFFFDCB6E);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _carregarEstoque();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      setState(() {});
    }
  }

  Future<void> _carregarEstoque() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final novosProdutos = await ApiService.getEstoque();
      if (!mounted) return;

      setState(() {
        produtos = novosProdutos;
        _agruparPorCategoria();
        _calcularTotais();
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erro ao carregar estoque');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _agruparPorCategoria() {
    categoriasMap.clear();
    for (var p in produtos) {
      categoriasMap.putIfAbsent(p.categoria, () => []).add(p);
    }
  }

  void _calcularTotais() {
    totalFardos = produtos.fold(0, (sum, p) => sum + p.fardos);
    totalAvulsas = produtos.fold(0, (sum, p) => sum + p.avulsas);
  }

  Future<void> _alterar(int id, String tipo, int delta) async {
    try {
      await ApiService.updateQuantidade(id, tipo, delta);

      if (!mounted) return;

      setState(() {
        final produto = produtos.firstWhere((p) => p.id == id);
        if (tipo == 'f') {
          produto.fardos = (produto.fardos + delta).clamp(0, 999);
        } else {
          produto.avulsas = (produto.avulsas + delta).clamp(0, 999);
        }
        _calcularTotais();
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Falha ao salvar alteração');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD63031),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCategory == 'Dashboard') {
      return _buildDashboard();
    }

    final itens = categoriasMap[widget.selectedCategory] ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lightGray,
            Colors.white,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _carregarEstoque,
        color: primaryOrange,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        child: isLoading
            ? _buildShimmerLoading()
            : itens.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    itemCount: itens.length,
                    itemBuilder: (context, i) => _buildProdutoCard(itens[i], i),
                  ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: 5,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(150, 20, 8),
            const SizedBox(height: 8),
            _buildShimmerBox(200, 12, 4),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildShimmerBox(double.infinity, 120, 12)),
                const SizedBox(width: 16),
                Expanded(child: _buildShimmerBox(double.infinity, 120, 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, double radius) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerController.value * 2, 0),
              end: Alignment(1.0 + _shimmerController.value * 2, 0),
              colors: [
                borderGray,
                lightGray,
                borderGray,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboard() {
    final produtosComEstoque = produtos.where((p) => p.fardos > 0 || p.avulsas > 0).length;
    final produtosSemEstoque = produtos.length - produtosComEstoque;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightGray,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone principal com animação de pulso
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.05);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryOrange, lightOrange],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryOrange.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_rounded,
                        size: 90,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Título com ícone
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_rounded, color: primaryOrange, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Ao Gosto',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryOrange.withOpacity(0.1),
                      lightOrange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: primaryOrange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Gestão Inteligente de Estoque',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Cards de estatísticas principais
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Fardos',
                      totalFardos.toString(),
                      Icons.inventory_2_rounded,
                      primaryOrange,
                      lightOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Avulsas',
                      totalAvulsas.toString(),
                      Icons.shopping_basket_rounded,
                      lightOrange,
                      primaryOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cards de informações adicionais
              Row(
                children: [
                  Expanded(
                    child: _buildInfoMiniCard(
                      'Produtos',
                      produtos.length.toString(),
                      Icons.category_rounded,
                      textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoMiniCard(
                      'Em Estoque',
                      produtosComEstoque.toString(),
                      Icons.check_circle_rounded,
                      successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoMiniCard(
                      'Sem Estoque',
                      produtosSemEstoque.toString(),
                      Icons.warning_rounded,
                      produtosSemEstoque > 0 ? primaryOrange : textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Card de categorias
              _buildCategoriesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color1, Color color2) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, lightGray.withOpacity(0.5)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderGray, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color1, color2],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color1.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textLight,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryOrange.withOpacity(0.08),
            lightOrange.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryOrange.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryOrange, lightOrange],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categorias Disponíveis',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${categoriasMap.length} categorias organizadas',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: primaryOrange, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        lightGray,
                        Colors.white,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: borderGray, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 72,
                    color: textLight.withOpacity(0.5),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Nenhum produto encontrado',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta categoria ainda não possui produtos',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(Produto p, int index) {
    final isZero = p.fardos == 0 && p.avulsas == 0;
    final isLowStock = !isZero && ((p.fardos > 0 && p.fardos <= 2) || (p.avulsas > 0 && p.avulsas <= 5));
    
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, double opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(p.id),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, lightGray.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isZero 
                ? primaryOrange.withOpacity(0.4) 
                : isLowStock 
                    ? warningYellow.withOpacity(0.4)
                    : borderGray,
            width: isZero || isLowStock ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isZero 
                  ? primaryOrange.withOpacity(0.15)
                  : isLowStock
                      ? warningYellow.withOpacity(0.15)
                      : Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Header do produto com gradiente sutil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isZero
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryOrange.withOpacity(0.08),
                            lightOrange.withOpacity(0.03),
                          ],
                        )
                      : isLowStock
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                warningYellow.withOpacity(0.08),
                                warningYellow.withOpacity(0.03),
                              ],
                            )
                          : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isZero
                                  ? [primaryOrange.withOpacity(0.2), lightOrange.withOpacity(0.1)]
                                  : isLowStock
                                      ? [warningYellow.withOpacity(0.2), warningYellow.withOpacity(0.1)]
                                      : [successGreen.withOpacity(0.2), successGreen.withOpacity(0.1)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isZero 
                                ? Icons.remove_shopping_cart_rounded
                                : isLowStock
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                            color: isZero 
                                ? primaryOrange
                                : isLowStock
                                    ? warningYellow
                                    : successGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.nome,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isZero ? zeroStock : textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (isZero)
                          _buildStatusBadge(
                            'SEM ESTOQUE',
                            Icons.block_rounded,
                            [primaryOrange, lightOrange],
                          )
                        else if (isLowStock)
                          _buildStatusBadge(
                            'ESTOQUE BAIXO',
                            Icons.trending_down_rounded,
                            [warningYellow, warningYellow.withOpacity(0.8)],
                          ),
                      ],
                    ),
                    if (p.ultimaAlteracao != null && p.ultimaAlteracao!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: lightGray.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderGray, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: textLight,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_formatarData(p.ultimaAlteracao!)} • ${p.conferenteNome ?? 'Sistema'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Divisor com gradiente
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      borderGray,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Área de quantidades com visual melhorado
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuantityBox(
                        "FARDOS",
                        p.fardos,
                        () => _alterar(p.id, 'f', -1),
                        () => _alterar(p.id, 'f', 1),
                        isZero,
                        Icons.inventory_2_rounded,
                        primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuantityBox(
                        "AVULSAS",
                        p.avulsas,
                        () => _alterar(p.id, 'a', -1),
                        () => _alterar(p.id, 'a', 1),
                        isZero,
                        Icons.shopping_basket_rounded,
                        lightOrange,
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

  Widget _buildStatusBadge(String text, IconData icon, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBox(
    String label,
    int value,
    VoidCallback onDec,
    VoidCallback onInc,
    bool isZero,
    IconData icon,
    Color accentColor,
  ) {
    final isLow = value > 0 && value <= (label == "FARDOS" ? 2 : 5);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightGray,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLow ? warningYellow.withOpacity(0.3) : borderGray,
          width: isLow ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: isZero 
                  ? zeroStock 
                  : isLow 
                      ? warningYellow 
                      : textDark,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                Icons.remove_rounded, 
                onDec, 
                value == 0,
                accentColor,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                Icons.add_rounded, 
                onInc, 
                false,
                accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon, 
    VoidCallback onTap, 
    bool disabled,
    Color accentColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withOpacity(0.8)],
                  ),
            color: disabled ? textLight.withOpacity(0.15) : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: disabled 
                  ? textLight.withOpacity(0.2)
                  : accentColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            color: disabled ? textLight.withOpacity(0.4) : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  String _formatarData(String dataStr) {
    try {
      final trimmed = dataStr.trim();
      if (trimmed.isEmpty) return 'Data inválida';

      DateTime? parsedDate;

      if (trimmed.contains(' - ')) {
        final parts = trimmed.split(' - ');
        if (parts.length == 2) {
          parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse('${parts[0]} ${parts[1]}');
        }
      }

      if (parsedDate == null && (trimmed.contains('T') || (trimmed.contains('-') && trimmed.contains(':')))) {
        final cleanIso = trimmed.split('.')[0].replaceAll('T', ' ');
        parsedDate = DateFormat('yyyy-MM-dd HH:mm').parse(cleanIso);
      }

      if (parsedDate == null) {
        try {
          parsedDate = DateTime.parse(trimmed);
        } catch (_) {}
      }

      if (parsedDate == null && trimmed.contains('/')) {
        final clean = trimmed.replaceAll(' - ', ' ');
        parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(clean);
      }

      if (parsedDate == null) return trimmed;

      return DateFormat('dd/MM/yyyy - HH:mm').format(parsedDate);
    } catch (e) {
      return dataStr;
    }
  }
}