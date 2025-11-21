// lib/expedicao/expedicao_screen.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../produto.dart';
import 'checagem_screen.dart';
import 'carrinho_expedicao.dart';

class ExpedicaoScreen extends StatefulWidget {
  const ExpedicaoScreen({super.key});

  @override
  State<ExpedicaoScreen> createState() => _ExpedicaoScreenState();
}

class _ExpedicaoScreenState extends State<ExpedicaoScreen> with TickerProviderStateMixin {
  List<Produto> produtos = [];
  Map<String, List<Produto>> categoriasMap = {};
  List<Map<String, dynamic>> lojas = [];

  String? categoriaSelecionada;
  int? lojaSelecionadaId;
  String? lojaSelecionadaNome;

  bool isLoading = true;
  late AnimationController _fabAnimationController;
  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // CORES - Paleta sofisticada
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color lightOrange = Color(0xFFFF8C42);
  static const Color deepOrange = Color(0xFFE85A2D);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color textLight = Color(0xFF6C757D);
  static const Color dangerRed = Color(0xFFE74C3C);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color cardWhite = Colors.white;
  static const Color successGreen = Color(0xFF27AE60);
  static const Color accentBlue = Color(0xFF3498DB);

  // Ícones para as lojas com melhor mapeamento
  final Map<String, IconData> lojaIcons = {
    'Silviano': Icons.storefront_rounded,
    'Prudente': Icons.shopping_bag_rounded,
    'Belvedere': Icons.store_rounded,
    'Pampulha': Icons.local_mall_rounded,
    'Mangabeiras': Icons.shop_rounded,
    'Delivery': Icons.delivery_dining_rounded,
    'Castelo': Icons.business_rounded,
    'Barreiro': Icons.store_mall_directory_rounded,
    'Eldorado': Icons.shopping_basket_rounded,
    'Silva Lobo': Icons.shopping_cart_rounded,
    'Buritis': Icons.add_business_rounded,
    'Cidade Nova': Icons.apartment_rounded,
    'Afonsos': Icons.home_work_rounded,
    'Ouro Preto': Icons.domain_rounded,
    'Sion': Icons.business_center_rounded,
    'Lagoa Santa': Icons.store_outlined,
  };

  // Cores variadas para cada loja (visual mais dinâmico)
  final List<List<Color>> lojaGradients = [
    [Color(0xFFFF6B35), Color(0xFFFF8C42)],
    [Color(0xFF3498DB), Color(0xFF5DADE2)],
    [Color(0xFF9B59B6), Color(0xFFBB8FCE)],
    [Color(0xFFE74C3C), Color(0xFFEC7063)],
    [Color(0xFF27AE60), Color(0xFF58D68D)],
    [Color(0xFFF39C12), Color(0xFFF8C471)],
    [Color(0xFF1ABC9C), Color(0xFF48C9B0)],
    [Color(0xFFE67E22), Color(0xFFEB984E)],
  ];

