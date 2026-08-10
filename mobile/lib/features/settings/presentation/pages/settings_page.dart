import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/presentation/controller/session_controller.dart';
import '../../../diagnostico/data/datasources/database_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _db = DatabaseService();

  int? _totalLeituras;
  int? _pendentes;
  bool _limpando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final todas = await _db.buscarTodasLeituras();
    final pendentes = await _db.contarLeiturasPendentes();
    if (!mounted) return;
    setState(() {
      _totalLeituras = todas.length;
      _pendentes = pendentes;
    });
  }

  Future<void> _confirmarLimpeza() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar cache local'),
        content: const Text(
          'Todas as leituras salvas neste dispositivo serão removidas. '
          'Leituras já sincronizadas com a nuvem não serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    setState(() => _limpando = true);
    await _db.limparTodasLeituras();
    await _carregarDados();
    if (!mounted) return;
    setState(() => _limpando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache local limpo.')),
    );
  }

  Future<void> _abrirEmail() async {
    final uri = Uri.parse('mailto:suporte@hectaria.com.br');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = sl<SessionController>().usuario;
    final nome = usuario?.name ?? '';
    final email = usuario?.email ?? '';
    final role = usuario?.role ?? UserRole.operador;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const _SecaoLabel(label: 'Perfil'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  _Avatar(nome: nome),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome.isEmpty ? '—' : nome,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _RoleChip(role: role),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SecaoLabel(label: 'Dados Locais'),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.analytics_outlined,
                  label: 'Leituras salvas no dispositivo',
                  valor: _totalLeituras == null ? '...' : '$_totalLeituras',
                ),
                const Divider(height: 1, indent: AppSpacing.xl * 2.5),
                _InfoTile(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Pendentes de sincronização',
                  valor: _pendentes == null ? '...' : '$_pendentes',
                  valorColor:
                      (_pendentes ?? 0) > 0 ? AppColors.syncPending : null,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _limpando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.danger),
                            )
                          : const Icon(Icons.delete_sweep_outlined,
                              color: AppColors.danger),
                      label: Text(_limpando ? 'Limpando...' : 'Limpar cache local',
                          style: const TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      onPressed: _limpando ? null : _confirmarLimpeza,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SecaoLabel(label: 'Sobre'),
          Card(
            child: Column(
              children: [
                const _InfoTile(
                  icon: Icons.eco_outlined,
                  label: 'Aplicativo',
                  valor: 'HectarIA · AGData',
                ),
                const Divider(height: 1, indent: AppSpacing.xl * 2.5),
                const _InfoTile(
                  icon: Icons.info_outline,
                  label: 'Versão',
                  valor: '1.0.0 (build 1)',
                ),
                const Divider(height: 1, indent: AppSpacing.xl * 2.5),
                _TapTile(
                  icon: Icons.mail_outline,
                  label: 'Suporte',
                  valor: 'suporte@hectaria.com.br',
                  onTap: _abrirEmail,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              '© 2025 HectarIA',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ── Widgets de suporte ────────────────────────────────────────────────────────

class _SecaoLabel extends StatelessWidget {
  final String label;
  const _SecaoLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nome;
  const _Avatar({required this.nome});

  String get _iniciais {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primaryContainer,
      child: Text(
        _iniciais,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (role) {
      UserRole.superAdmin => ('Super Admin', const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
      UserRole.admin => ('Administrador', const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
      UserRole.operador => ('Operador', AppColors.primary, AppColors.primaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color? valorColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.valor,
    this.valorColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(
        valor,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valorColor ?? AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final VoidCallback onTap;

  const _TapTile({
    required this.icon,
    required this.label,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
        ],
      ),
      onTap: onTap,
    );
  }
}
