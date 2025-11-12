// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<Map<String, dynamic>> conferentes = [];
  int? selectedId;
  bool isLoading = true;
  String? error;

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color lightOrange = Color(0xFFFF8555);

  @override
  void initState() {
    super.initState();
    _carregarConferentes();
  }

  Future<void> _carregarConferentes() async {
    setState(() => isLoading = true);
    try {
      final lista = await ApiService.getConferentes();
      setState(() {
        conferentes = lista;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Erro ao carregar conferentes';
        isLoading = false;
      });
    }
  }

  Future<void> _fazerLogin() async {
    if (selectedId == null) return;

    final conferente = conferentes.firstWhere((c) => c['id'] == selectedId);
    await ApiService.selecionarConferente(selectedId!, conferente['nome']);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryOrange, lightOrange]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inventory_2_rounded, size: 48, color: Colors.white),
              ),
              SizedBox(height: 24),

              Text('Ao Gosto', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
              SizedBox(height: 8),
              Text('Selecione o conferente para continuar', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
              SizedBox(height: 32),

              // Dropdown
              if (isLoading)
                CircularProgressIndicator(color: primaryOrange)
              else if (error != null)
                Text(error!, style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<int>(
                  value: selectedId,
                  decoration: InputDecoration(
                    labelText: 'Conferente',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.person_rounded, color: primaryOrange),
                  ),
                  items: conferentes
                      .map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nome'])))
                      .toList(),
                  onChanged: (id) => setState(() => selectedId = id),
                ),

              SizedBox(height: 24),

              // Botão Entrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedId == null ? null : _fazerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}