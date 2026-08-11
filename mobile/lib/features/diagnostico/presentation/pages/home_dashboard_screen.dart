import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/diagnostico_badge.dart';
import '../../../auth/presentation/controller/session_controller.dart';
import '../../../clima/presentation/clima_card.dart';
import '../../data/datasources/database_service.dart';
import '../../data/models/leitura_model.dart';
import '../widgets/sync_status_button.dart';
import 'leitura_detalhe_screen.dart';
import 'selecao_talhao_screen.dart';
import 'historico_screen.dart';
import 'mapa_screen.dart';

/// Tela inicial do AGdata — barra de marca fixa, acesso principal ao mapa
/// (central de controle) e demais ações em lista. Menu lateral reservado
/// para dados futuros de usuário/empresa.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _ir(BuildContext context, Widget tela) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ClimaCard(),
                  const SizedBox(height: AppSpacing.xl),
                  _MapControlCard(onTap: () => _ir(context, const MapaScreen())),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Ações rápidas',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.center_focus_strong_outlined,
                    title: 'Nova Análise',
                    subtitle: 'Capturar e diagnosticar uma amostra',
                    accent: AppColors.primary,
                    onTap: () => _ir(context, const SelecaoTalhaoScreen()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.history,
                    title: 'Histórico',
                    subtitle: 'Relatórios e leituras salvas',
                    accent: AppColors.info,
                    onTap: () => _ir(context, const HistoricoScreen()),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _UltimasLeituras(
                    onVerTodas: () => _ir(context, const HistoricoScreen()),
                    onAbrirDetalhe: (l) => _ir(context, LeituraDetalheScreen(leitura: l)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra superior fixa com a marca (verde, cantos inferiores arredondados).
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final nome = sl<SessionController>().usuario?.name.split(' ').first;
    final subtitulo = nome != null ? 'Olá, $nome!' : 'Diagnóstico fitossanitário da soja';
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, topInset + AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AGdata',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
                Text(subtitulo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        )),
              ],
            ),
          ),
          const SyncStatusButton(),
        ],
      ),
    );
  }
}

/// Cartão grande de acesso ao mapa — "central de controle" dos focos.
class _MapControlCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MapControlCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: SizedBox(
          height: 190,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fundo verde.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3C8C40), AppColors.primaryDark],
                    ),
                  ),
                ),
                // Malha simbolizando um mapa.
                CustomPaint(
                  painter: _MalhaMapaPainter(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                // Botão central com ícone de mapa.
                Center(
                  child: Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.map_outlined,
                        color: Colors.white, size: 38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desenha uma malha (grade) leve para simbolizar um mapa.
class _MalhaMapaPainter extends CustomPainter {
  final Color color;
  const _MalhaMapaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const passo = 30.0;
    for (double x = 0; x <= size.width; x += passo) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += passo) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MalhaMapaPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Seção "Atividade recente" no dashboard — exibe as 3 leituras mais recentes.
class _UltimasLeituras extends StatelessWidget {
  final VoidCallback onVerTodas;
  final ValueChanged<LeituraModel> onAbrirDetalhe;

  const _UltimasLeituras({
    required this.onVerTodas,
    required this.onAbrirDetalhe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Atividade recente',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: onVerTodas,
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        FutureBuilder<List<LeituraModel>>(
          future: DatabaseService().buscarTodasLeituras(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final todas = snapshot.data ?? [];
            final recentes = todas.reversed.take(3).toList();
            if (recentes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Nenhuma análise ainda.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: recentes
                  .map((l) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: DiagnosticoBadge(
                              resultado: l.resultadoIA, dense: true),
                          title: Text(
                            '${l.talhao} · ${l.resultadoIA}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(formatarDataHora(l.dataHora),
                              style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary),
                          onTap: () => onAbrirDetalhe(l),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Item de ação em formato de lista (ícone + título + subtítulo + seta).
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

