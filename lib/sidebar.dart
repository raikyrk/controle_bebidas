// lib/sidebar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'home_screen.dart';
import 'expedicao/expedicao_screen.dart';
import 'login_screen.dart';
import 'main.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});
  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _selectedMain = 'Estoque Geral';
  String _selectedCategory = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // === SIDEBAR ===
          Container(
            width: 290,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: Offset(4, 0))],
            ),
            child: Column(
              children: [
                // LOGO
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
                    boxShadow: [BoxShadow(color: Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 15, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.inventory_2_rounded, size: 28, color: Color(0xFFFF6B35)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ao Gosto', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            Text('Controle de Bebidas', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // CONFERENTE
                Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), child: _conferenteDropdown()),

                // DIVISOR
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(height: 1, color: Colors.white.withOpacity(0.1))),
                const SizedBox(height: 8),

                // MENU PRINCIPAL
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    children: [
                      _menuItem('Estoque Geral', Icons.inventory_2_rounded, isSelected: _selectedMain == 'Estoque Geral'),
                      _menuItem('Expedição', Icons.local_shipping_rounded, isSelected: _selectedMain == 'Expedição'),
                    ],
                  ),
                ),

                // === RODAPÉ COM LOGOUT ===
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.copyright_rounded, size: 11, color: Colors.white30),
                          const SizedBox(width: 4),
                          Text(
                            'Ao Gosto 2025',
                            style: GoogleFonts.inter(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (ApiService.conferenteNome != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final confirmed = await _showLogoutDialog(context);
                              if (confirmed && mounted) {
                                await ApiService.logout();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginWrapper()),
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Colors.red, Colors.red]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 3))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sair',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === CONTEÚDO ===
          Expanded(
            child: Column(
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Icon(
                          _selectedMain == 'Estoque Geral' ? Icons.inventory_2_rounded : Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _selectedMain,
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF212529)),
                      ),
                      const Spacer(),
                      if (ApiService.conferenteNome != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [const Color(0xFFFF6B35).withOpacity(0.15), const Color(0xFFFF8C42).withOpacity(0.15)]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]), shape: BoxShape.circle),
                                child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                ApiService.conferenteNome!,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFFF6B35)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // CONTEÚDO
                Expanded(
                  child: _selectedMain == 'Estoque Geral'
                      ? HomeScreen(selectedCategory: _selectedCategory, onCategoryChanged: (c) => setState(() => _selectedCategory = c))
                      : _selectedMain == 'Expedição'
                          ? const ExpedicaoScreen()
                          : const Center(child: Text('Página não encontrada')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String title, IconData icon, {required bool isSelected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _selectedMain = title;
              _selectedCategory = '';
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.white : Colors.white.withOpacity(0.6), size: 22),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (isSelected) const Spacer(),
                if (isSelected) const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conferenteDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getConferentes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _loadingDropdown();
          final conferentes = snapshot.data!;
          return DropdownButtonFormField<int>(
            value: ApiService.conferenteId,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.person_rounded, color: Colors.white, size: 16),
            ),
            dropdownColor: const Color(0xFF2A2A2A),
            style: GoogleFonts.inter(color: Colors.white),
            items: conferentes
                .map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nome'] as String)))
                .toList(),
            onChanged: (id) => id != null
                ? ApiService.selecionarConferente(id, conferentes.firstWhere((c) => c['id'] == id)['nome'] as String)
                : null,
          );
        },
      ),
    );
  }

  Widget _loadingDropdown() => Container(
        height: 50,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35), strokeWidth: 2.5)),
      );

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 12,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.red, Colors.red]), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sair do Sistema',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF212529)),
                ),
              ],
            ),
            content: Text(
              'Tem certeza que deseja sair?\nVocê será redirecionado para a tela de login.',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6C757D), height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6C757D)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Sair',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}