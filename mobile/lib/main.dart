import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'classifier.dart'; 

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image;
  final _picker = ImagePicker();
  
  // Instância do classificador
  final Classifier _classifier = Classifier();

  String _resultado = "Tire uma foto";
  String _confianca = "para analisar a soja";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  // --- LÓGICA DE CLASSIFICAÇÃO ---
  Future<void> _classificarImagem(File image) async {
    setState(() {
      _loading = true;
      _resultado = "Analisando...";
      _confianca = "";
    });

    // --- CORREÇÃO DO ERRO AQUI ---
    // Pegamos o resultado genérico primeiro
    var rawOutput = await _classifier.predict(image);
    
    // Convertemos explicitamente para lista de double
    List<double> output = List<double>.from(rawOutput);

    setState(() {
      _loading = false;

      if (output.isEmpty) {
        _resultado = "Erro na análise";
        return;
      }

      // --- SUA LISTA DE DOENÇAS ---
      // 0: ferrugem
      // 1: saudavel
      List<String> labels = ["Ferrugem", "Saudável"]; 

      double maiorValor = 0.0;
      int indexGanhador = -1;

      for (int i = 0; i < output.length; i++) {
        if (output[i] > maiorValor) {
          maiorValor = output[i];
          indexGanhador = i;
        }
      }

      if (indexGanhador != -1) {
        if (maiorValor < 0.6) {
             _resultado = "Inconclusivo";
             _confianca = "Tente melhorar a iluminação";
        } else {
             String nomeResultado = indexGanhador < labels.length 
                 ? labels[indexGanhador] 
                 : "Desconhecido";

             _resultado = nomeResultado.toUpperCase();
             _confianca = "${(maiorValor * 100).toStringAsFixed(1)}% de certeza";
        }
      } else {
        _resultado = "Não identificado";
      }
    });
  }

  // --- LÓGICA DA CÂMERA/GALERIA ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        File imagemTemporaria = File(pickedFile.path);
        
        setState(() {
          _image = imagemTemporaria;
        });
        
        _classificarImagem(imagemTemporaria);
      }
    } catch (e) {
      // O 'debugPrint' é preferível ao 'print' no Flutter, mas print funciona
      debugPrint("Erro ao pegar imagem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector AGdata'),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- PREVIEW DA IMAGEM ---
              if (_image != null)
                Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_image!), 
                      fit: BoxFit.cover
                    ),
                  ),
                )
              else
                Container(
                   height: 300,
                   width: 300,
                   decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey, width: 2),
                   ),
                   child: const Column( // Adicionado const aqui para otimização
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.add_a_photo, size: 60, color: Colors.grey),
                       SizedBox(height: 10),
                       Text("Sem imagem", style: TextStyle(color: Colors.grey))
                     ],
                   ),
                ),
              
              const SizedBox(height: 30),
              
              // --- RESULTADOS ---
              _loading 
                ? const CircularProgressIndicator(color: Colors.green)
                : Column(
                    children: [
                      Text(
                        _resultado,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _resultado == "SAUDÁVEL" ? Colors.green : (_resultado == "FERRUGEM" ? Colors.red : Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _confianca,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),

              const SizedBox(height: 40),
              
              // --- BOTÕES ---
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
      ),
    );
  }
}