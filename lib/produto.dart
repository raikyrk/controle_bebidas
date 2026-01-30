class Produto {
  final int id;
  final String nome;
  final String categoria;
  final int fardos;
  final int avulsas;

  Produto({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.fardos,
    required this.avulsas,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      categoria: json['categoria'] ?? 'Geral',
      // Garante que venha como int mesmo se a API mandar string
      fardos: int.tryParse(json['fardos'].toString()) ?? 0,
      avulsas: int.tryParse(json['avulsas'].toString()) ?? 0,
    );
  }
}