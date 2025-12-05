// lib/screens/adicionar_produto_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class AdicionarProdutoScreen extends StatefulWidget {
  final ValueChanged<String> onMainItemChanged;

  const AdicionarProdutoScreen({
    super.key,
    required this.onMainItemChanged,
  });

  @override
  State<AdicionarProdutoScreen> createState() => _AdicionarProdutoScreenState();
}

class _AdicionarProdutoScreenState extends State<AdicionarProdutoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _fardosController = TextEditingController(text: '0');
  final _avulsasController = TextEditingController(text: '0');

  late AnimationController _headerController;
  late AnimationController _cardController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardScale;

  String? _categoriaSelecionada;
  int _fardos = 0;
  int _avulsas = 0;

  List<Map<String, dynamic>> _categorias = [];
  bool _carregando = true;
  bool _salvando = false;

  // === NOVA PALETA: PRETO + BRANCO + LARANJA NEON (FIRE MODE) ===
  static const Color pureBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color brightOrange = Color(0xFFFF4500);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color softOrange = Color(0xFFFF8C42);
  static const Color pureWhite = Color(0xFFFFFFFF);
  // static const Color offWhite = Color(0xFFF5F5F5); 
  static const Color grayText = Color(0xFFAAAAAA);
  static const Color borderGray = Color(0xFF333333);

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.elasticOut));

    _cardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _headerController.forward();
    _cardController.forward();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    try {
      final lista = await ApiService.getCategorias();
      setState(() {
        _categorias = lista;
        _carregando = false;
      });
      if (_categorias.isNotEmpty && _categoriaSelecionada == null) {
        setState(() => _categoriaSelecionada = _categorias.first['name'] as String);
      }
    } catch (e) {
      setState(() => _carregando = false);
      _mostrarSnackBar('Erro ao carregar categorias', isError: true);
    }
  }

  void _mostrarSnackBar(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: pureWhite,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? brightOrange : neonOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (_categoriaSelecionada == null || _categoriaSelecionada!.isEmpty) {
      _mostrarSnackBar('Selecione uma categoria', isError: true);
      HapticFeedback.mediumImpact();
      return;
    }

    _fardos = int.tryParse(_fardosController.text) ?? 0;
    _avulsas = int.tryParse(_avulsasController.text) ?? 0;

    setState(() => _salvando = true);
    HapticFeedback.heavyImpact();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/add_produto.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nome': _nomeController.text.trim(),
          'categoria': _categoriaSelecionada,
          'fardos': _fardos,
          'avulsas': _avulsas,
          'gerente_id': ApiService.conferenteId,
        }),
      );

      final jsonResposta = json.decode(response.body);

      if (response.statusCode == 200 && jsonResposta['success'] == true) {
        HapticFeedback.heavyImpact();
        _mostrarSnackBar('Produto adicionado com sucesso!');
        await Future.delayed(const Duration(milliseconds: 1200));

        if (mounted) {
          widget.onMainItemChanged('Estoque Geral');
        }
      } else {
        throw Exception(jsonResposta['error'] ?? 'Falha ao salvar');
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', isError: true);
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureBlack,
      body: SafeArea(
        // Removido o Column e colocado o SingleChildScrollView diretamente
        // para que o header role junto.
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24), // Padding ajustado
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // === NOVO LOCAL DO HEADER ===
                const SizedBox(height: 16), // Espaçamento do topo
                _buildGlassHeader(),
                const SizedBox(height: 24), // Espaçamento após o header
                
                ScaleTransition(
                  scale: _cardScale,
                  child: _buildWelcomeCard(),
                ),
                const SizedBox(height: 24),
                _buildAnimatedFormCard(),
                const SizedBox(height: 24),
                _buildQuantitySection(),
                const SizedBox(height: 32),
                _buildNeonButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        // Container antigo tinha um margin de 20. 
        // Eu removi o margin e mantive o padding horizontal no SingleChildScrollView.
        // O padding vertical está aqui agora.
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brightOrange.withOpacity(0.3), // REDUZIDO O BRILHO
                neonOrange.withOpacity(0.15), // REDUZIDO O BRILHO
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: brightOrange.withOpacity(0.3), width: 2), // REDUZIDO
            boxShadow: [
              BoxShadow(
                color: brightOrange.withOpacity(0.3), // REDUZIDO O BRILHO
                blurRadius: 20, // REDUZIDO O BLUR
                offset: const Offset(0, 10), // AJUSTADO O OFFSET
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [brightOrange, neonOrange]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: brightOrange.withOpacity(0.5), // REDUZIDO O BRILHO
                      blurRadius: 15, // REDUZIDO O BLUR
                      offset: const Offset(0, 6), // AJUSTADO O OFFSET
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: pureWhite, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo Produto',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: pureWhite,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure e adicione ao estoque',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: grayText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (o resto do código _buildWelcomeCard, _buildAnimatedFormCard, etc., permanece o mesmo)

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brightOrange.withOpacity(0.15),
            neonOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brightOrange.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: brightOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.info_rounded, color: brightOrange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Preencha os campos abaixo para adicionar um novo produto ao seu inventário',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: grayText,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informações Básicas', Icons.inventory_2_rounded),
          const SizedBox(height: 24),
          _buildNeumorphicField(
            controller: _nomeController,
            label: 'Nome do Produto',
            hint: 'Ex: Skol Lata 350ml',
            icon: Icons.shopping_bag_rounded,
          ),
          const SizedBox(height: 20),
          _buildNeumorphicDropdown(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [brightOrange, neonOrange]),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Icon(icon, color: pureWhite, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pureWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildNeumorphicField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: grayText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: deepBlack,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderGray, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: pureWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: grayText.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: brightOrange, size: 22),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: brightOrange, width: 2.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: brightOrange, width: 2),
              ),
            ),
            validator: (v) => v?.trim().isEmpty ?? true ? 'Campo obrigatório' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNeumorphicDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: grayText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: deepBlack,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderGray, width: 1),
          ),
          child: DropdownButtonFormField<String>(
            value: _categoriaSelecionada,
            isExpanded: true,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: pureWhite,
            ),
            dropdownColor: cardBlack,
            icon: Icon(Icons.arrow_drop_down_circle_rounded, color: brightOrange, size: 26),
            decoration: InputDecoration(
              hintText: _carregando ? 'Carregando...' : 'Selecione',
              hintStyle: GoogleFonts.poppins(
                color: grayText.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(Icons.category_rounded, color: brightOrange, size: 22),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
            ),
            items: _categorias
                .map((cat) => DropdownMenuItem<String>(
                      value: cat['name'] as String,
                      child: Text(cat['name'] as String),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _categoriaSelecionada = value),
            validator: (v) => v == null || v.isEmpty ? 'Selecione uma categoria' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader('Quantidade', Icons.analytics_rounded),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildGlowingQuantityCard(
                  label: 'Fardos',
                  controller: _fardosController,
                  icon: Icons.apps_rounded,
                  gradient: [brightOrange, neonOrange],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlowingQuantityCard(
                  label: 'Unidades',
                  controller: _avulsasController,
                  icon: Icons.shopping_basket_rounded,
                  gradient: [neonOrange, softOrange],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingQuantityCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gradient[0].withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient.map((c) => c.withOpacity(0.25)).toList()),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: gradient[0], size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: gradient[0],
                height: 1,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: GoogleFonts.poppins(
                  color: gradient[0].withOpacity(0.2),
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              validator: (v) {
                final val = int.tryParse(v ?? '0');
                if (val == null || val < 0) return 'Inválido';
                return null;
              },
              onChanged: (v) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 68,
      decoration: BoxDecoration(
        gradient: _salvando
            ? null
            : const LinearGradient(colors: [brightOrange, neonOrange]),
        color: _salvando ? cardBlack : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _salvando
            ? null
            : [
                BoxShadow(color: brightOrange.withOpacity(0.9), blurRadius: 40, spreadRadius: 2),
                BoxShadow(color: neonOrange.withOpacity(0.7), blurRadius: 60, offset: const Offset(0, 20)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _salvando ? null : _salvar,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: _salvando
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: grayText),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Processando...',
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: grayText),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: pureWhite, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Adicionar Produto',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: pureWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _fardosController.dispose();
    _avulsasController.dispose();
    _headerController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}