  @override
  void initState() {
    super.initState();
    
    // Animação do FAB
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Animação de entrada de página
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _carregarDados();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final resultados = await Future.wait([
        ApiService.getEstoque(),
        _carregarLojas(),
      ]);

      final List<Produto> estoque = resultados[0] as List<Produto>;
      final List<Map<String, dynamic>> listaLojas = resultados[1] as List<Map<String, dynamic>>;

      final Map<String, List<Produto>> mapa = {};
      for (final p in estoque) {
        mapa.putIfAbsent(p.categoria, () => []).add(p);
      }

      if (mounted) {
        setState(() {
          produtos = estoque;
          categoriasMap = mapa;
          lojas = listaLojas;
          isLoading = false;
        });
        _pageAnimationController.forward();
        _fabAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar(
          'Erro ao carregar dados',
          dangerRed,
          Icons.error_outline_rounded,
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarLojas() async {
  try {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/get_lojas.php'));
    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body) as List;
      final List<Map<String, dynamic>> lojas = jsonResponse
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Ordena por ID crescente
      lojas.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

      return lojas;
    }
  } catch (e) {
    debugPrint('Erro ao carregar lojas: $e');
  }

  // Fallback ordenado (caso API falhe)
  final fallback = <Map<String, dynamic>>[];
  final nomes = ['Silviano','Prudente','Belvedere','Pampulha','Mangabeiras','Delivery','Castelo','Barreiro','Eldorado','Silva Lobo','Buritis','Cidade Nova','Afonsos','Ouro Preto','Sion','Lagoa Santa'];
  for (int i = 0; i < nomes.length; i++) {
    fallback.add({'id': i + 1, 'nome': nomes[i]});
  }
  return fallback; // já vem ordenado naturalmente
}

  void _adicionarComLimite(int produtoId, String tipo) {
    final produto = produtos.firstWhere((p) => p.id == produtoId);
    final noCarrinho = CarrinhoExpedicao.itens[produtoId] ?? {'f': 0, 'a': 0};

    int estoqueDisponivel = tipo == 'f' ? produto.fardos : produto.avulsas;
    int jaNoCarrinho = tipo == 'f' ? (noCarrinho['f'] ?? 0) : (noCarrinho['a'] ?? 0);

    if (jaNoCarrinho >= estoqueDisponivel) {
      _mostrarSnackBar(
        'Sem mais ${tipo == 'f' ? 'fardos' : 'avulsas'} disponíveis!',
        dangerRed,
        Icons.warning_rounded,
      );
      return;
    }

    CarrinhoExpedicao.adicionar(produtoId, tipo);
    
    // Feedback háptico leve (vibração)
    // HapticFeedback.lightImpact(); // Descomente se quiser feedback háptico
    
    setState(() {});
    
    // Anima o FAB se for o primeiro item
    if (CarrinhoExpedicao.totalItens == 1) {
      _fabAnimationController.reset();
      _fabAnimationController.forward();
    }
  }

  void _remover(int produtoId, String tipo) {
    CarrinhoExpedicao.removerOuDiminuir(produtoId, tipo);
    setState(() {});
  }

  void _mostrarSnackBar(String mensagem, Color cor, IconData icon) {
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
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : lojaSelecionadaId == null
                      ? _buildSelecaoLoja()
                      : categoriaSelecionada == null
                          ? _buildGridCategorias()
                          : _buildListaProdutos(),
            ),
          ],
        ),
      ),
      floatingActionButton: CarrinhoExpedicao.totalItens > 0
          ? ScaleTransition(
              scale: CurvedAnimation(
                parent: _fabAnimationController,
                curve: Curves.elasticOut,
              ),
              child: FloatingActionButton.extended(
                backgroundColor: primaryOrange,
                elevation: 12,
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ChecagemScreen(
                        lojaId: lojaSelecionadaId!,
                        lojaNome: lojaSelecionadaNome!,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.playlist_add_check_rounded, size: 24),
                ),
                label: Text(
                  'Checagem (${CarrinhoExpedicao.totalItens})',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardWhite, lightGray],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        children: [
          // Ícone principal com animação
          Hero(
            tag: 'expedicao_icon',
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryOrange, lightOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expedição',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                if (lojaSelecionadaNome != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryOrange.withOpacity(0.1),
                          lightOrange.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryOrange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          lojaIcons[lojaSelecionadaNome] ?? Icons.store_rounded,
                          size: 16,
                          color: primaryOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lojaSelecionadaNome!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
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
          if (lojaSelecionadaId != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    lojaSelecionadaId = null;
                    lojaSelecionadaNome = null;
                    categoriaSelecionada = null;
                    CarrinhoExpedicao.limpar();
                  });
                  _pageAnimationController.reset();
                  _pageAnimationController.forward();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryOrange.withOpacity(0.1),
                        lightOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryOrange.withOpacity(0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: primaryOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Trocar',
                        style: GoogleFonts.inter(
                          color: primaryOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryOrange.withOpacity(0.1),
                        lightOrange.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: primaryOrange,
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Carregando dados',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aguarde um momento...',
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

  Widget _buildSelecaoLoja() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryOrange.withOpacity(0.1),
                          lightOrange.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 40, color: primaryOrange),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecione a Loja',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: darkText,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha uma loja para iniciar o processo de expedição',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: textLight,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 
                      ? 5 
                      : MediaQuery.of(context).size.width > 800 
                          ? 4 
                          : MediaQuery.of(context).size.width > 600 
                              ? 3 
                              : 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: lojas.length,
                itemBuilder: (_, i) {
                  final loja = lojas[i];
                  final lojaId = loja['id'] as int;
                  final lojaNome = loja['nome'] as String;
                  final icon = lojaIcons[lojaNome] ?? Icons.store_rounded;
                  final gradient = lojaGradients[i % lojaGradients.length];

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (i * 50)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          setState(() {
                            lojaSelecionadaId = lojaId;
                            lojaSelecionadaNome = lojaNome;
                            CarrinhoExpedicao.limpar();
                          });
                          _pageAnimationController.reset();
                          _pageAnimationController.forward();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardWhite,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradient[0].withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  lojaNome,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: darkText,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: lightGray,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ID: $lojaId',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: textLight,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCategorias() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryOrange.withOpacity(0.1),
                          lightOrange.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.category_rounded, size: 40, color: primaryOrange),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Categorias',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: darkText,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${categoriasMap.length} categorias disponíveis',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: textLight,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 
                      ? 5 
                      : MediaQuery.of(context).size.width > 800 
                          ? 4 
                          : MediaQuery.of(context).size.width > 600 
                              ? 3 
                              : 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categoriasMap.length,
                itemBuilder: (_, i) {
                  final cat = categoriasMap.keys.elementAt(i);
                  final produtos = categoriasMap[cat]!;
                  final total = produtos.fold(0, (s, p) => s + p.fardos + p.avulsas);
                  final gradient = lojaGradients[i % lojaGradients.length];

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (i * 50)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          setState(() => categoriaSelecionada = cat);
                          _pageAnimationController.reset();
                          _pageAnimationController.forward();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardWhite,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Badge de contagem no canto superior direito
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: gradient),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gradient[0].withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '$total',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          gradient[0].withOpacity(0.15),
                                          gradient[1].withOpacity(0.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      size: 40,
                                      color: gradient[0],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      cat,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: darkText,
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${produtos.length} produto${produtos.length != 1 ? 's' : ''}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: textLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaProdutos() {
    final lista = categoriasMap[categoriaSelecionada] ?? [];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header da categoria com botão de voltar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardWhite, lightGray],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() => categoriaSelecionada = null);
                      _pageAnimationController.reset();
                      _pageAnimationController.forward();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryOrange.withOpacity(0.1),
                            lightOrange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryOrange.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: primaryOrange,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoriaSelecionada!,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: darkText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: successGreen.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${lista.length} disponíveis',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: successGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista de produtos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final p = lista[i];
                final qtd = CarrinhoExpedicao.itens[p.id] ?? {'f': 0, 'a': 0};
                final temNoCarrinho = qtd['f']! > 0 || qtd['a']! > 0;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (i * 30)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: temNoCarrinho
                          ? LinearGradient(
                              colors: [
                                primaryOrange.withOpacity(0.05),
                                lightOrange.withOpacity(0.05),
                              ],
                            )
                          : null,
                      color: temNoCarrinho ? null : cardWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: temNoCarrinho 
                          ? Border.all(color: primaryOrange, width: 2)
                          : Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: temNoCarrinho 
                              ? primaryOrange.withOpacity(0.2)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: temNoCarrinho ? 20 : 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header do produto
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: temNoCarrinho
                                        ? [primaryOrange, lightOrange]
                                        : [
                                            primaryOrange.withOpacity(0.1),
                                            lightOrange.withOpacity(0.1),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: temNoCarrinho
                                      ? [
                                          BoxShadow(
                                            color: primaryOrange.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: temNoCarrinho ? Colors.white : primaryOrange,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nome,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: darkText,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildEstoqueBadge(
                                          '${p.fardos}',
                                          'fardos',
                                          primaryOrange,
                                          Icons.widgets_rounded,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildEstoqueBadge(
                                          '${p.avulsas}',
                                          'avulsas',
                                          accentBlue,
                                          Icons.apps_rounded,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Indicador visual se tem no carrinho
                              if (temNoCarrinho)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [primaryOrange, lightOrange],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryOrange.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Controles de quantidade
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: lightGray,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildQuantidadeRow(
                                  'Fardos',
                                  Icons.widgets_rounded,
                                  qtd['f']!,
                                  p.fardos,
                                  primaryOrange,
                                  () => _remover(p.id, 'f'),
                                  () => _adicionarComLimite(p.id, 'f'),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.grey.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildQuantidadeRow(
                                  'Avulsas',
                                  Icons.apps_rounded,
                                  qtd['a']!,
                                  p.avulsas,
                                  accentBlue,
                                  () => _remover(p.id, 'a'),
                                  () => _adicionarComLimite(p.id, 'a'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstoqueBadge(String quantidade, String label, Color cor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cor),
          const SizedBox(width: 6),
          Text(
            quantidade,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: cor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantidadeRow(
    String label,
    IconData icon,
    int quantidade,
    int estoque,
    Color cor,
    VoidCallback onRemove,
    VoidCallback onAdd,
  ) {
    final porcentagem = estoque > 0 ? (quantidade / estoque) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: cor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: darkText,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estoque: $estoque',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Botões de controle
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: quantidade > 0 ? onRemove : null,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: quantidade > 0
                        ? LinearGradient(
                            colors: [
                              dangerRed.withOpacity(0.15),
                              dangerRed.withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: quantidade > 0 ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                    border: quantidade > 0
                        ? Border.all(color: dangerRed.withOpacity(0.3), width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: quantidade > 0 ? dangerRed : Colors.grey,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 60),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: quantidade > 0
                    ? LinearGradient(
                        colors: [cor, cor.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: quantidade > 0 ? null : cardWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: quantidade > 0
                    ? [
                        BoxShadow(
                          color: cor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                border: quantidade == 0
                    ? Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5)
                    : null,
              ),
              child: Text(
                '$quantidade',
                style: GoogleFonts.inter(
                  color: quantidade > 0 ? Colors.white : textLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: estoque > quantidade ? onAdd : null,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: estoque > quantidade
                        ? LinearGradient(
                            colors: [
                              cor.withOpacity(0.15),
                              cor.withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: estoque > quantidade ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                    border: estoque > quantidade
                        ? Border.all(color: cor.withOpacity(0.3), width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: estoque > quantidade ? cor : Colors.grey,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Barra de progresso
        if (quantidade > 0) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: porcentagem),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                  minHeight: 6,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(porcentagem * 100).toStringAsFixed(0)}% do estoque',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}