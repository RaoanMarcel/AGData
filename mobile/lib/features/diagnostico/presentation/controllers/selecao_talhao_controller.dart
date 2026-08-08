import 'package:flutter/material.dart';
import '../../data/datasources/database_service.dart';
import '../../data/models/talhao_model.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/controller/session_controller.dart';

class SelecaoTalhaoController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final SessionController _session = sl<SessionController>();

  List<TalhaoModel> talhoes = [];
  String? talhaoSelecionado;
  bool loading = true;

  Map<String, DateTime> ultimaLeitura = {};
  Map<String, int> totalLeituras = {};

  SelecaoTalhaoController() {
    _carregarTalhoes();
  }

  Future<void> _carregarTalhoes() async {
    loading = true;
    notifyListeners();

    final String? companyId = _session.usuario?.companyId;

    if (companyId != null) {
      talhoes = await _databaseService.buscarTalhoesPorEmpresa(companyId);
    } else {
      talhoes = [];
    }

    if (talhaoSelecionado == null && talhoes.isNotEmpty) {
      talhaoSelecionado = talhoes.first.nome;
    }

    final leituras = await _databaseService.buscarTodasLeituras();
    final nomesTodo = talhoes.map((t) => t.nome).toSet();

    ultimaLeitura = {};
    totalLeituras = {};
    for (final l in leituras) {
      if (!nomesTodo.contains(l.talhao)) continue;
      totalLeituras[l.talhao] = (totalLeituras[l.talhao] ?? 0) + 1;
      final atual = ultimaLeitura[l.talhao];
      if (atual == null || l.dataHora.isAfter(atual)) {
        ultimaLeitura[l.talhao] = l.dataHora;
      }
    }

    loading = false;
    notifyListeners();
  }

  Future<void> recarregar() => _carregarTalhoes();

  void selecionarTalhao(String nome) {
    talhaoSelecionado = nome;
    notifyListeners();
  }

  Future<void> salvarTalhao(String nome) async {
    final String? companyId = _session.usuario?.companyId;

    if (companyId != null) {
      final novoTalhao = TalhaoModel()
        ..nome = nome
        ..companyId = companyId;

      await _databaseService.guardarTalhao(novoTalhao);
      await _carregarTalhoes();
    }
  }
}
