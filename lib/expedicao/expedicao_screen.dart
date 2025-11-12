// lib/expedicao/expedicao_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../produto.dart';

class ExpedicaoScreen extends StatefulWidget {
  const ExpedicaoScreen({super.key});

  @override
  State<ExpedicaoScreen> createState() => _ExpedicaoScreenState();
}

class _ExpedicaoScreenState extends State<ExpedicaoScreen> {
  List<Produto> produtos = [];
  List<Map<String, dynamic>> lojas = [];
  int? lojaSelecionadaId;
  String? lojaSelecionadaNome;

  // Carrinho temporário: {produto_id: {fardos: X, avulsas: Y}}
  final Map<int, Map<String, int>> _carrinho = {};

  bool isLoading = true;
  bool isSending = false;

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color lightOrange = Color(0xFFFF8555);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color borderGray = Color(0xFFE9ECEF);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);
    try {
      final List<dynamic> results = await Future.wait([
        ApiService.getEstoque(),
        _carregarLojas(),
      ]);

      final List<Produto> estoque = results[0] as List<Produto>;
      final List<Map<String, dynamic>> listaLojas = results[1] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          produtos = estoque;
          lojas = listaLojas;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) _mostrarErro('Erro ao carregar dados');
    }
  }

  Future<List<Map<String, dynamic>>> _carregarLojas() async {
    // MOCK TEMPORÁRIO (depois vem do banco)
    return List.generate(16, (i) => {
      'id': i + 1,
      'nome': [
        'Silviano', 'Prudente', 'Belvedere', 'Pampulha', 'Mangabeiras',
        'Delivery', 'Castelo', 'Barreiro', 'Eldorado', 'Silva Lobo',
        'Buritis', 'Cidade Nova', 'Afonsos', 'Ouro Preto', 'Sion', 'Lagoa Santa'
      ][i]
    });
  }

  void _adicionarAoCarrinho(int produtoId, String tipo) {
    setState(() {
      _carrinho.putIfAbsent(produtoId, () => {'f': 0, 'a': 0});
      _carrinho[produtoId]![tipo == 'f' ? 'f' : 'a'] =
          (_carrinho[produtoId]![tipo == 'f' ? 'f' : 'a'] ?? 0) + 1;
    });
  }

  void _limparCarrinho() {
    setState(() => _carrinho.clear());
  }

  int _totalItens() {
    return _carrinho.values.fold(0, (sum, item) => sum + item['f']! + item['a']!);
  }

  Future<void> _confirmarEnvio() async {
    if (lojaSelecionadaId == null || _carrinho.isEmpty) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar Expedição'),
        content: Text(
          'Enviar ${_totalItens()} item(ns) para **$lojaSelecionadaNome**?\n\n'
          'Isso irá **subtrair do estoque geral**.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    setState(() => isSending = true);
    try {
      await _enviarExpedicao();
      _limparCarrinho();
      _mostrarSucesso('Enviado com sucesso para $lojaSelecionadaNome!');
    } catch (e) {
      _mostrarErro('Falha ao enviar');
    } finally {
      setState(() => isSending = false);
    }
  }

  Future<void> _enviarExpedicao() async {
    // Mock temporário – depois será POST para /expedir.php
    await Future.delayed(const Duration(seconds: 1));
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightGray,
      child: Column(
        children: [
          // Header com seleção de loja
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_rounded, color: primaryOrange, size: 28),
                const SizedBox(width: 12),
                Text('Expedição', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: lightGray, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButton<int>(
                    value: lojaSelecionadaId,
                    hint: Text('Selecione a loja', style: GoogleFonts.inter()),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: lojas.map((l) => DropdownMenuItem<int>(
                      value: l['id'] as int,
                      child: Text(l['nome'] as String),
                    )).toList(),
                    onChanged: (id) {
                      setState(() {
                        lojaSelecionadaId = id;
                        lojaSelecionadaNome = lojas.firstWhere((l) => l['id'] == id)['nome'] as String;
                        _limparCarrinho();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Carrinho flutuante
          if (_carrinho.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_rounded, color: primaryOrange),
                  const SizedBox(width: 12),
                  Text('$_totalItens item(ns) no carrinho', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(onPressed: _limparCarrinho, child: const Text('Limpar', style: TextStyle(color: Colors.red))),
                  ElevatedButton(
                    onPressed: isSending ? null : _confirmarEnvio,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
                    child: isSending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enviar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

          // Lista de produtos
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                : lojaSelecionadaId == null
                    ? Center(child: Text('* EM PRODUÇÃO *', style: GoogleFonts.inter()))
                    : RefreshIndicator(
                        onRefresh: _carregarDados,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: produtos.length,
                          itemBuilder: (context, i) {
                            final p = produtos[i];
                            final noCarrinho = _carrinho[p.id] ?? {'f': 0, 'a': 0};
                            return _buildProdutoCard(p, noCarrinho['f']!, noCarrinho['a']!);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(Produto p, int fardosCarrinho, int avulsasCarrinho) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.nome, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (fardosCarrinho > 0 || avulsasCarrinho > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                  child: Text('$fardosCarrinho f • $avulsasCarrinho a',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAddButton('FARDOS', p.fardos, () => _adicionarAoCarrinho(p.id, 'f'), primaryOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAddButton('AVULSAS', p.avulsas, () => _adicionarAoCarrinho(p.id, 'a'), lightOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, int estoqueAtual, VoidCallback onTap, Color color) {
    final disponivel = estoqueAtual > 0;
    return Opacity(
      opacity: disponivel ? 1.0 : 0.5,
      child: InkWell(
        onTap: disponivel ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}