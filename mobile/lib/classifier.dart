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

    img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    
    var input = [
      List.generate(224, (y) {
        return List.generate(224, (x) {
          var pixel = resizedImage.getPixel(x, y);
          // Extrai RGB
          var r = pixel.r;
          var g = pixel.g;
          var b = pixel.b;
          
        return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];        });
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