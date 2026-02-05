import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart'; // Importante!

void main() {
  runApp(const MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image;
  final _picker = ImagePicker();
  
  // Variáveis para guardar o resultado da IA
  String _resultado = "Tire uma foto para analisar";
  String _confianca = "";
  bool _loading = false; // Para mostrar um "carregando..."

  @override
  void initState() {
    super.initState();
    _carregarModelo(); // Carrega o cérebro da IA ao iniciar o app
  }

  // 1. Função para carregar o modelo TFLite
  Future<void> _carregarModelo() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/modelo_soja.tflite",
        labels: "assets/labels.txt",
        numThreads: 1, // Usa 1 núcleo do processador
        isAsset: true,
        useGpuDelegate: false,
      );
      print("Modelo carregado: $res");
    } catch (e) {
      print("Erro ao carregar modelo: $e");
    }
  }

  // 2. Função para passar a foto para a IA
  Future<void> _classificarImagem(File image) async {
    setState(() {
      _loading = true;
    });

    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2, // Quantos resultados queremos (top 2)
      threshold: 0.5, // Só mostra se tiver mais de 50% de certeza
      imageMean: 127.5, // Padrão para normalizar cores
      imageStd: 127.5,
    );

    setState(() {
      _loading = false;
      if (output != null && output.isNotEmpty) {
        // O output vem assim: [{'label': 'Ferrugem', 'confidence': 0.95}]
        String label = output[0]['label'];
        // Remove números do label se houver (ex: "0 Ferrugem" vira "Ferrugem")
        label = label.replaceAll(RegExp(r'[0-9]'), '').trim(); 
        
        double confidence = (output[0]['confidence'] * 100);
        
        _resultado = label; 
        _confianca = "${confidence.toStringAsFixed(1)}% de certeza";
      } else {
        _resultado = "Não consegui identificar.";
        _confianca = "";
      }
    });
  }

  // 3. Função de tirar foto (igual a antes, mas chama a IA no final)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        File imagemTemporaria = File(pickedFile.path);
        setState(() {
          _image = imagemTemporaria;
        });
        // AQUI É A MÁGICA: Chama a IA para ler a foto nova
        _classificarImagem(imagemTemporaria);
      }
    } catch (e) {
      print("Erro ao pegar imagem: $e");
    }
  }

  @override
  void dispose() {
    Tflite.close(); // Libera a memória quando fechar o app
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Ferrugem AGdata'),
        backgroundColor: const Color(0xFF2E7D32), // Verde soja
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                      image: FileImage(_image!), fit: BoxFit.cover),
                ),
              )
            else
              Image.asset(
                'assets/logo.png', // Se não tiver logo, ele mostra erro, pode comentar essa linha
                height: 150,
                errorBuilder: (c, o, s) => const Icon(Icons.eco, size: 100, color: Colors.green),
              ),
            
            const SizedBox(height: 20),
            
            // Exibição do Resultado
            _loading 
              ? const CircularProgressIndicator() 
              : Column(
                  children: [
                    Text(
                      _resultado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _resultado.contains("Saudável") ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      _confianca,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),

            const SizedBox(height: 40),
            
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('Galeria'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}