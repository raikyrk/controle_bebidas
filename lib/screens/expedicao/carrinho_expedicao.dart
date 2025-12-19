// lib/expedicao/carrinho_expedicao.dart
import 'package:flutter/foundation.dart'; // Import necessário para ValueNotifier

class CarrinhoExpedicao {
  static final Map<int, Map<String, int>> _itens = {};

  // 🔥 NOVO: Um "dedo-duro" que avisa a tela quando o total muda
  static final ValueNotifier<int> totalNotifier = ValueNotifier(0);

  static Map<int, Map<String, int>> get itens => Map.unmodifiable(_itens);

  static int get totalItens => _itens.values.fold(0, (sum, item) => sum + (item['f'] ?? 0) + (item['a'] ?? 0));

  static void adicionar(int produtoId, String tipo) {
    _itens.putIfAbsent(produtoId, () => {'f': 0, 'a': 0});
    if (tipo == 'f') {
      _itens[produtoId]!['f'] = (_itens[produtoId]!['f'] ?? 0) + 1;
    } else {
      _itens[produtoId]!['a'] = (_itens[produtoId]!['a'] ?? 0) + 1;
    }
    _atualizarNotificacao(); // 🔥
  }

  static void removerOuDiminuir(int produtoId, String tipo) {
    if (!_itens.containsKey(produtoId)) return;

    final mapa = _itens[produtoId]!;
    if (tipo == 'f') {
      mapa['f'] = (mapa['f'] ?? 0) - 1;
    } else {
      mapa['a'] = (mapa['a'] ?? 0) - 1;
    }

    if ((mapa['f'] ?? 0) <= 0 && (mapa['a'] ?? 0) <= 0) {
      _itens.remove(produtoId);
    }
    _atualizarNotificacao(); // 🔥
  }

  static void limpar() {
    _itens.clear();
    _atualizarNotificacao(); // 🔥
  }

  static void _atualizarNotificacao() {
    totalNotifier.value = totalItens;
  }

  static Map<int, Map<String, int>> get carrinhoParaEnvio => Map.from(_itens);
}