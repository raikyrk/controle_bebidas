class Produto {
  final int id;
  final String nome;
  final String categoria;
  int fardos;
  int avulsas;
  final String? ultimaAlteracao;
  final String? conferenteNome;

  Produto({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.fardos,
    required this.avulsas,
    this.ultimaAlteracao,
    this.conferenteNome,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      categoria: json['categoria'],
      fardos: int.parse(json['fardos'].toString()),
      avulsas: int.parse(json['avulsas'].toString()),
      ultimaAlteracao: json['ultima_alteracao'],
      conferenteNome: json['conferente_nome'],
    );
  }
}