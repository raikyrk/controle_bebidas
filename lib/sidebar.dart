// lib/sidebar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'home_screen.dart';
import 'expedicao/expedicao_screen.dart'; // ← NOVA IMPORTAÇÃO

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});
  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _selectedCategory = 'Estoque Geral'; // ← MUDOU AQUI
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _conferentes = [];
  bool _loadingConferentes = true;
  bool _loadingCategories = true;
  String? _hoveredCategory;

  static const double _sidebarWidth = 290;

  @override
  void initState() {
    super.initState();
    _carregarConferentes();
    _carregarCategoriasDoBanco();
    _verificarLoginSalvo();
  }

  Future<void> _verificarLoginSalvo() async {
    final logado = await ApiService.checkLogin();
    if (!logado && mounted && _conferentes.isNotEmpty) {
      _selecionarPrimeiroConferenteSeHouver();
    }
  }

  Future<void> _carregarConferentes() async {
    try {
      final lista = await ApiService.getConferentes();
      setState(() {
        _conferentes = lista;
        _loadingConferentes = false;
      });
      if (ApiService.conferenteId == null && mounted) {
        _selecionarPrimeiroConferenteSeHouver();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar conferentes'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _selecionarPrimeiroConferenteSeHouver() {
    if (_conferentes.isNotEmpty && mounted) {
      final primeiro = _conferentes[0];
      _selecionarConferente(primeiro['id'] as int, primeiro['nome'] as String);
    }
  }

  Future<void> _selecionarConferente(int id, String nome) async {
    try {
      await ApiService.selecionarConferente(id, nome);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar conferente'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _carregarCategoriasDoBanco() async {
    try {
      final listaDoBanco = await ApiService.getCategorias();
      setState(() {
        _departments = [
          {'name': 'Estoque Geral', 'icon': Icons.inventory_2_rounded}, // ← MUDOU
          ...listaDoBanco,
          {'name': 'Expedição', 'icon': Icons.local_shipping_rounded}, // ← NOVA ABA
        ];
        _loadingCategories = false;
      });
    } catch (e) {
      print('Erro ao carregar categorias: $e');
      setState(() {
        _departments = [
          {'name': 'Estoque Geral', 'icon': Icons.inventory_2_rounded},
          {'name': 'Expedição', 'icon': Icons.local_shipping_rounded},
        ];
        _loadingCategories = false;
      });
    }
  }

  IconData _getIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('refrigerante')) return Icons.local_drink;
    if (lower.contains('cerveja')) return Icons.sports_bar_outlined;
    if (lower.contains('redbull')) return Icons.bolt_rounded;
    if (lower.contains('vinho')) return Icons.wine_bar_outlined;
    if (lower.contains('gin')) return Icons.liquor_outlined;
    if (lower.contains('whisky')) return Icons.nightlife_outlined;
    if (lower.contains('gatorade')) return Icons.sports_soccer_outlined;
    if (lower.contains('água')) return Icons.water_drop_outlined;
    if (lower.contains('diversos')) return Icons.inventory_2_outlined;
    if (lower.contains('expedição')) return Icons.local_shipping_rounded;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // === SIDEBAR ===
          Container(
            width: _sidebarWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: Offset(4, 0))],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(24, 56, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
                    boxShadow: [BoxShadow(color: Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 15, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.inventory_2_rounded, size: 28, color: Color(0xFFFF6B35))),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ao Gosto', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            Text('Controle de Bebidas', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 16), child: _loadingConferentes ? _loadingDropdown() : _conferenteDropdown()),

                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Container(height: 1, color: Colors.white.withOpacity(0.1))),
                SizedBox(height: 8),

                Padding(padding: EdgeInsets.fromLTRB(24, 8, 24, 8), child: Text('MENU', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w700))),

                Expanded(
                  child: _loadingCategories
                      ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          itemCount: _departments.length,
                          itemBuilder: (context, index) {
                            final dept = _departments[index];
                            final name = dept['name'] as String;
                            final iconData = dept['icon'] ?? _getIcon(name);
                            final isSelected = _selectedCategory == name;
                            final isHovered = _hoveredCategory == name;

                            return MouseRegion(
                              onEnter: (_) => setState(() => _hoveredCategory = name),
                              onExit: (_) => setState(() => _hoveredCategory = null),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 250),
                                margin: EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]) : null,
                                  color: isSelected ? null : isHovered ? Colors.white.withOpacity(0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSelected ? [BoxShadow(color: Color(0xFFFF6B35).withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))] : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => setState(() => _selectedCategory = name),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: Duration(milliseconds: 250),
                                            padding: EdgeInsets.all(isSelected ? 8 : 6),
                                            decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent, shape: BoxShape.circle),
                                            child: Icon(iconData, color: isSelected ? Colors.white : isHovered ? Color(0xFFFF8C42) : Colors.white.withOpacity(0.6), size: 22),
                                          ),
                                          SizedBox(width: 14),
                                          Expanded(child: Text(name, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                          if (isSelected) Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.copyright_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
                    SizedBox(width: 4),
                    Text('Ao Gosto 2025', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                  ]),
                ),
              ],
            ),
          ),

          // === CONTEÚDO PRINCIPAL ===
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))]),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]), borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          _getIcon(_selectedCategory),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedCategory, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF212529))),
                          Text('Gestão de inventário', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      Spacer(),
                      if (_selectedCategory != 'Estoque Geral')
                        IconButton(icon: Icon(Icons.home_rounded, color: Color(0xFFFF6B35)), onPressed: () => setState(() => _selectedCategory = 'Estoque Geral')),
                      if (ApiService.conferenteNome != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFFFF6B35).withOpacity(0.15), Color(0xFFFF8C42).withOpacity(0.15)]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.3), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]), shape: BoxShape.circle), child: Icon(Icons.person_rounded, size: 16, color: Colors.white)),
                              SizedBox(width: 10),
                              Text(ApiService.conferenteNome!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF6B35))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedCategory == 'Expedição'
                      ? ExpedicaoScreen() // ← RENDERIZA A NOVA TELA
                      : HomeScreen(
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conferenteDropdown() => Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 2))]),
        child: DropdownButtonFormField<int>(
          value: ApiService.conferenteId,
          isDense: true,
          decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), prefixIcon: Container(margin: EdgeInsets.only(right: 8, left: 4), padding: EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.person_rounded, color: Colors.white, size: 16))),
          dropdownColor: Color(0xFF2A2A2A),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF6B35), size: 22),
          isExpanded: true,
          items: _conferentes.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nome'] as String, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (id) => id != null ? _selecionarConferente(id, _conferentes.firstWhere((c) => c['id'] == id)['nome']) : null,
        ),
      );

  Widget _loadingDropdown() => Container(height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.1))), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFFF6B35), strokeWidth: 2.5))));
}