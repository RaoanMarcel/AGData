import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/config_prescricao.dart';
import '../models/zona_prescricao.dart';

/// Gera um pacote ISO 11783-10 (ISOBUS Task Controller) para prescrição
/// variável de fungicida — compatível com John Deere e Jacto.
///
/// Formato gerado:
///   TaskData.xml  — estrutura da tarefa com elemento GRD (GridType 2)
///   GRD00001.bin  — grade binária: int32 little-endian por célula (L/ha × 100)
///   → Ambos empacotados em um .zip
class IsobusService {
  static Future<Uint8List> gerarZip({
    required GradePrescricao grade,
    required ConfigPrescricao config,
    required String talhaoNome,
    required String empresaNome,
  }) async {
    final xmlBytes = _gerarXml(grade, config, talhaoNome, empresaNome);
    final binBytes = _gerarBinario(grade);

    final archive = Archive();
    archive.addFile(ArchiveFile('TaskData.xml', xmlBytes.length, xmlBytes));
    archive.addFile(ArchiveFile('GRD00001.bin', binBytes.length, binBytes));

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(zipBytes ?? []);
  }

  // ── XML ─────────────────────────────────────────────────────────────────────

  static Uint8List _gerarXml(
    GradePrescricao grade,
    ConfigPrescricao config,
    String talhaoNome,
    String empresaNome,
  ) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('ISO11783_TaskData', attributes: {
      'VersionMajor': '4',
      'VersionMinor': '0',
      'ManagementSoftwareManufacturer': 'HectarIA',
      'ManagementSoftwareVersion': '1.0.0',
      'TaskControllerManufacturer': '',
      'TaskControllerVersion': '',
      'DataTransferOrigin': '1',
    }, nest: () {
      // Cliente / Empresa
      builder.element('CTR', attributes: {
        'A': 'CTR1',
        'B': empresaNome,
      });

      // Fazenda
      builder.element('FRM', attributes: {
        'A': 'FRM1',
        'B': empresaNome,
        'G': 'CTR1',
      });

      // Campo / Talhão
      final areaTotalM2 =
          (grade.nRows * grade.cellHeightDeg * 111000) *
          (grade.nCols * grade.cellWidthDeg * 111000);
      builder.element('PFD', attributes: {
        'A': 'PFD1',
        'B': talhaoNome,
        'C': 'PFD1',
        'D': '1',
        'E': areaTotalM2.toInt().toString(),
        'F': 'FRM1',
      });

      // Produto
      builder.element('PDT', attributes: {
        'A': 'PDT1',
        'B': config.nomeProduto,
        'C': '',
        'D': '',
      });

      // Tarefa com grade de prescrição
      builder.element('TSK', attributes: {
        'A': 'TSK1',
        'B': 'Prescricao ${config.nomeProduto} - $talhaoNome',
        'C': 'CTR1',
        'D': 'FRM1',
        'E': 'PFD1',
        'F': 'PDT1',
        'G': '1',
      }, nest: () {
        // GRD: Grade de prescrição (GridType 2 = valores diretos por célula)
        // A = latMin, B = lngMin, C = cellH, D = cellW,
        // E = nCols-1 (índice máximo coluna), F = nRows-1 (índice máximo linha),
        // G = nome do arquivo binário (sem extensão), H = GridType (2)
        builder.element('GRD', attributes: {
          'A': grade.minLat.toStringAsFixed(8),
          'B': grade.minLng.toStringAsFixed(8),
          'C': grade.cellHeightDeg.toStringAsFixed(8),
          'D': grade.cellWidthDeg.toStringAsFixed(8),
          'E': (grade.nCols - 1).toString(),
          'F': (grade.nRows - 1).toString(),
          'G': 'GRD00001',
          'H': '2',
        });
      });
    });

    final doc = builder.buildDocument();
    return Uint8List.fromList(
        doc.toXmlString(pretty: true).codeUnits);
  }

  // ── Binário ──────────────────────────────────────────────────────────────────

  /// Gera o arquivo binário GRD.
  ///
  /// Formato: int32 little-endian por célula.
  /// Ordem: linha por linha de N→S (row nRows-1 primeiro), W→E por coluna.
  /// Valor = taxa em L/ha × 100 (ex.: 2.5 L/ha → 250).
  static Uint8List _gerarBinario(GradePrescricao grade) {
    final total = grade.nRows * grade.nCols;
    final buffer = ByteData(total * 4);
    int offset = 0;

    // ISO 11783: linha 0 da grade = latMin (sul); binário começa pelo norte
    for (int row = grade.nRows - 1; row >= 0; row--) {
      for (int col = 0; col < grade.nCols; col++) {
        final zona = grade.celulas[row][col];
        final valor = (zona.taxa * 100).round(); // L/ha × 100
        buffer.setInt32(offset, valor, Endian.little);
        offset += 4;
      }
    }

    return buffer.buffer.asUint8List();
  }
}
