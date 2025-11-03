// sidebar.dart (VERSÃO FINAL COM BORDA LARANJA + ÍCONE DESTACADO)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _selectedCategory = 'Dashboard';
  bool _isSidebarExpanded = true;

  final List<Map<String, dynamic>> _departments = [
    {'name': 'Dashboard', 'icon': Icons.dashboard_rounded},
    {'name': 'Refrigerante', 'icon': Icons.local_drink_rounded},
    {'name': 'Cerveja Long Neck', 'icon': Icons.local_bar_rounded},
    {'name': 'Cerveja 600ml', 'icon': Icons.local_bar_rounded},
    {'name': 'Redbull', 'icon': Icons.whatshot_rounded},
    {'name': 'Vinho', 'icon': Icons.wine_bar_rounded},
    {'name': 'Gin', 'icon': Icons.local_bar_rounded},
    {'name': 'Whisky', 'icon': Icons.local_bar_rounded},
    {'name': 'Gatorade', 'icon': Icons.sports_kabaddi_rounded},
    {'name': 'Água Mineral', 'icon': Icons.water_drop_rounded},
    {'name': 'Diversos', 'icon': Icons.category_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // === SIDEBAR FIXA EXPANSÍVEL ===
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _isSidebarExpanded ? 280 : 76,
            decoration: const BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 0))
              ],
            ),
            child: Column(
              children: [
                // HEADER DA SIDEBAR
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.inventory_2_rounded, size: 26, color: Color(0xFFFF6B35)),
                      ),
                      if (_isSidebarExpanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ao Gosto',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Controle de Bebidas',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isSidebarExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                      ),
                    ],
                  ),
                ),

                // === LISTA DE DEPARTAMENTOS COM BORDA LARANJA ===
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _departments.length,
                    itemBuilder: (context, index) {
                      final dept = _departments[index];
                      final isSelected = _selectedCategory == dept['name'];

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
                            width: 1.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selectedCategory = dept['name']),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Row(
                              children: [
                                // ÍCONE COM CÍRCULO BRANCO QUANDO SELECIONADO
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    dept['icon'],
                                    color: isSelected ? const Color(0xFFFF6B35) : Colors.orange.shade300,
                                    size: 20,
                                  ),
                                ),
                                if (_isSidebarExpanded) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      dept['name'],
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // RODAPÉ
                if (_isSidebarExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '© Ao Gosto 2025',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          // === CONTEÚDO PRINCIPAL ===
          Expanded(
            child: Column(
              children: [
                // APPBAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedCategory == 'Dashboard' ? 'Dashboard' : _selectedCategory,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212529),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCategory != 'Dashboard')
                        IconButton(
                          icon: const Icon(Icons.home_rounded, color: Color(0xFFFF6B35)),
                          onPressed: () => setState(() => _selectedCategory = 'Dashboard'),
                        ),
                    ],
                  ),
                ),

                // CONTEÚDO
                Expanded(
                  child: HomeScreen(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (category) => setState(() => _selectedCategory = category),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}