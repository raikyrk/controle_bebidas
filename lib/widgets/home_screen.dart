// lib/widgets/home_screen.dart
import 'package:flutter/material.dart'; // <--- CORRIGIDO: ESSENCIAL
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';

// Importa os arquivos da camada de Lógica e Modelo
import '../api_service.dart';
import '../produto.dart'; 

// Importa as Views Modulares
import 'home_grid_view.dart';
import 'home_product_list_view.dart';

class HomeScreen extends StatefulWidget {
  // Recebe parâmetros do Sidebar
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final ValueChanged<String> onMainItemChanged;

  const HomeScreen({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onMainItemChanged,
  });

  @override
  // CORRIGIDO: A classe State deve ser definida aqui
  State<HomeScreen> createState() => _HomeScreenState(); 
}

// CORRIGIDO: Herança correta de State<HomeScreen> e uso do mixin
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin { 
  // ===================================
  // 1. ESTADO E CONTROLADORES DE DADOS (Agora definidos dentro da classe)
  // ===================================
  List<Produto> produtos = [];
  Map<String, List<Produto>> categoriasMap = {};
  final Map<int, TextEditingController> _fardosControllers = {};
  final Map<int, TextEditingController> _avulsasControllers = {};
  final Map<int, Timer?> _debounceTimers = {};
  int totalFardos = 0;
  int totalAvulsas = 0;
  bool isLoading = true;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late double _scaleFactor;

  // ===================================
  // 2. PALETA DE CORES (MANTIDO)
  // ===================================
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
  
  final Map<String, Color> _colorsMap = const {
      'primaryOrange': primaryOrange, 'lightOrange': lightOrange, 'deepOrange': deepOrange,
      'accentPurple': accentPurple, 'accentBlue': accentBlue, 'lightGray': lightGray, 
      'borderGray': borderGray, 'textDark': textDark, 'textLight': textLight, 
      'zeroStock': zeroStock, 'successGreen': successGreen, 'warningYellow': warningYellow,
      'warningOrange': warningOrange, 'backgroundGradientStart': backgroundGradientStart, 
      'backgroundGradientEnd': backgroundGradientEnd, 'cardShadow': cardShadow,
  };


  // ===================================
  // 3. LIFECYCLE E SETUP (MANTIDO)
  // ===================================

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarEstoque(); 
    });
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


  // ===================================
  // 4. LÓGICA DA API E DE ESTADO
  // ===================================

  Future<void> _carregarEstoque() async {
    // 'mounted' e 'setState' agora são reconhecidos
    if (!mounted) return; 
    setState(() => isLoading = true); 
    try {
      // 'ApiService' agora é reconhecido (assumindo que está importado em '../api_service.dart')
      final novosProdutos = await ApiService.getEstoque(); 
      if (!mounted) return;

      // Limpa e recria controllers
      _fardosControllers.values.forEach((c) => c.dispose());
      _avulsasControllers.values.forEach((c) => c.dispose());
      _fardosControllers.clear();
      _avulsasControllers.clear();

      for (var p in novosProdutos) {
        // 'TextEditingController' agora é reconhecido
        _fardosControllers[p.id] = TextEditingController( 
          text: p.fardos == 0 ? '' : p.fardos.toString(),
        );
        _avulsasControllers[p.id] = TextEditingController(
          text: p.avulsas == 0 ? '' : p.avulsas.toString(),
        );
      }
      
      setState(() {
        produtos = novosProdutos;
        _agruparPorCategoria(); // Agora é reconhecido
        _calcularTotais(); // Agora é reconhecido
      });

      // Lógica de seleção automática removida, mantendo o Grid view inicial.
      
    } catch (e) {
      if (mounted) _showErrorSnackbar('Erro ao carregar estoque: $e'); // Agora é reconhecido
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // DEFINIÇÃO DOS MÉTODOS DE LÓGICA (Anteriormente apenas chamados)
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

  void _onQuantidadeChanged(int id, String tipo, String value) {
    _debounceTimers[id]?.cancel();
    
    _debounceTimers[id] = Timer(const Duration(milliseconds: 800), () {
      final novoValor = int.tryParse(value.isEmpty ? '0' : value) ?? 0;
      _alterar(id, tipo, novoValor.clamp(0, 999));
    });
  }

  Future<void> _alterar(int id, String tipo, int novoValor) async {
    final produto = produtos.firstWhere((p) => p.id == id);
    final antigo = tipo == 'f' ? produto.fardos : produto.avulsas;
    if (novoValor == antigo) return;

    setState(() {
      if (tipo == 'f') {
        produto.fardos = novoValor.clamp(0, 999);
      } else {
        produto.avulsas = novoValor.clamp(0, 999);
      }
      _calcularTotais();
    });
    
    try {
      final diferenca = novoValor - antigo;
      await ApiService.updateQuantidade(id, tipo, diferenca);
      if (!mounted) return;
      
      _showSuccessFeedback();
      
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Falha ao salvar alteração: $e');
        setState(() {
          if (tipo == 'f') {
            produto.fardos = antigo;
            _fardosControllers[id]?.text = antigo == 0 ? '' : antigo.toString();
          } else {
            produto.avulsas = antigo;
            _avulsasControllers[id]?.text = antigo == 0 ? '' : antigo.toString();
          }
          _calcularTotais();
        });
      }
    }
  }

  // ===================================
  // 5. FEEDBACKS VISUAIS E HELPERS
  // ===================================
  
  // (Mantenha _showSuccessFeedback e _showErrorSnackbar, _getCategoryIcon, _getCrossAxisCount, _getChildAspectRatio aqui)

  void _showSuccessFeedback() {
    // ... (corpo do método)
  }

  void _showErrorSnackbar(String message) {
    // ... (corpo do método)
  }
  
  IconData _getCategoryIcon(String category) {
    // ... (corpo do método)
    final normalized = category.trim().toLowerCase();
    if (normalized == 'refrigerante') return Icons.local_drink_rounded;
    if (normalized.contains('cerveja') && normalized.contains('long')) return Icons.sports_bar_rounded;
    if (normalized.contains('cerveja') && normalized.contains('600')) return Icons.local_bar_rounded;
    if (normalized.contains('red bull') || normalized.contains('redbull')) return Icons.flash_on_rounded;
    if (normalized.contains('vinho')) return Icons.wine_bar_rounded;
    if (normalized.contains('gin')) return Icons.liquor_rounded;
    if (normalized.contains('whisky')) return Icons.local_bar_rounded;
    if (normalized.contains('gatorade')) return Icons.sports_rounded;
    if (normalized.contains('agua') || normalized.contains('mineral')) return Icons.water_drop_rounded;
    return Icons.inventory_rounded;
  }

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


  // ===================================
  // 6. BUILDER (Orquestrador de Views)
  // ===================================

  @override
  Widget build(BuildContext context) {
    // 1. Visão Detalhe (Lista de Produtos de uma Categoria Específica)
    if (widget.selectedCategory.isNotEmpty && categoriasMap.containsKey(widget.selectedCategory)) {
      final itens = categoriasMap[widget.selectedCategory]!;
      
      return HomeProductListView(
        categoria: widget.selectedCategory,
        itens: itens,
        onBack: () => widget.onCategoryChanged(''),
        isLoading: isLoading,
        onRefresh: _carregarEstoque,
        onQuantidadeChanged: _onQuantidadeChanged,
        fardosControllers: _fardosControllers,
        avulsasControllers: _avulsasControllers,
        shimmerController: _shimmerController,
        pulseController: _pulseController,
        scaleFactor: _scaleFactor,
        colors: _colorsMap,
        getCategoryIcon: _getCategoryIcon,
      );
    }
    
    // 2. Visão Geral (Grid de Categorias)
    return HomeGridView(
      categoriasMap: categoriasMap,
      totalFardos: totalFardos,
      totalAvulsas: totalAvulsas,
      isLoading: isLoading,
      onRefresh: _carregarEstoque,
      onCategorySelected: widget.onCategoryChanged,
      shimmerController: _shimmerController,
      pulseController: _pulseController,
      scaleFactor: _scaleFactor,
      getCrossAxisCount: _getCrossAxisCount,
      getChildAspectRatio: _getChildAspectRatio,
      colors: _colorsMap,
      getCategoryIcon: _getCategoryIcon,
    );
  }
}