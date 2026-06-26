import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/menu_card.dart';
import 'selecao_talhao_screen.dart';
import 'historico_screen.dart';
import 'mapa_screen.dart';

/// Tela inicial do AGdata — apresenta a marca e organiza o acesso às opções.
///
/// Substitui a entrada anterior (que caía direto na seleção de talhão).
/// Estruturada para receber futuramente Perfil e Configurações (após login).
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandHeader(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('O que deseja fazer?',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.lg),

                    // Ação principal — iniciar uma nova análise.
                    MenuCard(
                      icon: Icons.center_focus_strong_outlined,
                      title: 'Nova Análise',
                      subtitle: 'Capturar e diagnosticar uma amostra',
                      onTap: () => _ir(context, const SelecaoTalhaoScreen()),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Consultas.
                    Row(
                      children: [
                        Expanded(
                          child: MenuCard(
                            icon: Icons.history,
                            title: 'Histórico',
                            subtitle: 'Leituras salvas',
                            accent: AppColors.info,
                            onTap: () =>
                                _ir(context, const HistoricoScreen()),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: MenuCard(
                            icon: Icons.map_outlined,
                            title: 'Mapa',
                            subtitle: 'Ocorrências no campo',
                            accent: AppColors.oidio,
                            onTap: () => _ir(context, const MapaScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Seção futura (após implementação de login/usuário).
                    Text('Conta',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    const Row(
                      children: [
                        Expanded(
                          child: MenuCard(
                            icon: Icons.person_outline,
                            title: 'Perfil',
                            subtitle: 'Seus dados',
                            enabled: false,
                            badge: 'Em breve',
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: MenuCard(
                            icon: Icons.settings_outlined,
                            title: 'Configurações',
                            subtitle: 'Preferências',
                            enabled: false,
                            badge: 'Em breve',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ir(BuildContext context, Widget tela) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }
}

/// Cabeçalho com a marca do app (gradiente verde + nome + tagline).
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'AGdata',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Diagnóstico fitossanitário da soja',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
          ),
        ],
      ),
    );
  }
}
