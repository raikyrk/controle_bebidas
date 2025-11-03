import 'dart:convert';
import 'package:http/http.dart' as http;
import 'produto.dart';

class ApiService {
  // MUDE AQUI PARA SEU DOMÍNIO (ou use um servidor local para teste)
  static const String baseUrl = 'http://192.168.1.100/estoque/api'; // EXEMPLO LOCAL
  // OU: 'https://seusite.com/estoque/api'

  static Future<List<Produto>> getEstoque() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_estoque.php'));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Produto.fromJson(data)).toList();
      } else {
        throw Exception('Erro ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sem conexão: $e');
    }
  }

  static Future<void> updateQuantidade(int id, String tipo, int delta) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_quantidade.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'tipo': tipo, 'valor': delta}),
      );

      final result = json.decode(response.body);
      if (response.statusCode != 200 || result['success'] != true) {
        throw Exception(result['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      throw Exception('Falha ao salvar: $e');
    }
  }
}