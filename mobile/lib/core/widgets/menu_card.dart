import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Cartão de opção do menu (dashboard inicial).
///
/// Ícone em destaque + título + subtítulo opcional. Suporta estado desabilitado
/// com selo "Em breve" para funcionalidades futuras (ex: Perfil, Configurações).
class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Cor de destaque do ícone (padrão: primária).
  final Color accent;
  final VoidCallback? onTap;
  final bool enabled;

  /// Selo opcional (ex: "Em breve") exibido no canto.
  final String? badge;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = AppColors.primary,
    this.onTap,
    this.enabled = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color accentColor = enabled ? accent : AppColors.textTertiary;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Card(
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: accentColor, size: 28),
                    ),
                    if (badge != null) _Badge(text: badge!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
