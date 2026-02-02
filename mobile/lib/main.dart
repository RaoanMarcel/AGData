import 'dart:io'; // Necessário para lidar com arquivos
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // A biblioteca que instalamos

void main() {
  runApp(const AppTCC());
}

class AppTCC extends StatelessWidget {
  const AppTCC({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agro TCC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  File? _imagem; // Variável para guardar a foto na memória

  // Função que acessa a câmera/galeria
  Future<void> _pegarImagem(ImageSource origem) async {
    final picker = ImagePicker();
    // Aqui a mágica acontece: abre a câmera ou galeria
    final pickedFile = await picker.pickImage(source: origem);

    if (pickedFile != null) {
      setState(() {
        // Atualiza a tela mostrando a foto que o usuário tirou
        _imagem = File(pickedFile.path);
      });
    }
  }

  // Mostra um menu para escolher entre Câmera ou Galeria
  void _mostrarOpcoes() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                _pegarImagem(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pegarImagem(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Detecção de Doenças"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lógica visual: Se tem imagem, mostra a foto. Se não, mostra o ícone.
            _imagem != null
                ? Image.file(
                    _imagem!,
                    height: 300,
                    width: 300,
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.agriculture,
                    size: 100,
                    color: Colors.green,
                  ),
            const SizedBox(height: 20),
            Text(
              _imagem != null ? 'Imagem Carregada!' : 'Nenhuma imagem selecionada',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _mostrarOpcoes, // Chama o menu de opções
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Analisar Folha"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}