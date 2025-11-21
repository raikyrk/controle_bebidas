// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'produto.dart';

class ApiService {
  // URL DO SERVIDOR
  static const String baseUrl = 'https://aogosto.store/estoquebebidas/api';
  static const Duration _timeout = Duration(seconds: 15);

  // DADOS DO CONFERENTE LOGADO
  static int? conferenteId;
  static String? conferenteNome;

  // CACHES
  static List<Map<String, dynamic>> _conferentesCache = [];
  static List<Map<String, dynamic>> _categoriasCache = [];

  // === ESTÁ LOGADO? ===
  static bool get estaLogado => conferenteId != null;

  // === CARREGAR CONFERENTE DO CACHE ===
  static Future<void> carregarConferenteCache() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('conferente_id');
    final nome = prefs.getString('conferente_nome');

    if (id != null && nome != null) {
      conferenteId = id;
      conferenteNome = nome;
    }
  }

  // === CARREGAR ESTOQUE ===
  static Future<List<Produto>> getEstoque() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_estoque.php'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Produto.fromJson(data)).toList();
      } else {
        throw Exception('Falha na conexão: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar estoque: $e');
      rethrow;
    }
  }

  // === ATUALIZAR QUANTIDADE ===
  static Future<void> updateQuantidade(int id, String tipo, int delta) async {
    if (conferenteId == null) throw Exception('Usuário não logado');
    if (!['f', 'a'].contains(tipo)) throw Exception('Tipo inválido: use "f" ou "a"');

    final payload = {
      'id': id,
      'tipo': tipo,
      'delta': delta,
      'conferente_id': conferenteId!,
      'origem': 'app'
    };

    print('ENVIANDO (APP): $payload'); // Debug

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_quantidade.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(_timeout);

      print('RESPOSTA: ${response.body}'); // Debug

      if (response.statusCode != 200) {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }

      final result = json.decode(response.body);
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      print('Erro ao salvar: $e');
      rethrow;
    }
  }

  // === CARREGAR CONFERENTES (COM CACHE) ===
  static Future<List<Map<String, dynamic>>> getConferentes() async {
    if (_conferentesCache.isNotEmpty) return _conferentesCache;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_conferentes.php'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        _conferentesCache = jsonResponse.map((e) => Map<String, dynamic>.from(e)).toList();
        return _conferentesCache;
      }
    } catch (e) {
      print('Erro ao carregar conferentes: $e');
      rethrow;
    }
    return [];
  }

  // === CARREGAR CATEGORIAS DO BANCO (PADRONIZA COM 'name') ===
  static Future<List<Map<String, dynamic>>> getCategorias() async {
    if (_categoriasCache.isNotEmpty) return _categoriasCache;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_categorias.php'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        _categoriasCache = jsonResponse
            .map((e) => {'name': e['nome'] as String})
            .toList();
        return _categoriasCache;
      }
    } catch (e) {
      print('Erro ao carregar categorias: $e');
    }

    // MOCK DE SEGURANÇA
    final mock = [
      {'name': 'Refrigerante'},
      {'name': 'Cerveja Long Neck'},
      {'name': 'Cerveja 600ml'},
      {'name': 'Redbull'},
      {'name': 'Vinho'},
      {'name': 'Gin'},
      {'name': 'Whisky'},
      {'name': 'Gatorade'},
      {'name': 'Água Mineral'},
      {'name': 'Diversos'},
    ];
    _categoriasCache = mock;
    return mock;
  }

  // === SELECIONAR CONFERENTE ===
  static Future<void> selecionarConferente(int id, String nome) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/selecionar_conferente.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}),
      ).timeout(_timeout);

      if (response.statusCode != 200) throw Exception('Erro HTTP: ${response.statusCode}');

      // Atualiza localmente
      conferenteId = id;
      conferenteNome = nome;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('conferente_id', id);
      await prefs.setString('conferente_nome', nome);
    } catch (e) {
      print('Erro ao selecionar conferente: $e');
      rethrow;
    }
  }

  // === VERIFICAR LOGIN (LEGADO - opcional) ===
  static Future<bool> checkLogin() async {
    if (conferenteId != null && conferenteNome != null) return true;

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('conferente_id');
    final nome = prefs.getString('conferente_nome');

    if (id != null && nome != null) {
      conferenteId = id;
      conferenteNome = nome;
      return true;
    }
    return false;
  }

  // === LOGOUT ===
  static Future<void> logout() async {
    conferenteId = null;
    conferenteNome = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('conferente_id');
    await prefs.remove('conferente_nome');
    _conferentesCache.clear();
    _categoriasCache.clear();
  }

  // === EXPEDIR PARA LOJA (NOVA FUNÇÃO) ===
  static Future<void> expedirParaLoja(int lojaId, Map<int, Map<String, int>> carrinho) async {
  if (carrinho.isEmpty) throw Exception('Carrinho vazio');
  if (conferenteId == null) throw Exception('Conferente não logado');

  final itens = carrinho.entries.map((e) {
    return {
      'produto_id': e.key,
      'fardos': e.value['f'] ?? 0,
      'avulsas': e.value['a'] ?? 0,
    };
  }).toList();

  final payload = {
    'loja_id': lojaId,
    'conferente_id': conferenteId!,           // ← ESSA LINHA ESTAVA FALTANDO
    'conferente_nome': conferenteNome ?? '',  // ← OPCIONAL, mas recomendado
    'itens': itens,
    'origem': 'app'                           // ← bom ter também
  };

  print('ENVIANDO EXPEDIÇÃO → $payload');

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/expedir/expedir.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    ).timeout(_timeout);

    print('RESPOSTA DO SERVIDOR: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Erro de conexão: HTTP ${response.statusCode}');
    }

    final result = json.decode(response.body);
    if (!(result['success'] ?? false)) {
      throw Exception(result['error'] ?? 'Falha ao expedir');
    }
  } catch (e) {
    print('Erro na expedição: $e');
    rethrow;
  }
}}