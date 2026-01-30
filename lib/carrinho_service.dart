import 'package:flutter/material.dart';
import 'dart:convert'; // Necessário para converter em JSON
import 'package:shared_preferences/shared_preferences.dart';

class ItemCarrinho {
  final String loja;
  final String produtoNome;
  int fardos;
  int unidades;

  ItemCarrinho({
    required this.loja,
    required this.produtoNome,
    required this.fardos,
    required this.unidades,
  });

  // CONVERTE PARA TEXTO (JSON) PARA SALVAR NO CELULAR
  Map<String, dynamic> toJson() {
    return {
      'loja': loja,
      'produto': produtoNome, // Mantendo a correção que fizemos!
      'fardos': fardos,
      'unidades': unidades,
    };
  }

  // CONVERTE DE VOLTA DO TEXTO PARA OBJETO QUANDO O APP ABRE
  factory ItemCarrinho.fromJson(Map<String, dynamic> json) {
    return ItemCarrinho(
      loja: json['loja'],
      produtoNome: json['produto'], // Lê a chave 'produto'
      fardos: json['fardos'],
      unidades: json['unidades'],
    );
  }
}

class CarrinhoService extends ChangeNotifier {
  static final CarrinhoService _instance = CarrinhoService._internal();
  factory CarrinhoService() => _instance;
  
  // No construtor, a gente já manda carregar os dados salvos
  CarrinhoService._internal() {
    _carregarDoCelular();
  }

  List<ItemCarrinho> _itens = [];

  List<ItemCarrinho> get itens => _itens;

  // === PERSISTÊNCIA (A "MÁGICA" DE SALVAR) ===

  Future<void> _salvarNoCelular() async {
    final prefs = await SharedPreferences.getInstance();
    // Transforma a lista de objetos em uma lista de textos (Strings JSON)
    List<String> listaJson = _itens.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList('carrinho_v1', listaJson);
  }

  Future<void> _carregarDoCelular() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? listaJson = prefs.getStringList('carrinho_v1');
    
    if (listaJson != null) {
      // Transforma os textos de volta em objetos
      _itens = listaJson.map((s) => ItemCarrinho.fromJson(jsonDecode(s))).toList();
      notifyListeners(); // Avisa a tela para atualizar os números
    }
  }

  // === MÉTODOS DO CARRINHO ===

  void adicionarItem(String loja, String produto, int f, int u) {
    var existente = _itens.firstWhere(
      (i) => i.produtoNome == produto && i.loja == loja,
      orElse: () => ItemCarrinho(loja: '', produtoNome: '', fardos: 0, unidades: 0)
    );

    if (existente.loja.isNotEmpty) {
      existente.fardos += f;
      existente.unidades += u;
    } else {
      _itens.add(ItemCarrinho(
        loja: loja, 
        produtoNome: produto, 
        fardos: f, 
        unidades: u
      ));
    }
    
    _salvarNoCelular(); // <--- SALVA NO CELULAR
    notifyListeners();
  }

  void removerItem(int index) {
    _itens.removeAt(index);
    _salvarNoCelular(); // <--- SALVA A REMOÇÃO
    notifyListeners();
  }

  void limparTudo() {
    _itens.clear();
    _salvarNoCelular(); // <--- LIMPA A MEMÓRIA DO CELULAR TAMBÉM
    notifyListeners();
  }

  Map<String, List<ItemCarrinho>> agruparPorLoja() {
    Map<String, List<ItemCarrinho>> agrupado = {};
    for (var item in _itens) {
      if (!agrupado.containsKey(item.loja)) {
        agrupado[item.loja] = [];
      }
      agrupado[item.loja]!.add(item);
    }
    return agrupado;
  }

  int qtdFardosReservados(String nome) {
    return _itens
        .where((i) => i.produtoNome == nome)
        .fold(0, (prev, element) => prev + element.fardos);
  }

  int qtdUnidadesReservadas(String nome) {
    return _itens
        .where((i) => i.produtoNome == nome)
        .fold(0, (prev, element) => prev + element.unidades);
  }
}