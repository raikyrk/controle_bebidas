import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:seu_app/api_service.dart'; // Adicione a importação do ApiService real

class ProductList extends StatelessWidget {
  final String categoryName;

  const ProductList({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    // ⚠️ TODO: Implementar a lógica de carregamento de dados aqui
    // 1. Usar FutureBuilder/StreamBuilder para chamar ApiService.getProdutos(categoryName)
    // 2. Exibir CircularProgressIndicator enquanto carrega
    // 3. Exibir a lista de produtos (ListView.builder)

    return Center(
      // Placeholder temporário:
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 40, color: Color(0xFFFF6B35)),
          const SizedBox(height: 16),
          Text(
            'Conteúdo do Estoque para:',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            categoryName,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B35)),
        ],
      ),
    );
  }
}