import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'produto.dart';
// Importações Locais
import 'vitrine_screen_func.dart';
import 'carrinho_service.dart';
import 'resumo_carrinho_modal.dart';

class VitrineScreen extends StatefulWidget {
  const VitrineScreen({super.key});

  @override
  State<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends State<VitrineScreen> with TickerProviderStateMixin {
  List<Produto> _produtos = [];
  List<Produto> _filtrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  // === VARIÁVEL: LOJA SELECIONADA NO TOPO ===
  String? _lojaAtual; 
  
  // Lista de Lojas
  final List<String> _lojas = [
    'Silviano', 'Prudente', 'Belvedere', 'Pampulha', 'Mangabeiras', 'Castelo',
    'Barreiro', 'Contagem', 'Silva Lobo', 'Buritis', 'Cidade Nova', 'Afonsos',
    'Ouro Preto', 'Sion', 'Lagoa Santa', 'Serviços Diversos',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final dados = await ApiService.getEstoque();
      setState(() {
        _produtos = dados;
        _filtrados = dados;
        _isLoading = false;
      });
      // Se tiver busca digitada, reaplica o filtro
      if (_searchController.text.isNotEmpty) {
        _filtrar(_searchController.text);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnack('Erro de conexão: $e', isError: true);
    }
  }

  // Função para limpar o carrinho manualmente (Reset)
  void _limparCacheApp() {
    CarrinhoService().limparTudo();
    setState(() {
      _lojaAtual = null; // Reseta a loja selecionada também
    });
    HapticFeedback.mediumImpact();
    _showSnack("Carrinho e seleção limpos!", isError: false);
  }

  void _filtrar(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtrados = _produtos;
      } else {
        _filtrados = _produtos
            .where((p) => p.nome.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFEF4444) : VitrineTheme.brandOrange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _abrirResumoCarrinho(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ResumoCarrinhoModal(),
    );
  }

  // === LÓGICA DE TROCA DE LOJA ===
  void _trocarLoja(String? novaLoja) {
    if (novaLoja == null) return;

    // Se já tem itens no carrinho e a loja é diferente da atual
    if (CarrinhoService().itens.isNotEmpty && _lojaAtual != null && _lojaAtual != novaLoja) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Trocar de Loja?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
            "Você tem itens no carrinho do $_lojaAtual.\nDeseja limpar o pedido atual e iniciar um novo para o $novaLoja?",
            style: GoogleFonts.poppins(),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancelar", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                // Limpa tudo e troca a loja
                CarrinhoService().limparTudo();
                setState(() => _lojaAtual = novaLoja);
                Navigator.pop(ctx);
              },
              child: Text("Limpar e Trocar", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      // Se tá vazio ou é a primeira vez, troca direto
      setState(() => _lojaAtual = novaLoja);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      
      floatingActionButton: AnimatedBuilder(
        animation: CarrinhoService(),
        builder: (context, child) {
          if (CarrinhoService().itens.isEmpty) return const SizedBox();
          
          return FloatingActionButton.extended(
            onPressed: () => _abrirResumoCarrinho(context),
            backgroundColor: VitrineTheme.brandOrange,
            elevation: 8,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              "Finalizar (${CarrinhoService().itens.length})",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        },
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFAFBFC),
              const Color(0xFFFFF5F0),
              VitrineTheme.brandOrange.withOpacity(0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120, right: -80,
              child: AnimatedOrb(size: 280, color: VitrineTheme.brandOrange.withOpacity(0.08)),
            ),
            
            Column(
              children: [
                // 1. HEADER COM SELETOR DE LOJA E BOTÕES DE AÇÃO
                _buildHeaderComSeletor(),
                
                // 2. BUSCA
                _buildGlassSearchBar(),
                
                // 3. LISTA (Só aparece se tiver loja selecionada)
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _lojaAtual == null 
                          ? _buildAvisoSelecioneLoja() // Bloqueia se não tiver loja
                          : _filtrados.isEmpty
                              ? _buildEmptyState()
                              : _buildProductListGlass(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === NOVO HEADER COM DROPDOWN E AÇÕES ===
  Widget _buildHeaderComSeletor() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20), // Top padding para StatusBar
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border(bottom: BorderSide(color: VitrineTheme.glassBorder, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LINHA DO TOPO: Título + Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SELECIONE A LOJA', 
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: VitrineTheme.textGrey, letterSpacing: 1.2)
                  ),
                  
                  // AÇÕES: Limpar Cache e Atualizar
                  Row(
                    children: [
                      // Botão Lixeira (Limpar Cache Local)
                      InkWell(
                        onTap: _limparCacheApp,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botão Refresh (Atualizar API)
                      InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _carregarDados();
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: VitrineTheme.brandOrange.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.refresh_rounded, color: VitrineTheme.brandOrange, size: 20),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              
              // O Dropdown Bonito
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VitrineTheme.brandOrange.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: VitrineTheme.brandOrange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text("Toque para escolher...", style: GoogleFonts.poppins(color: VitrineTheme.textMedium)),
                    value: _lojaAtual,
                    icon: const Icon(Icons.store_rounded, color: VitrineTheme.brandOrange),
                    items: _lojas.map((loja) {
                      return DropdownMenuItem(
                        value: loja,
                        child: Text(loja, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VitrineTheme.textDark, fontSize: 18)),
                      );
                    }).toList(),
                    onChanged: _trocarLoja, // Usa a função de troca segura
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvisoSelecioneLoja() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 80, color: VitrineTheme.brandOrange.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text("Selecione uma loja\npara iniciar o pedido", 
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, color: VitrineTheme.textMedium, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16), // Ajustei padding levemente
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: VitrineTheme.glassBorder, width: 1.5),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrar,
              style: GoogleFonts.poppins(color: VitrineTheme.textDark, fontSize: 16),
              cursorColor: VitrineTheme.brandOrange,
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                hintStyle: GoogleFonts.poppins(color: VitrineTheme.textGrey.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: VitrineTheme.brandOrange),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductListGlass() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: _filtrados.length,
      itemBuilder: (context, index) {
        final produto = _filtrados[index];
        final isZero = produto.fardos == 0 && produto.avulsas == 0;
        final isLow = !isZero && (produto.fardos <= 2 && produto.avulsas <= 5);
        Color statusColor = isZero ? VitrineTheme.textGrey : (isLow ? const Color(0xFFFB923C) : const Color(0xFF10B981));

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ProdutoCardGlass(
            produto: produto,
            statusColor: statusColor,
            isZero: isZero,
            index: index,
            // AQUI É O PULO DO GATO: Passamos a loja selecionada para o modal
            onTap: () => _mostrarModalGlass(context, produto, statusColor),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: VitrineTheme.brandOrange));
  }

  Widget _buildEmptyState() {
    return Center(child: Text("Nada encontrado", style: GoogleFonts.poppins(color: VitrineTheme.textGrey)));
  }

  void _mostrarModalGlass(BuildContext context, Produto produto, Color statusColor) {
    if (_lojaAtual == null) return; // Segurança extra

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SolicitacaoModalGlass(
        produto: produto,
        accentColor: statusColor,
        lojaPreSelecionada: _lojaAtual!, // Passamos a loja obrigatória
      ),
    );
  }
}