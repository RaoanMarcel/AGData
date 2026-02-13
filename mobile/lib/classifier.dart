import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img; // Biblioteca para tratar a imagem
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  // Variável para guardar o interpretador (o cérebro da IA)
  Interpreter? _interpreter;

  // Carrega o modelo da memória
  Future<void> loadModel() async {
    try {
      // Cria o interpretador a partir do arquivo na pasta assets
      _interpreter = await Interpreter.fromAsset('assets/modelo_soja.tflite');
      print('Modelo carregado com sucesso!');
      
      // Imprime o formato de entrada para conferência (ajuda a debugar)
      var inputShape = _interpreter!.getInputTensor(0).shape;
      print("Formato esperado pela IA: $inputShape");
      
    } catch (e) {
      print('Erro ao carregar o modelo: $e');
    }
  }

  // Função principal que faz a previsão
  Future<List<double>> predict(File imageFile) async {
    if (_interpreter == null) {
      print("Interpretador não inicializado");
      return [];
    }

    // 1. Ler a imagem do arquivo
    var imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) return [];

    // 2. Redimensionar para 224x224 (Padrão do Teachable Machine)
    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    // 3. Converter a imagem para uma matriz de números (Float32)
    // O Teachable Machine geralmente exporta como Float32 [1, 224, 224, 3]
    // Precisamos normalizar os pixels de 0 a 255 para 0.0 a 1.0 (ou manter 0-255 dependendo do modelo)
    // OBS: Modelos padrão do Teachable Machine (sem quantização) usam Float32 normalizado (0 a 1).
    
    var input = [
      List.generate(224, (y) {
        return List.generate(224, (x) {
          var pixel = resizedImage.getPixel(x, y);
          // Extrai RGB
          var r = pixel.r;
          var g = pixel.g;
          var b = pixel.b;
          
          // Normalização padrão (x / 255.0) para modelos Float
          return [r / 255.0, g / 255.0, b / 255.0]; 
        });
      })
    ];

    // 4. Preparar o array de saída
    // Supondo 2 classes (Ferrugem, Saudavel), o output será [1, 2]
    var outputBuffer = List.filled(1 * 2, 0.0).reshape([1, 2]);

    _interpreter!.run(input, outputBuffer);

    List<double> result = List<double>.from(outputBuffer[0]);
    
    return result;
  }
}