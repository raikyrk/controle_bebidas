// lib/expedicao/checagem_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../api_service.dart';
import '../../produto.dart';
import 'carrinho_expedicao.dart';

class ChecagemScreen extends StatefulWidget {
  final int lojaId;
  final String lojaNome;

  const ChecagemScreen({required this.lojaId, required this.lojaNome, super.key});

  @override
  State<ChecagemScreen> createState() => _ChecagemScreenState();
}

class _ChecagemScreenState extends State<ChecagemScreen> with TickerProviderStateMixin {
  bool isSending = false;
  AnimationController? _fabController;
  AnimationController? _headerController;
  
  // === PALETA FIRE MODE ===
  static const Color pureBlack = Color(0xFF000000);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color brightOrange = Color(0xFFFF4500);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color cyanNeon = Color(0xFF00E5FF); // Cor secundária para Avulsas
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color grayText = Color(0xFFAAAAAA);
  static const Color borderGray = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fabController?.dispose();
    _headerController?.dispose();
    super.dispose();
  }

  // Atualiza a tela quando um item é modificado
  void _triggerRefresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (CarrinhoExpedicao.itens.isEmpty) {
      return Scaffold(
        backgroundColor: pureBlack,
        appBar: _buildFireAppBar(context),
        body: _buildEmptyState(),
      );
    }

    return Scaffold(
      backgroundColor: pureBlack,
      extendBodyBehindAppBar: true,
      appBar: _buildFireAppBar(context),
      body: FutureBuilder<List<Produto>>(
        future: ApiService.getEstoque(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          final estoqueList = snapshot.data!;
          // 🚀 OTIMIZAÇÃO: Converter Lista para Map para acesso O(1)
          // Isso evita percorrer a lista inteira para cada item do carrinho
          final estoqueMap = { for (var p in estoqueList) p.id : p };

          final entradas = CarrinhoExpedicao.itens.entries.toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Espaço para o AppBar Transparente
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
              
              // Header Estatísticas
              SliverToBoxAdapter(child: _buildStatisticsHeader(entradas.length)),
              
              // Lista
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = entradas[i];
                      // Busca instantânea no Map
                      final produto = estoqueMap[entry.key] ?? Produto(
                        id: entry.key,
                        nome: 'Produto Removido/Não Encontrado',
                        categoria: 'Erro',
                        fardos: 0,
                        avulsas: 0,
                      );

                      return Column(
                        children: [
                          // Card de Fardos (Laranja)
                          if ((entry.value['f'] ?? 0) > 0)
                            _buildAnimatedItem(
                              index: i,
                              child: FireProductCard(
                                key: ValueKey('${entry.key}-f'),
                                produto: produto,
                                quantidadeInicial: entry.value['f']!,
                                tipoPlural: 'Fardos',
                                color: brightOrange,
                                icon: Icons.inventory_2_rounded,
                                produtoId: entry.key,
                                tipoCarrinho: 'f',
                                onChanged: _triggerRefresh,
                              ),
                            ),

                          // Card de Avulsas (Cyan/Azul Neon)
                          if ((entry.value['a'] ?? 0) > 0)
                            _buildAnimatedItem(
                              index: i,
                              child: FireProductCard(
                                key: ValueKey('${entry.key}-a'),
                                produto: produto,
                                quantidadeInicial: entry.value['a']!,
                                tipoPlural: 'Avulsas',
                                color: cyanNeon,
                                icon: Icons.widgets_rounded,
                                produtoId: entry.key,
                                tipoCarrinho: 'a',
                                onChanged: _triggerRefresh,
                              ),
                            ),
                          
                          const SizedBox(height: 16),
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
      floatingActionButton: _buildFireFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
     if (_headerController == null) return child;
     return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2), // Vem levemente de baixo
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _headerController!,
          curve: Interval(index * 0.05, 1.0, curve: Curves.easeOutCubic),
        )),
        child: FadeTransition(
          opacity: _headerController!,
          child: child,
        ),
      );
  }

  // ===================================
  // 🔥 APP BAR (FIRE MODE)
  // ===================================
  PreferredSizeWidget _buildFireAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: pureBlack.withOpacity(0.8),
              border: Border(bottom: BorderSide(color: borderGray, width: 1)),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderGray),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: pureWhite, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revisão de Envio',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: pureWhite,
            ),
          ),
          Text(
            widget.lojaNome,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: grayText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================
  // 📊 STATISTICS HEADER
  // ===================================
  Widget _buildStatisticsHeader(int totalUniqueProducts) {
    if (_headerController == null) return const SizedBox.shrink();
    
    return FadeTransition(
      opacity: _headerController!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [cardBlack, pureBlack],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderGray),
          boxShadow: [
            BoxShadow(
              color: brightOrange.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Grande Contador
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL DE ITENS',
                  style: GoogleFonts.inter(
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5,
                    color: grayText
                  ),
                ),
                Text(
                  '${CarrinhoExpedicao.totalItens}',
                  style: GoogleFonts.robotoMono( // Ou RobotoMono
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: pureWhite,
                    height: 1.1
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Divisor Vertical
            Container(width: 1, height: 40, color: borderGray),
            const Spacer(),
            // Produtos Únicos
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PRODUTOS',
                  style: GoogleFonts.inter(
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5,
                    color: grayText
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.layers_outlined, color: brightOrange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$totalUniqueProducts',
                       style: GoogleFonts.robotoMono(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: pureWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================================
  // 🚀 FAB DE ENVIO
  // ===================================
  Widget _buildFireFAB(BuildContext context) {
    if (_fabController == null) return const SizedBox.shrink();

    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabController!, curve: Curves.elasticOut),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSending ? Colors.grey.withOpacity(0.1) : brightOrange.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSending ? null : () => _confirmarEnvio(context),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSending
                      ? [cardBlack, cardBlack]
                      : [brightOrange, neonOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSending ? borderGray : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSending)
                    SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: grayText, strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.rocket_launch_rounded, color: pureWhite, size: 22),
                  
                  const SizedBox(width: 12),
                  
                  Text(
                    isSending ? 'ENVIANDO...' : 'FINALIZAR ENVIO',
                    style: GoogleFonts.inter(
                      color: isSending ? grayText : pureWhite,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.0,
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

  // Lógica de Envio (Mantida, mas com Snackbars Dark)
  Future<void> _confirmarEnvio(BuildContext context) async {
    setState(() => isSending = true);
    try {
      await ApiService.expedirParaLoja(widget.lojaId, CarrinhoExpedicao.carrinhoParaEnvio);
      CarrinhoExpedicao.limpar();

      if (!mounted) return;
      _showDarkSnackBar(context, 'Sucesso! Produtos expedidos.', Icons.check_circle, Colors.greenAccent);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showDarkSnackBar(context, 'Erro: $e', Icons.error_outline, Colors.redAccent);
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void _showDarkSnackBar(BuildContext context, String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cardBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderGray)),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: GoogleFonts.inter(color: pureWhite, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  // ===================================
  // 💀 EMPTY & LOADING STATES
  // ===================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart_outlined, size: 80, color: borderGray),
          const SizedBox(height: 20),
          Text(
            'Carrinho Vazio',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: pureWhite),
          ),
          const SizedBox(height: 10),
          Text(
            'Adicione produtos para prosseguir.',
            style: GoogleFonts.inter(color: grayText),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: brightOrange));
  }
}

// ============================================================================
// 🔥 CARD DO PRODUTO (FIRE MODE)
// ============================================================================

class FireProductCard extends StatelessWidget {
  final Produto produto;
  final int quantidadeInicial;
  final String tipoPlural;
  final Color color;
  final IconData icon;
  final int produtoId;
  final String tipoCarrinho;
  final VoidCallback onChanged;

  const FireProductCard({
    super.key,
    required this.produto,
    required this.quantidadeInicial,
    required this.tipoPlural,
    required this.color,
    required this.icon,
    required this.produtoId,
    required this.tipoCarrinho,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Fundo para o Swipe (Dismissible)
    final dismissBackground = Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: Colors.red, size: 30),
    );

    return Dismissible(
      key: ValueKey('${produtoId}_$tipoCarrinho'),
      direction: DismissDirection.endToStart,
      background: dismissBackground,
      onDismissed: (_) {
        // Remove tudo
        while ((CarrinhoExpedicao.itens[produtoId]?[tipoCarrinho] ?? 0) > 0) {
          CarrinhoExpedicao.removerOuDiminuir(produtoId, tipoCarrinho);
        }
        onChanged();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // cardBlack
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)), // Borda Neon sutil
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone Neon
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              
              const SizedBox(width: 16),
              
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nome,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tipoPlural.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color.withOpacity(0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Controle Numérico (Botões + Display)
              _buildQuantityControl(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão Menos
          _SmallButton(
            icon: Icons.remove, 
            onTap: () {
               CarrinhoExpedicao.removerOuDiminuir(produtoId, tipoCarrinho);
               onChanged();
            }
          ),
          
          // Display Valor
          SizedBox(
            width: 36,
            child: Text(
              '$quantidadeInicial',
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono( // Use robotoMono aqui
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          // Botão Mais
          _SmallButton(
            icon: Icons.add, 
            onTap: () {
               CarrinhoExpedicao.adicionar(produtoId, tipoCarrinho);
               onChanged();
            }
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}