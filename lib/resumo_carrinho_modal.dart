import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'carrinho_service.dart';
import 'api_service.dart';
import 'vitrine_screen_func.dart'; // Para usar o VitrineTheme

class ResumoCarrinhoModal extends StatefulWidget {
  const ResumoCarrinhoModal({super.key});

  @override
  State<ResumoCarrinhoModal> createState() => _ResumoCarrinhoModalState();
}

class _ResumoCarrinhoModalState extends State<ResumoCarrinhoModal> {
  bool enviando = false;

  // Substitua o método _enviarPedidos por este:

Future<void> _enviarPedidos() async {
    setState(() => enviando = true);
    final carrinho = CarrinhoService();
    
    // Pega a loja do primeiro item (já que agora só pode ter uma loja por vez)
    String lojaDestino = carrinho.itens.isNotEmpty ? carrinho.itens.first.loja : "Geral";

    // Prepara a lista JSON
    List<Map<String, dynamic>> itensJson = carrinho.itens.map((i) => i.toJson()).toList();

    try {
      // Usa a função de envio agrupado, mas passando a loja explicitamente no JSON se necessário
      // (O PHP já pega a loja de dentro dos itens, mas é bom garantir)
      await ApiService.enviarPedidoAgrupado(lojaDestino, itensJson);
      
      carrinho.limparTudo(); // Limpa o carrinho e a memória do celular
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Pedido enviado com sucesso!"), backgroundColor: Color(0xFF10B981))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Erro: $e"), backgroundColor: const Color(0xFFEF4444))
        );
      }
    } finally {
      if (mounted) setState(() => enviando = false);
    }
}

  @override
  Widget build(BuildContext context) {
    // Escuta o carrinho para atualizar a tela se remover item
    return AnimatedBuilder(
      animation: CarrinhoService(),
      builder: (context, _) {
        final itens = CarrinhoService().itens;

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text("Resumo do Pedido", 
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: VitrineTheme.textDark)),
              ),
              
              // Lista de Itens
              Expanded(
                child: itens.isEmpty 
                  ? Center(child: Text("Carrinho vazio", style: GoogleFonts.poppins(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: itens.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = itens[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(color: VitrineTheme.brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                             child: const Icon(Icons.store, color: VitrineTheme.brandOrange),
                          ),
                          title: Text(item.loja, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            "${item.produtoNome}\n${item.fardos} Fardos + ${item.unidades} Unidades",
                            style: GoogleFonts.poppins(color: VitrineTheme.textMedium),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => CarrinhoService().removerItem(index),
                          ),
                        );
                      },
                    ),
              ),

              // Botão Enviar
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (itens.isEmpty || enviando) ? null : _enviarPedidos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VitrineTheme.brandOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: enviando 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("CONFIRMAR ENVIO (${itens.length})", 
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}