import 'dart:convert';
import 'package:http/http.dart' as http;
import 'produto.dart';

class ApiService {
  static const String baseUrl = 'https://aogosto.store/estoquebebidas/api/index.php';
  
  // 1. BUSCAR ESTOQUE
  static Future<List<Produto>> getEstoque() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?endpoint=get_estoque'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Produto.fromJson(data)).toList();
      } else {
        throw Exception('Erro ao carregar estoque');
      }
    } catch (e) {
      throw Exception('Falha na conexão: $e');
    }
  }

  // 2. SOLICITAÇÃO INDIVIDUAL (Legado/Unitário)
  static Future<void> solicitarRetirada(
    String produtoNome, {
    int fardos = 0, 
    int unidades = 0, 
    String? loja
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=solicitar_retirada'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'produto_nome': produtoNome,
          'fardos': fardos,
          'unidades': unidades,
          'loja': loja,
        }),
      );

      final result = json.decode(response.body);
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      throw Exception('Erro ao enviar solicitação: $e');
    }
  }

  // 3. NOVA FUNÇÃO: ENVIAR PEDIDO AGRUPADO (CARRINHO)
  // Essa é a função que estava faltando!
  static Future<void> enviarPedidoAgrupado(String loja, List<Map<String, dynamic>> itens) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=solicitar_retirada_agrupada'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'loja': loja,
          'itens': itens,
        }),
      );

      final result = json.decode(response.body);
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      throw Exception('Erro ao enviar lista para $loja: $e');
    }
  }
}