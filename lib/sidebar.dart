// lib/sidebar.dart - Versão Caprichada (FIXED: Removido 'inset' e atualizado 'withOpacity')
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'widgets/home_screen.dart'; 
import 'screens/expedicao/expedicao_screen.dart';
import 'screens/adicionar_produto_screen.dart' as add; 

// ====================================================================
// 💡 NOVOS CONSTANTES DE ESTILO 
// ====================================================================

// Cores e Estilos aprimorados para uma UX/UI elegante
const Color _kPrimaryColor = Color(0xFFFF6B35); // Laranja Principal
const Color _kDarkBackground = Color(0xFF121212); // Fundo escuro aprofundado
const Color _kDarkSurface = Color(0xFF1E1E1E); // Superfície de componentes escuros
const double _kBorderRadius = 12.0; // Raio de borda uniforme e suave

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _selectedMain = 'Estoque Geral';
  String _selectedCategory = '';
  
  void selectMainItem(String title) {
    setState(() {
      _selectedMain = title;
      _selectedCategory = '';
    });
  }

  // ====================================================================
  // 💅 MENU ITEM - Design Sofisticado
  // ====================================================================
  Widget _menuItem(String title, IconData icon, {required bool isSelected}) {
    // CORREÇÃO: Usando .withAlpha() ao invés de .withOpacity()
    final iconColor = isSelected ? Colors.white : Colors.white.withAlpha(255 * 45 ~/ 100); // 45% opacidade
    final textColor = isSelected ? Colors.white : Colors.white.withAlpha(255 * 70 ~/ 100); // 70% opacidade

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // CORREÇÃO: Usando .withAlpha()
        color: isSelected ? null : _kDarkSurface.withAlpha(255 * 50 ~/ 100), // 50% opacidade
        gradient: isSelected
            ? const LinearGradient(
                colors: [_kPrimaryColor, Color(0xFFFF8C42)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  // CORREÇÃO: Usando .withAlpha()
                  color: _kPrimaryColor.withAlpha(255 * 30 ~/ 100), // 30% opacidade
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  // CORREÇÃO: Usando .withAlpha()
                  color: Colors.black.withAlpha(255 * 20 ~/ 100), // 20% opacidade
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
        borderRadius: BorderRadius.circular(_kBorderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          onTap: () {
            selectMainItem(title); 
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected) 
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ==================== SIDEBAR ====================
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kDarkBackground, Color(0xFF1A1A1A)], 
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 15,
                  offset: Offset(4, 0),
                )
              ],
            ),
            child: Column(
              children: [
                // LOGO - Com mais respiro e menos BOX
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 28), // Mais padding superior
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                       colors: [Color(0xFF1E1E1E), _kDarkBackground], // Fundo sutilmente mais claro
                       begin: Alignment.topCenter,
                       end: Alignment.bottomCenter,
                    ),
                     border: const Border(bottom: BorderSide(color: Colors.white10)),
                    boxShadow: [
                      BoxShadow( // Sombra sutil para destacar a área do logo
                        // Corrigido para .withAlpha()
                        color: Colors.black.withAlpha(255 * 50 ~/ 100), // 50% opacidade
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: _kPrimaryColor, // Cor de destaque no ícone
                            shape: BoxShape.circle
                        ),
                        // ✅ RESTAURADO: Seu asset de imagem original
                        child: Image.asset(
                          'assets/go-icon.png', // Caminho EXATO do asset
                          width: 28, 
                          height: 28, 
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ao Gosto',
                                // ✅ CORRIGIDO: Aplicando GoogleFonts.inter ao invés de TextStyle padrão
                                style: GoogleFonts.inter(
                                  color: Colors.white, 
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                )),
                            const SizedBox(height: 2),
                            const Text('Controle de Bebidas',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // CONFERENTE DROPDOWN
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: _ConferenteDropdown(),
                ),

                const Divider(height: 1, color: Colors.white12, indent: 24, endIndent: 24),
                const SizedBox(height: 16),

                // MENU
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    children: [
                      _menuItem('Estoque Geral', Icons.inventory_2_rounded,
                          isSelected: _selectedMain == 'Estoque Geral'),
                      _menuItem('Expedição', Icons.local_shipping_rounded,
                          isSelected: _selectedMain == 'Expedição'),
                      _menuItem('Adicionar Produto', Icons.add_box_rounded,
                          isSelected: _selectedMain == 'Adicionar Produto'),
                      const SizedBox(height: 24),
                       const Text('FERRAMENTAS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                      
                    ],
                  ),
                ),

                // RODAPÉ - LOGOUT
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.copyright_rounded, size: 10, color: Colors.white30),
                          SizedBox(width: 4),
                          Text('Ao Gosto 2025',
                              style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      if (ApiService.conferenteNome != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(_kBorderRadius),
                            onTap: () async {
                              final sair = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                          title: const Text('Sair'),
                                          content: const Text('Deseja realmente sair?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
                                          ],
                                        ),
                                      ) ?? false;

                              if (sair && mounted) {
                                await ApiService.logout();
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                                borderRadius: BorderRadius.circular(_kBorderRadius), 
                                boxShadow: [
                                  // CORREÇÃO: Usando .withAlpha()
                                  BoxShadow(color: Colors.red.withAlpha(255 * 40 ~/ 100), blurRadius: 8, offset: const Offset(0, 2)) // 40% opacidade
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Sair', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
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

          // ==================== CONTEÚDO PRINCIPAL ====================
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _selectedMain == 'Estoque Geral'
                  ? HomeScreen(
                        key: const ValueKey('estoque'),
                        selectedCategory: _selectedCategory,
                        onCategoryChanged: (c) => setState(() => _selectedCategory = c),
                        onMainItemChanged: selectMainItem, 
                    )
                  : _selectedMain == 'Expedição'
                      ? const ExpedicaoScreen(key: ValueKey('expedicao'))
                      : _selectedMain == 'Adicionar Produto'
                          ? add.AdicionarProdutoScreen(
                                key: const ValueKey('adicionar'),
                                onMainItemChanged: selectMainItem, 
                              )
                          : const Center(child: Text('Em desenvolvimento...', key: ValueKey('dev'))),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// ⚙️ CONFERENTE DROPDOWN - Corrigido 'inset' e 'withOpacity'
// ====================================================================
class _ConferenteDropdown extends StatelessWidget {
  const _ConferenteDropdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kDarkSurface,
        borderRadius: BorderRadius.circular(_kBorderRadius), 
        // CORREÇÃO: Usando .withAlpha()
        border: Border.all(color: Colors.white.withAlpha(255 * 10 ~/ 100)), // 10% opacidade
        boxShadow: [
          // REMOVIDO 'inset': Usando apenas a sombra externa de profundidade
          BoxShadow(
            // CORREÇÃO: Usando .withAlpha()
            color: Colors.black.withAlpha(255 * 40 ~/ 100), // 40% opacidade
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
          // Sombra para simular o brilho superior (efeito de relevo sutil)
          BoxShadow(
            // CORREÇÃO: Usando .withAlpha()
            color: Colors.white.withAlpha(255 * 5 ~/ 100), // 5% opacidade
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getConferentes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: _kDarkSurface, borderRadius: BorderRadius.circular(_kBorderRadius)),
              child: const Center(child: CircularProgressIndicator(color: _kPrimaryColor, strokeWidth: 2.5)),
            );
          }
          final conferentes = snapshot.data!;
          return DropdownButtonFormField<int>(
            initialValue: ApiService.conferenteId, 
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.person_rounded, color: Colors.white70, size: 20),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
            dropdownColor: _kDarkBackground,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            items: conferentes
                .map((c) => DropdownMenuItem(
                      value: c['id'] as int, 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(c['nome'] as String),
                      ),
                    ))
                .toList(),
            onChanged: (id) async {
              if (id != null) {
                final nome = conferentes.firstWhere((c) => c['id'] == id)['nome'] as String;
                await ApiService.selecionarConferente(id, nome);
              }
            },
          );
        },
      ),
    );
  }
}