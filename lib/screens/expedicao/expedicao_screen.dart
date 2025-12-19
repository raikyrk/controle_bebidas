// lib/expedicao/expedicao_screen.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Necessário para BackdropFilter
import '../../api_service.dart';
import '../../produto.dart';
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

  // === PALETA FIRE MODE ===
  static const Color pureBlack = Color(0xFF000000);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color brightOrange = Color(0xFFFF4500);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color cyanNeon = Color(0xFF00E5FF); // Para Avulsas
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color grayText = Color(0xFFAAAAAA);
  static const Color borderGray = Color(0xFF333333);
  static const Color dangerRed = Color(0xFFFF3333);

  // Mantive seus ícones
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

  // Gradients adaptados para brilhar no escuro
  final List<List<Color>> lojaGradients = [
    [Color(0xFFFF4500), Color(0xFFFF6B00)], // Laranja
    [Color(0xFF2979FF), Color(0xFF448AFF)], // Azul
    [Color(0xFFD500F9), Color(0xFFE040FB)], // Roxo
    [Color(0xFFFF1744), Color(0xFFFF5252)], // Vermelho
    [Color(0xFF00E676), Color(0xFF69F0AE)], // Verde
    [Color(0xFFFFC400), Color(0xFFFFD740)], // Amarelo
    [Color(0xFF1DE9B6), Color(0xFF64FFDA)], // Teal
    [Color(0xFFFF9100), Color(0xFFFFAB40)], // Laranja Claro
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeOutCubic),
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
        _mostrarSnackBar('Erro ao carregar dados', dangerRed, Icons.error_outline);
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
        lojas.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        return lojas;
      }
    } catch (e) {
      debugPrint('Erro: $e');
    }
    // Fallback
    final fallback = <Map<String, dynamic>>[];
    final nomes = ['Silviano', 'Prudente', 'Belvedere', 'Pampulha', 'Mangabeiras', 'Delivery', 'Castelo', 'Barreiro', 'Eldorado', 'Silva Lobo', 'Buritis', 'Cidade Nova', 'Afonsos', 'Ouro Preto', 'Sion', 'Lagoa Santa'];
    for (int i = 0; i < nomes.length; i++) {
      fallback.add({'id': i + 1, 'nome': nomes[i]});
    }
    return fallback;
  }

  void _adicionarComLimite(int produtoId, String tipo) {
    // Lógica mantida, apenas removi o "setState" excessivo pois usaremos ValueNotifier na próxima otimização se precisar
    // Por enquanto, setState é necessário para atualizar a UI desta tela
    final produto = produtos.firstWhere((p) => p.id == produtoId);
    final noCarrinho = CarrinhoExpedicao.itens[produtoId] ?? {'f': 0, 'a': 0};

    int estoqueDisponivel = tipo == 'f' ? produto.fardos : produto.avulsas;
    int jaNoCarrinho = tipo == 'f' ? (noCarrinho['f'] ?? 0) : (noCarrinho['a'] ?? 0);

    if (jaNoCarrinho >= estoqueDisponivel) {
      _mostrarSnackBar('Limite de estoque atingido!', dangerRed, Icons.warning_amber_rounded);
      return;
    }

    CarrinhoExpedicao.adicionar(produtoId, tipo);
    setState(() {}); // Atualiza a tela

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
            Icon(icon, color: pureWhite, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: cardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cor.withOpacity(0.5)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildFireHeader(),
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
          ? _buildNeonFAB()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ===================================
  // 🔥 HEADER FIRE MODE
  // ===================================
  Widget _buildFireHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: pureBlack,
        border: Border(bottom: BorderSide(color: borderGray, width: 1)),
      ),
      child: Row(
        children: [
          // Ícone Principal (Caminhão)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brightOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brightOrange.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: brightOrange.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: -5,
                )
              ],
            ),
            child: Icon(Icons.local_shipping_rounded, color: brightOrange, size: 28),
          ),
          const SizedBox(width: 16),
          
          // Texto Dinâmico
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expedição',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: pureWhite,
                    height: 1.1,
                  ),
                ),
                if (lojaSelecionadaNome != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          lojaSelecionadaNome!,
                          style: GoogleFonts.inter(color: brightOrange, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (categoriaSelecionada != null) ...[
                          Icon(Icons.chevron_right, color: grayText, size: 16),
                          Expanded(
                            child: Text(
                              categoriaSelecionada!,
                              style: GoogleFonts.inter(color: grayText, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Botão Trocar Loja (só aparece se loja selecionada)
          if (lojaSelecionadaId != null)
            IconButton(
              onPressed: () {
                setState(() {
                  lojaSelecionadaId = null;
                  lojaSelecionadaNome = null;
                  categoriaSelecionada = null;
                  CarrinhoExpedicao.limpar();
                });
                _pageAnimationController.reset();
                _pageAnimationController.forward();
              },
              icon: Icon(Icons.swap_horiz_rounded, color: grayText),
              tooltip: 'Trocar Loja',
            )
        ],
      ),
    );
  }

  // ===================================
  // 🏪 SELEÇÃO DE LOJA (DARK GRID)
  // ===================================
  Widget _buildSelecaoLoja() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Text(
                'Selecione o Destino',
                style: GoogleFonts.inter(fontSize: 16, color: grayText, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: lojas.length,
                itemBuilder: (_, i) {
                  final loja = lojas[i];
                  final gradient = lojaGradients[i % lojaGradients.length];
                  
                  return _buildDarkCard(
                    onTap: () {
                      setState(() {
                        lojaSelecionadaId = loja['id'];
                        lojaSelecionadaNome = loja['nome'];
                        CarrinhoExpedicao.limpar();
                      });
                      _pageAnimationController.reset();
                      _pageAnimationController.forward();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ícone com Glow
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [gradient[0].withOpacity(0.2), gradient[1].withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: gradient[0].withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(color: gradient[0].withOpacity(0.15), blurRadius: 20, spreadRadius: -5),
                            ]
                          ),
                          child: Icon(lojaIcons[loja['nome']] ?? Icons.store, color: gradient[0], size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loja['nome'],
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: pureWhite
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  // ===================================
  // 📦 GRID CATEGORIAS (DARK)
  // ===================================
  Widget _buildGridCategorias() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Text(
                'O que vamos enviar?',
                style: GoogleFonts.inter(fontSize: 16, color: grayText, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0, // Quadrado perfeito
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categoriasMap.length,
                itemBuilder: (_, i) {
                  final cat = categoriasMap.keys.elementAt(i);
                  final produtosCat = categoriasMap[cat]!;
                  final totalItens = produtosCat.fold(0, (s, p) => s + p.fardos + p.avulsas);
                  
                  return _buildDarkCard(
                    onTap: () {
                      setState(() => categoriaSelecionada = cat);
                      _pageAnimationController.reset();
                      _pageAnimationController.forward();
                    },
                    child: Stack(
                      children: [
                        // Marca d'água
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(Icons.category, size: 80, color: pureWhite.withOpacity(0.03)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.inventory_2_outlined, color: brightOrange, size: 30),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: pureWhite, height: 1.2
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalItens itens',
                                    style: GoogleFonts.inter(fontSize: 12, color: grayText),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
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

  // ===================================
  // 📝 LISTA DE PRODUTOS (CONTROL PANEL STYLE)
  // ===================================
  Widget _buildListaProdutos() {
    final lista = categoriasMap[categoriaSelecionada] ?? [];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Botão voltar inline
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: GestureDetector(
              onTap: () {
                setState(() => categoriaSelecionada = null);
                _pageAnimationController.reset();
                _pageAnimationController.forward();
              },
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: brightOrange, size: 18),
                  const SizedBox(width: 8),
                  Text('Voltar para categorias', style: GoogleFonts.inter(color: brightOrange, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final p = lista[i];
                final qtd = CarrinhoExpedicao.itens[p.id] ?? {'f': 0, 'a': 0};
                final temNoCarrinho = qtd['f']! > 0 || qtd['a']! > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cardBlack,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: temNoCarrinho ? brightOrange.withOpacity(0.5) : borderGray,
                      width: 1
                    ),
                    boxShadow: [
                      if (temNoCarrinho)
                        BoxShadow(color: brightOrange.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Column(
                    children: [
                      // Header do Produto
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: pureBlack,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderGray),
                              ),
                              child: Icon(Icons.inventory_2_rounded, color: pureWhite, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                p.nome,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: pureWhite),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Divider(color: borderGray, height: 1),

                      // Controles (Lado a Lado)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Controle Fardos
                            Expanded(
                              child: _buildControlCapsule(
                                label: 'FARDOS',
                                count: qtd['f']!,
                                max: p.fardos,
                                color: brightOrange,
                                onAdd: () => _adicionarComLimite(p.id, 'f'),
                                onRemove: () => _remover(p.id, 'f'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Controle Avulsas
                            Expanded(
                              child: _buildControlCapsule(
                                label: 'AVULSAS',
                                count: qtd['a']!,
                                max: p.avulsas,
                                color: cyanNeon,
                                onAdd: () => _adicionarComLimite(p.id, 'a'),
                                onRemove: () => _remover(p.id, 'a'),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Auxiliar: Cápsula de Controle
  Widget _buildControlCapsule({
    required String label,
    required int count,
    required int max,
    required Color color,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    final isActive = count > 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: pureBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : borderGray,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isActive ? color : grayText, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniButton(Icons.remove, onRemove, isActive),
              Text(
                '$count',
                style: GoogleFonts.robotoMono(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: isActive ? pureWhite : grayText
                ),
              ),
              _buildMiniButton(Icons.add, onAdd, count < max),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Max: $max',
            style: GoogleFonts.inter(fontSize: 10, color: grayText.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, VoidCallback onTap, bool enabled) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? borderGray : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: enabled ? pureWhite : borderGray),
      ),
    );
  }

  // ===================================
  // 🧩 WIDGETS GENÉRICOS DARK
  // ===================================
  Widget _buildDarkCard({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderGray),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildNeonFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: brightOrange.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => ChecagemScreen(
                    lojaId: lojaSelecionadaId!,
                    lojaNome: lojaSelecionadaNome!,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [brightOrange, neonOrange]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_add_check_rounded, color: pureWhite),
                  const SizedBox(width: 12),
                  Text(
                    'Revisar (${CarrinhoExpedicao.totalItens})',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: pureWhite),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: brightOrange),
          const SizedBox(height: 16),
          Text('Carregando...', style: GoogleFonts.inter(color: grayText)),
        ],
      ),
    );
  }
}