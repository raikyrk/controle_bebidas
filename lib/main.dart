// main.dart
import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'login_screen.dart';
import 'api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.carregarConferenteCache(); // Carrega do cache
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final logado = await ApiService.checkLogin(); // Usa o método async
    setState(() {
      _isLoggedIn = logado;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
        ),
      );
    }

    return MaterialApp(
      title: 'Ao Gosto - Estoque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: _isLoggedIn ? const Sidebar() : const LoginWrapper(),
    );
  }
}

class LoginWrapper extends StatelessWidget {
  const LoginWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onLoginSuccess: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Sidebar()),
        );
      },
    );
  }
}