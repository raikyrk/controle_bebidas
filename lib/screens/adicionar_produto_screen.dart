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
  // === CONTROLADORES ===
  final _nomeController = TextEditingController();
  final _fardosController = TextEditingController(text: '0');
  final _avulsasController = TextEditingController(text: '0');
  
  // Controlador da Página (Wizard)
  late PageController _pageController;

  // === ANIMAÇÕES ===
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // === ESTADO ===
  String? _categoriaSelecionada;
  List<Map<String, dynamic>> _categorias = [];
  
  bool _carregando = true;
  bool _salvando = false;
  int _currentStep = 0; // 0: Nome, 1: Categoria, 2: Qtd, 3: Resumo

  // === PALETA FIRE MODE ===
  static const Color pureBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color brightOrange = Color(0xFFFF4500);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color softOrange = Color(0xFFFF8C42);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color grayText = Color(0xFFAAAAAA);
  static const Color borderGray = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.elasticOut));

    _headerController.forward();
    _carregarCategorias();
  }

  // ... (Métodos de API e SnackBar mantidos iguais) ...
  Future<void> _carregarCategorias() async {
    try {
      final lista = await ApiService.getCategorias();
      setState(() {
        _categorias = lista;
        _carregando = false;
      });
      // Não seleciona auto aqui para obrigar o user a escolher, ou selecione se preferir
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

  // === LÓGICA DE NAVEGAÇÃO DO WIZARD ===
  void _avancarPasso() {
    HapticFeedback.lightImpact();
    
    // Validação Passo 0: Nome
    if (_currentStep == 0) {
      if (_nomeController.text.trim().isEmpty) {
        _mostrarSnackBar('Por favor, digite o nome do produto', isError: true);
        HapticFeedback.mediumImpact();
        return;
      }
    }

    // Validação Passo 1: Categoria
    if (_currentStep == 1) {
      if (_categoriaSelecionada == null) {
        _mostrarSnackBar('Selecione uma categoria para continuar', isError: true);
        HapticFeedback.mediumImpact();
        return;
      }
    }

    // Se chegou no último passo (Resumo), salva. Se não, avança página.
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuad,
      );
    } else {
      _salvar();
    }
  }

  void _voltarPasso() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuad,
      );
    }
  }

  Future<void> _salvar() async {
    // Validação final de segurança
    if (_nomeController.text.isEmpty || _categoriaSelecionada == null) return;

    final fardos = int.tryParse(_fardosController.text) ?? 0;
    final avulsas = int.tryParse(_avulsasController.text) ?? 0;

    setState(() => _salvando = true);
    HapticFeedback.heavyImpact();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/add_produto.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nome': _nomeController.text.trim(),
          'categoria': _categoriaSelecionada,
          'fardos': fardos,
          'avulsas': avulsas,
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
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSmallHeader(), // Header reduzido e fixo
            const SizedBox(height: 20),
            _buildProgressIndicator(), // Bolinhas indicando o passo
            const SizedBox(height: 20),
            
            // AQUI É ONDE A MÁGICA ACONTECE: PAGEVIEW
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Bloqueia arrastar manual
                children: [
                  _buildStepContent(
                    title: 'Qual o nome do Produto',
                    subtitle: 'Digite o nome do produto como aparece na nota.',
                    content: _buildNeumorphicField(
                      controller: _nomeController,
                      label: 'Nome do Produto',
                      hint: 'Ex: Skol Lata 350ml',
                      icon: Icons.edit_note_rounded,
                      autoFocus: true,
                    ),
                  ),
                  _buildStepContent(
                    title: 'Qual a categoria?',
                    subtitle: 'Selecione onde esse produto se encaixa.',
                    content: _buildNeumorphicDropdown(),
                  ),
                  _buildStepContent(
                    title: 'Quantidade inicial?',
                    subtitle: 'Quantos itens você tem agora? (Opcional)',
                    content: _buildQuantitySection(),
                  ),
                  _buildStepContent(
                    title: 'Tudo certo?',
                    subtitle: 'Confira os dados antes de salvar.',
                    content: _buildSummaryCard(),
                  ),
                ],
              ),
            ),
            
            // BOTÕES DE AÇÃO NO RODAPÉ
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildActionBtn(),
                  if (_currentStep > 0) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _salvando ? null : _voltarPasso,
                      child: Text(
                        'Voltar',
                        style: GoogleFonts.poppins(
                          color: grayText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === WIDGETS AUXILIARES DO WIZARD ===

  Widget _buildSmallHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch_rounded, color: brightOrange, size: 24),
              const SizedBox(width: 10),
              Text(
                'Novo Produto',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: pureWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 6,
          width: isActive ? 24 : 6,
          decoration: BoxDecoration(
            color: isActive ? brightOrange : borderGray,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(color: brightOrange.withOpacity(0.4), blurRadius: 8)]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: pureWhite,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: grayText,
            ),
          ),
          const SizedBox(height: 40),
          content,
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Nome', _nomeController.text),
          const Divider(color: Color.fromARGB(255, 255, 255, 255), height: 32),
          _buildSummaryRow('Categoria', _categoriaSelecionada ?? 'Não selecionado'),
          const Divider(color: Color.fromARGB(255, 255, 255, 255), height: 32),
          _buildSummaryRow('Fardos', _fardosController.text),
          const SizedBox(height: 12),
          _buildSummaryRow('Avulsas', _avulsasController.text),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: grayText, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: pureWhite,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn() {
    String label = _currentStep == 3 ? 'Finalizar e Salvar' : 'Avançar';
    IconData icon = _currentStep == 3 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 64,
      decoration: BoxDecoration(
        gradient: _salvando
            ? null
            : const LinearGradient(colors: [brightOrange, neonOrange]),
        color: _salvando ? cardBlack : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _salvando
            ? null
            : [
                BoxShadow(color: brightOrange.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _salvando ? null : _avancarPasso,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: _salvando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: grayText),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: pureWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, color: pureWhite),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // === REUTILIZAÇÃO DOS SEUS WIDGETS ANTIGOS ===
  // Mantive a lógica visual idêntica, apenas ajustada para contexto

  Widget _buildNeumorphicField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool autoFocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: deepBlack,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        autofocus: autoFocus,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: pureWhite,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: grayText.withOpacity(0.5), fontSize: 16),
          prefixIcon: Icon(icon, color: brightOrange, size: 22),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: brightOrange, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicDropdown() {
  return Container(
    height: 64,
    decoration: BoxDecoration(
      color: deepBlack,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderGray, width: 1),
    ),
    child: DropdownButtonHideUnderline(
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButton<String>(
          value: _categoriaSelecionada,
          isExpanded: true,
          dropdownColor: cardBlack,
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_drop_down_circle_rounded, color: brightOrange, size: 26),
          ),
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _carregando ? 'Carregando...' : 'Selecione a categoria',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: pureWhite.withOpacity(0.85),
              ),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: pureWhite,
          ),
          items: _categorias.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['name'],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  cat['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: pureWhite,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _categoriaSelecionada = value),
        ),
      ),
    ),
  );
}

  Widget _buildQuantitySection() {
    return Column(
      children: [
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
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient.map((c) => c.withOpacity(0.25)).toList()),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: gradient[0], size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: pureWhite,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: gradient[0],
                height: 5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: GoogleFonts.poppins(
                  color: gradient[0].withOpacity(0.2),
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _fardosController.dispose();
    _avulsasController.dispose();
    _headerController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}