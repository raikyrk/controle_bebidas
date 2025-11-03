// home_screen.dart (MESMO CÓDIGO, SÓ PEQUENOS AJUSTES VISUAIS)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  List<Produto> produtos = [];
  Map<String, List<Produto>> categoriasMap = {};
  int totalFardos = 0;
  int totalAvulsas = 0;
  bool isLoading = true;

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color borderGray = Color(0xFFE9ECEF);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color zeroStock = Color(0xFFADB5BD);

  @override
  void initState() {
    super.initState();
    _carregarEstoque();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      setState(() {});
    }
  }

  Future<void> _carregarEstoque() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      produtos = [
        Produto(id: 1, nome: "Coca Cola 2L", categoria: "Refrigerante", fardos: 5, avulsas: 3),
        Produto(id: 2, nome: "Coca Cola Lata", categoria: "Refrigerante", fardos: 0, avulsas: 12),
        Produto(id: 3, nome: "Pepsi 2L", categoria: "Refrigerante", fardos: 2, avulsas: 0),
        Produto(id: 10, nome: "Heineken", categoria: "Cerveja Long Neck", fardos: 3, avulsas: 8),
        Produto(id: 11, nome: "Brahma", categoria: "Cerveja Long Neck", fardos: 1, avulsas: 2),
        Produto(id: 20, nome: "Brahma 600ml", categoria: "Cerveja 600ml", fardos: 4, avulsas: 1),
        Produto(id: 30, nome: "Red Bull", categoria: "Redbull", fardos: 6, avulsas: 4),
        Produto(id: 40, nome: "Gatorade Limão", categoria: "Gatorade", fardos: 2, avulsas: 5),
        Produto(id: 50, nome: "Água São Lourenço", categoria: "Água Mineral", fardos: 10, avulsas: 0),
        Produto(id: 60, nome: "Cachaça 51", categoria: "Diversos", fardos: 1, avulsas: 1),
      ];
      _agruparPorCategoria();
      _calcularTotais();
      isLoading = false;
    });
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

  void _alterar(int id, String tipo, int delta) {
    setState(() {
      final produto = produtos.firstWhere((p) => p.id == id);
      if (tipo == 'f') {
        produto.fardos = (produto.fardos + delta).clamp(0, 999);
      } else {
        produto.avulsas = (produto.avulsas + delta).clamp(0, 999);
      }
      _calcularTotais();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCategory == 'Dashboard') {
      return _buildDashboard();
    }

    final itens = categoriasMap[widget.selectedCategory] ?? [];
    return RefreshIndicator(
      onRefresh: _carregarEstoque,
      color: primaryOrange,
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : itens.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  itemCount: itens.length,
                  itemBuilder: (context, i) => _buildProdutoCard(itens[i]),
                ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
              ),
              child: Icon(Icons.inventory_2_rounded, size: 80, color: primaryOrange),
            ),
            const SizedBox(height: 32),
            Text(
              'Bem-vindo ao Ao Gosto',
              style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie seu estoque com facilidade',
              style: GoogleFonts.inter(fontSize: 16, color: textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: textLight),
          const SizedBox(height: 16),
          Text('Nenhum produto nesta categoria', style: TextStyle(color: textLight, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(Produto p) {
    final isZero = p.fardos == 0 && p.avulsas == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.nome,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isZero ? zeroStock : textDark,
                  ),
                ),
              ),
              if (isZero)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: primaryOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text("SEM ESTOQUE", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: primaryOrange)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildQuantityBox("FARDOS", p.fardos, () => _alterar(p.id, 'f', -1), () => _alterar(p.id, 'f', 1), isZero)),
              const SizedBox(width: 16),
              Expanded(child: _buildQuantityBox("AVULSAS", p.avulsas, () => _alterar(p.id, 'a', -1), () => _alterar(p.id, 'a', 1), isZero)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBox(String label, int value, VoidCallback onDec, VoidCallback onInc, bool isZero) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: textLight, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value.toString(), style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: isZero ? zeroStock : textDark)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(Icons.remove, onDec, value == 0),
              const SizedBox(width: 12),
              _buildActionButton(Icons.add, onInc, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: disabled ? textLight.withOpacity(0.3) : primaryOrange,
          borderRadius: BorderRadius.circular(12),
          boxShadow: disabled ? [] : [BoxShadow(color: primaryOrange.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}