// home_screen.dart - VERSÃO CORRIGIDA PARA ANDROID APK
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';
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
  final Map<int, TextEditingController> _fardosControllers = {};
  final Map<int, TextEditingController> _avulsasControllers = {};
  final Map<int, Timer?> _debounceTimers = {}; // NOVO: Timer para debounce
  int totalFardos = 0;
  int totalAvulsas = 0;
  bool isLoading = true;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late double _scaleFactor;

  // PALETA DE CORES MODERNIZADA
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color lightOrange = Color(0xFFFF8C42);
  static const Color deepOrange = Color(0xFFFF4500);
  static const Color accentPurple = Color(0xFF6C5CE7);
  static const Color accentBlue = Color(0xFF0984E3);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFF636E72);
  static const Color zeroStock = Color(0xFF95A5A6);
  static const Color successGreen = Color(0xFF00B894);
  static const Color warningYellow = Color(0xFFFDCB6E);
  static const Color warningOrange = Color(0xFFE17055);
  static const Color backgroundGradientStart = Color(0xFFF8F9FA);
  static const Color backgroundGradientEnd = Color(0xFFECF0F1);
  static const Color cardShadow = Color(0x1A000000);

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double width = MediaQuery.of(context).size.width;
    _scaleFactor = width > 600 ? 1.0 : (width / 375).clamp(0.85, 1.0);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    // NOVO: Cancelar todos os timers
    _debounceTimers.values.forEach((timer) => timer?.cancel());
    _debounceTimers.clear();
    _fardosControllers.values.forEach((c) => c.dispose());
    _avulsasControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _carregarEstoque();
    }
  }

  // -------------------------------------------------
  // CARREGAR ESTOQUE
  // -------------------------------------------------
  Future<void> _carregarEstoque() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final novosProdutos = await ApiService.getEstoque();
      if (!mounted) return;

      _fardosControllers.values.forEach((c) => c.dispose());
      _avulsasControllers.values.forEach((c) => c.dispose());
      _fardosControllers.clear();
      _avulsasControllers.clear();

      for (var p in novosProdutos) {
        _fardosControllers[p.id] = TextEditingController(
          text: p.fardos == 0 ? '' : p.fardos.toString(),
        );
        _avulsasControllers[p.id] = TextEditingController(
          text: p.avulsas == 0 ? '' : p.avulsas.toString(),
        );
      }

      setState(() {
        produtos = novosProdutos;
        _agruparPorCategoria();
        _calcularTotais();
      });
    } catch (e) {
      if (mounted) _showErrorSnackbar('Erro ao carregar estoque');
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  // -------------------------------------------------
  // ALTERAR QUANTIDADE COM DEBOUNCE (NOVA VERSÃO)
  // -------------------------------------------------
  void _onQuantidadeChanged(int id, String tipo, String value) {
    // Cancelar timer anterior se existir
    _debounceTimers[id]?.cancel();
    
    // Criar novo timer
    _debounceTimers[id] = Timer(const Duration(milliseconds: 800), () {
      final novoValor = int.tryParse(value.isEmpty ? '0' : value) ?? 0;
      _alterar(id, tipo, novoValor.clamp(0, 999));
    });
  }

  Future<void> _alterar(int id, String tipo, int novoValor) async {
    final produto = produtos.firstWhere((p) => p.id == id);
    final antigo = tipo == 'f' ? produto.fardos : produto.avulsas;
    if (novoValor == antigo) return;

    try {
      await ApiService.updateQuantidade(id, tipo, novoValor - antigo);
      if (!mounted) return;

      setState(() {
        if (tipo == 'f') {
          produto.fardos = novoValor.clamp(0, 999);
        } else {
          produto.avulsas = novoValor.clamp(0, 999);
        }
        _calcularTotais();
      });
      
      _showSuccessFeedback();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Falha ao salvar alteração');
        setState(() {
          if (tipo == 'f') {
            produto.fardos = antigo;
            _fardosControllers[id]?.text = antigo == 0 ? '' : antigo.toString();
          } else {
            produto.avulsas = antigo;
            _avulsasControllers[id]?.text = antigo == 0 ? '' : antigo.toString();
          }
        });
      }
    }
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quantidade atualizada com sucesso',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 0,
      ),
    );
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD63031),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 0,
      ),
    );
  }

  // -------------------------------------------------
  // ÍCONE POR CATEGORIA
  // -------------------------------------------------
  IconData _getCategoryIcon(String category) {
    final normalized = category.trim().toLowerCase();
    if (normalized == 'refrigerante') return Icons.local_drink_rounded;
    if (normalized == 'cerveja long neck') return Icons.sports_bar_rounded;
    if (normalized == 'cerveja 600ml') return Icons.local_bar_rounded;
    if (normalized == 'redbull') return Icons.flash_on_rounded;
    if (normalized == 'vinho') return Icons.wine_bar_rounded;
    if (normalized == 'gin') return Icons.liquor_rounded;
    if (normalized == 'whisky') return Icons.local_bar_rounded;
    if (normalized == 'gatorade') return Icons.sports_rounded;
    if (normalized == 'água mineral') return Icons.water_drop_rounded;
    if (normalized == 'diversos') return Icons.category_rounded;
    if (normalized.contains('cerveja') && normalized.contains('long')) return Icons.sports_bar_rounded;
    if (normalized.contains('cerveja') && normalized.contains('600')) return Icons.local_bar_rounded;
    if (normalized.contains('red bull') || normalized.contains('redbull')) return Icons.flash_on_rounded;
    if (normalized.contains('agua') || normalized.contains('mineral')) return Icons.water_drop_rounded;
    return Icons.inventory_rounded;
  }

  // -------------------------------------------------
  // RESPONSIVIDADE
  // -------------------------------------------------
  int _getCrossAxisCount(double width) {
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  double _getChildAspectRatio(int crossAxisCount) {
    if (crossAxisCount >= 4) return 0.80;
    if (crossAxisCount == 3) return 0.75;
    return 0.72;
  }

  // -------------------------------------------------
  // BUILD
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (widget.selectedCategory.isNotEmpty && categoriasMap.containsKey(widget.selectedCategory)) {
      final itens = categoriasMap[widget.selectedCategory]!;
      return _buildCategoriaDetalhe(widget.selectedCategory, itens);
    }
    return _buildCategoriasGrid();
  }

  // -------------------------------------------------
  // GRID DE CATEGORIAS
  // -------------------------------------------------
  Widget _buildCategoriasGrid() {
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
          // HEADER MODERNIZADO COM GLASSMORPHISM
          Container(
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
                    24 * _scaleFactor,
                    32 * _scaleFactor,
                    24 * _scaleFactor,
                    28 * _scaleFactor,
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
                            padding: EdgeInsets.all(18 * _scaleFactor),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
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
                              size: 32 * _scaleFactor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20 * _scaleFactor),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestão de Estoque',
                              style: GoogleFonts.poppins(
                                fontSize: 28 * _scaleFactor,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 8 * _scaleFactor),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12 * _scaleFactor,
                                vertical: 6 * _scaleFactor,
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
                                    size: 16 * _scaleFactor,
                                    color: primaryOrange,
                                  ),
                                  SizedBox(width: 6 * _scaleFactor),
                                  Text(
                                    '${categoriasMap.length} categorias',
                                    style: GoogleFonts.inter(
                                      fontSize: 13 * _scaleFactor,
                                      color: primaryOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 12 * _scaleFactor),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: primaryOrange.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 12 * _scaleFactor),
                                  Icon(
                                    Icons.inventory_2_rounded,
                                    size: 16 * _scaleFactor,
                                    color: accentBlue,
                                  ),
                                  SizedBox(width: 6 * _scaleFactor),
                                  Text(
                                    '$totalFardos fardos • $totalAvulsas avulsas',
                                    style: GoogleFonts.inter(
                                      fontSize: 13 * _scaleFactor,
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
          ),

          // Grid de categorias
          Expanded(
            child: isLoading
                ? _buildShimmerGrid()
                : categoriasMap.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _carregarEstoque,
                        color: primaryOrange,
                        backgroundColor: Colors.white,
                        strokeWidth: 3.5,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                            final childAspectRatio = _getChildAspectRatio(crossAxisCount);
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

  // -------------------------------------------------
  // CARD MODERNO DE CATEGORIA
  // -------------------------------------------------
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

    Color primaryColor = estoqueOk ? successGreen : (semEstoque ? primaryOrange : warningOrange);
    Color secondaryColor = estoqueOk ? const Color(0xFF00D2AB) : (semEstoque ? lightOrange : warningYellow);

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
          onTap: () => widget.onCategoryChanged(categoria),
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
                    padding: EdgeInsets.all(18 * _scaleFactor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12 * _scaleFactor),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getCategoryIcon(categoria),
                                color: Colors.white,
                                size: 24 * _scaleFactor,
                              ),
                            ),
                            
                            if (semEstoque || baixoEstoque)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) => Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.1),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * _scaleFactor,
                                      vertical: 5 * _scaleFactor,
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
                                      size: 14 * _scaleFactor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        SizedBox(height: 12 * _scaleFactor),
                        
                        Flexible(
                          child: Text(
                            categoria,
                            style: GoogleFonts.poppins(
                              fontSize: 16 * _scaleFactor,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        SizedBox(height: 12 * _scaleFactor),
                        
                        Container(
                          padding: EdgeInsets.all(12 * _scaleFactor),
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
                                'Total',
                                Icons.inventory_2_rounded,
                                semEstoque ? zeroStock : textDark,
                              ),
                              SizedBox(height: 8 * _scaleFactor),
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
                              SizedBox(height: 8 * _scaleFactor),
                              _buildStatRowModerno(
                                '$emEstoque',
                                'Estoque',
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
                padding: EdgeInsets.all(5 * _scaleFactor),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14 * _scaleFactor, color: color),
              ),
              SizedBox(width: 8 * _scaleFactor),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11 * _scaleFactor,
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
        SizedBox(width: 8 * _scaleFactor),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * _scaleFactor,
            vertical: 3 * _scaleFactor,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14 * _scaleFactor,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------
  // DETALHE DA CATEGORIA
  // -------------------------------------------------
  Widget _buildCategoriaDetalhe(String categoria, List<Produto> itens) {
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
          Container(
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
                    24 * _scaleFactor,
                    32 * _scaleFactor,
                    24 * _scaleFactor,
                    28 * _scaleFactor,
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
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onCategoryChanged(''),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: EdgeInsets.all(14 * _scaleFactor),
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
                              size: 26 * _scaleFactor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 18 * _scaleFactor),
                      
                      Container(
                        padding: EdgeInsets.all(18 * _scaleFactor),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
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
                          _getCategoryIcon(categoria),
                          color: Colors.white,
                          size: 28 * _scaleFactor,
                        ),
                      ),
                      SizedBox(width: 20 * _scaleFactor),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoria,
                              style: GoogleFonts.poppins(
                                fontSize: 26 * _scaleFactor,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 8 * _scaleFactor),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12 * _scaleFactor,
                                vertical: 6 * _scaleFactor,
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
                                  Icon(
                                    Icons.inventory_2_rounded,
                                    size: 16 * _scaleFactor,
                                    color: accentBlue,
                                  ),
                                  SizedBox(width: 6 * _scaleFactor),
                                  Text(
                                    '${itens.length} produto${itens.length != 1 ? 's' : ''}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13 * _scaleFactor,
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
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregarEstoque,
              color: primaryOrange,
              backgroundColor: Colors.white,
              strokeWidth: 3.5,
              child: isLoading
                  ? _buildShimmerLista()
                  : itens.isEmpty
                      ? _buildEmptyState()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final padding = constraints.maxWidth < 500 ? 20.0 : 28.0;
                            final spacing = constraints.maxWidth < 500 ? 20.0 : 24.0;

                            return ListView.builder(
                              padding: EdgeInsets.all(padding),
                              itemCount: itens.length,
                              itemBuilder: (context, i) => Padding(
                                padding: EdgeInsets.only(bottom: spacing),
                                child: _buildProdutoCardModerno(itens[i], i),
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

  // -------------------------------------------------
  // CARD MODERNO DE PRODUTO
  // -------------------------------------------------
  Widget _buildProdutoCardModerno(Produto p, int index) {
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
              Container(
                padding: EdgeInsets.all(24 * _scaleFactor),
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
                    Container(
                      padding: EdgeInsets.all(14 * _scaleFactor),
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
                        size: 26 * _scaleFactor,
                      ),
                    ),
                    SizedBox(width: 18 * _scaleFactor),
                    
                    Expanded(
                      child: Text(
                        p.nome,
                        style: GoogleFonts.poppins(
                          fontSize: 20 * _scaleFactor,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    if (isZero || isLow)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.08),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14 * _scaleFactor,
                              vertical: 8 * _scaleFactor,
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
                                fontSize: 11 * _scaleFactor,
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
              
              Padding(
                padding: EdgeInsets.all(24 * _scaleFactor),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuantidadeEditavelModerna(
                        label: 'FARDOS',
                        controller: _fardosControllers[p.id]!,
                        produtoId: p.id,
                        tipo: 'f',
                        color: primaryOrange,
                        secondaryColor: deepOrange,
                      ),
                    ),
                    SizedBox(width: 24 * _scaleFactor),
                    Expanded(
                      child: _buildQuantidadeEditavelModerna(
                        label: 'AVULSAS',
                        controller: _avulsasControllers[p.id]!,
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

  // -------------------------------------------------
  // CAMPO EDITÁVEL MODERNO - VERSÃO CORRIGIDA PARA ANDROID
  // -------------------------------------------------
  Widget _buildQuantidadeEditavelModerna({
    required String label,
    required TextEditingController controller,
    required int produtoId,
    required String tipo,
    required Color color,
    required Color secondaryColor,
  }) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final padding = isSmall ? 16.0 : 20.0;
    final fontSizeLabel = isSmall ? 11.0 : 12.0;
    final fontSizeValue = isSmall ? 34.0 : 38.0;

    final currentValue = int.tryParse(controller.text) ?? 0;
    final isLow = currentValue > 0 && currentValue <= (label == 'FARDOS' ? 2 : 5);
    final isZero = currentValue == 0;

    return Container(
      padding: EdgeInsets.all(padding * _scaleFactor),
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
              horizontal: 12 * _scaleFactor,
              vertical: 6 * _scaleFactor,
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
                fontSize: fontSizeLabel * _scaleFactor,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          SizedBox(height: 16 * _scaleFactor),
          
          // CORREÇÃO PRINCIPAL: TextField simplificado
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * _scaleFactor,
              vertical: 8 * _scaleFactor,
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
                fontSize: fontSizeValue * _scaleFactor,
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
                  fontSize: fontSizeValue * _scaleFactor,
                  fontWeight: FontWeight.w900,
                  color: textLight.withOpacity(0.3),
                ),
              ),
              // CORREÇÃO: Usar onChanged com debounce
              onChanged: (value) {
                _onQuantidadeChanged(produtoId, tipo, value);
              },
              // CORREÇÃO: Permitir edição livre sem interferência
              enableInteractiveSelection: true,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
          
          SizedBox(height: 12 * _scaleFactor),
          
          if (isLow)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_down_rounded,
                  size: 14 * _scaleFactor,
                  color: warningOrange,
                ),
                SizedBox(width: 4 * _scaleFactor),
                Text(
                  'Estoque baixo',
                  style: GoogleFonts.inter(
                    fontSize: 10 * _scaleFactor,
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

  // -------------------------------------------------
  // SHIMMER
  // -------------------------------------------------
  Widget _buildShimmerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = _getChildAspectRatio(crossAxisCount);
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

  Widget _buildShimmerLista() {
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

  Widget _shimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) => Container(
        padding: EdgeInsets.all(20 * _scaleFactor),
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
                _shimmerBox(52.0 * _scaleFactor, 52.0 * _scaleFactor, 16.0),
                _shimmerBox(36.0 * _scaleFactor, 28.0 * _scaleFactor, 10.0),
              ],
            ),
            SizedBox(height: 16 * _scaleFactor),
            _shimmerBox(140.0 * _scaleFactor, 20.0 * _scaleFactor, 10.0),
            const Spacer(),
            _shimmerBox(double.infinity, 80.0 * _scaleFactor, 16.0),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, [double r = 8.0]) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + _shimmerController.value * 2, 0),
            end: Alignment(1.0 + _shimmerController.value * 2, 0),
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

  // -------------------------------------------------
  // ESTADO VAZIO
  // -------------------------------------------------
  Widget _buildEmptyState() {
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
                padding: EdgeInsets.all(40 * _scaleFactor),
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
                  size: 72 * _scaleFactor,
                  color: textLight.withOpacity(0.6),
                ),
              ),
            ),
          ),
          SizedBox(height: 32 * _scaleFactor),
          Text(
            'Nenhum produto encontrado',
            style: GoogleFonts.poppins(
              fontSize: 24 * _scaleFactor,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: 12 * _scaleFactor),
          Text(
            'Esta categoria está vazia no momento',
            style: GoogleFonts.inter(
              fontSize: 15 * _scaleFactor,
              color: textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}