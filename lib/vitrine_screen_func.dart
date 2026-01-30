import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'produto.dart';
import 'carrinho_service.dart'; 

// ==============================================================================
// 1. CONSTANTES DE ESTILO
// ==============================================================================
class VitrineTheme {
  static const Color brandOrange = Color(0xFFFF6B35);
  static const Color brandOrangeLight = Color(0xFFFF8F6B);
  static const Color textDark = Color(0xFF1A1D2E);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textGrey = Color(0xFF9CA3AF);

  static final Color glassBackground = Colors.white.withOpacity(0.25);
  static final Color glassBorder = Colors.white.withOpacity(0.5);
  static final Color glassHighlight = Colors.white.withOpacity(0.9);
  static final Color glassShadow = const Color(0xFF1A1D2E).withOpacity(0.08);
  static final Color glassInner = Colors.white.withOpacity(0.15);
}

// ==============================================================================
// 2. CARD DO PRODUTO (MOSTRA O SALDO VISUAL)
// ==============================================================================
class ProdutoCardGlass extends StatelessWidget {
  final Produto produto;
  final Color statusColor;
  final bool isZero;
  final int index;
  final VoidCallback onTap;

  const ProdutoCardGlass({
    super.key,
    required this.produto,
    required this.statusColor,
    required this.isZero,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calcula quanto "visual" resta (Total DB - Total Carrinho Global)
    // O usuário vê o estoque diminuindo conforme adiciona ao carrinho
    int fardosReservados = CarrinhoService().qtdFardosReservados(produto.nome);
    int unidadesReservadas = CarrinhoService().qtdUnidadesReservadas(produto.nome);
    
    int saldoFardos = (produto.fardos - fardosReservados).clamp(0, 9999);
    int saldoUnidades = (produto.avulsas - unidadesReservadas).clamp(0, 9999);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40.0 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [VitrineTheme.glassHighlight, VitrineTheme.glassBackground],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: VitrineTheme.glassBorder, width: 1.5),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: statusColor.withOpacity(0.6), blurRadius: 12)],
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(produto.nome,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: VitrineTheme.textDark),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: VitrineTheme.textGrey.withOpacity(0.1)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(child: _buildGlassCounter('Fardos', saldoFardos)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildGlassCounter('Unidades', saldoUnidades)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCounter(String label, int value) {
    bool hasValue = value > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: VitrineTheme.glassInner,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value.toString(), style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: hasValue ? VitrineTheme.brandOrange : VitrineTheme.textGrey)),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: VitrineTheme.textDark)),
        ],
      ),
    );
  }
}

// ==============================================================================
// 3. MODAL SIMPLIFICADO (RECEBE A LOJA JÁ ESCOLHIDA)
// ==============================================================================
class SolicitacaoModalGlass extends StatefulWidget {
  final Produto produto;
  final Color accentColor;
  final String lojaPreSelecionada; // <--- VEM DA TELA PRINCIPAL

  const SolicitacaoModalGlass({
    super.key,
    required this.produto,
    required this.accentColor,
    required this.lojaPreSelecionada,
  });

  @override
  State<SolicitacaoModalGlass> createState() => _SolicitacaoModalGlassState();
}

class _SolicitacaoModalGlassState extends State<SolicitacaoModalGlass> {
  int qtdFardos = 0;
  int qtdUnidades = 0;
  late int maxFardosDisponiveis;
  late int maxUnidadesDisponiveis;

  @override
  void initState() {
    super.initState();
    _calculaDisponivel();
  }

  void _calculaDisponivel() {
    // Quanto já foi reservado no carrinho GLOBAL (todas as lojas)
    // Se quiser que o estoque seja compartilhado entre lojas (ex: 10 total, 5 pra Savassi, sobra 5 pro Sion)
    int reservadoF = CarrinhoService().qtdFardosReservados(widget.produto.nome);
    int reservadoU = CarrinhoService().qtdUnidadesReservadas(widget.produto.nome);

    setState(() {
      maxFardosDisponiveis = (widget.produto.fardos - reservadoF).clamp(0, 9999);
      maxUnidadesDisponiveis = (widget.produto.avulsas - reservadoU).clamp(0, 9999);
    });
  }

  void _adicionarAoCarrinho() {
    if (qtdFardos == 0 && qtdUnidades == 0) return;

    CarrinhoService().adicionarItem(
      widget.lojaPreSelecionada, // Usa a loja que veio do Header
      widget.produto.nome,
      qtdFardos,
      qtdUnidades,
    );

    HapticFeedback.mediumImpact();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Adicionado para ${widget.lojaPreSelecionada}", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: VitrineTheme.brandOrange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: Colors.white.withOpacity(0.95),
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de qual loja estamos adicionando
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VitrineTheme.brandOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("Adicionando para: ${widget.lojaPreSelecionada.toUpperCase()}", 
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: VitrineTheme.brandOrange)
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(widget.produto.nome, 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: VitrineTheme.textDark)
                ),
                
                const SizedBox(height: 24),

                // Contadores
                _buildCounter('Fardos', qtdFardos, maxFardosDisponiveis, 
                  (v) => setState(() => qtdFardos = v)),
                
                const SizedBox(height: 12),
                
                _buildCounter('Unidades', qtdUnidades, maxUnidadesDisponiveis, 
                  (v) => setState(() => qtdUnidades = v)),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (qtdFardos > 0 || qtdUnidades > 0) ? _adicionarAoCarrinho : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VitrineTheme.brandOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text("Confirmar", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int val, int max, Function(int) onChange) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label (Disp: $max)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline), 
                onPressed: val > 0 ? () => onChange(val - 1) : null
              ),
              Text(val.toString(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: VitrineTheme.brandOrange), 
                onPressed: val < max ? () => onChange(val + 1) : null
              ),
            ],
          )
        ],
      ),
    );
  }
}

class AnimatedOrb extends StatelessWidget {
  final double size;
  final Color color;
  final int delay;
  const AnimatedOrb({super.key, required this.size, required this.color, this.delay = 0});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}