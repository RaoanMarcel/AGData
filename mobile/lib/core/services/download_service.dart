import 'dart:io';
import 'package:flutter/services.dart';

/// Salva arquivos na pasta Downloads do Android via MediaStore (API 29+) ou
/// escrita direta (API 28-). Retorna o caminho/descrição ou null em caso de erro.
class DownloadService {
  static const _channel = MethodChannel('com.agdata.mobile/downloader');

  static Future<String?> saveToDownloads({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('saveToDownloads', {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': mimeType,
      });
    } catch (_) {
      // MissingPluginException, PlatformException ou qualquer falha nativa
      return null;
    }
  }
}
