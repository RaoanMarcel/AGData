import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/controller/session_controller.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/super_admin_page.dart';
import '../../../auth/presentation/pages/admin_page.dart';
import '../../../diagnostico/presentation/pages/selecao_talhao_screen.dart';
import '../../../diagnostico/presentation/pages/historico_screen.dart';
import '../../../diagnostico/presentation/pages/mapa_screen.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onSync;
  final bool isSyncing;

  const CustomDrawer({
    super.key,
    this.onSync,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionController>();
    final user = session.usuario;
    final bool isSuperAdmin = user?.role == UserRole.superAdmin;
    final bool isAdmin = user?.role == UserRole.admin;
    final bool temAcessoGestao = isSuperAdmin || isAdmin;

    return Drawer(
      child: Column(
        children: [
          _DrawerHeader(user: user, isSuperAdmin: isSuperAdmin),

          // OPÇÃO DE SINCRONIZAÇÃO
          if (onSync != null)
            ListTile(
              leading: isSyncing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync, color: Colors.green),
              title: const Text("Sincronizar Dados"),
              onTap: isSyncing ? null : () {
                Navigator.pop(context);
                onSync!();
              },
            ),

          // NAVEGAÇÃO PRINCIPAL
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 10, bottom: 4),
            child: Text(
              "NAVEGAÇÃO",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Color(0xFF2E7D32)),
            title: const Text("Início"),
            subtitle: const Text("Voltar para a tela principal"),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.center_focus_strong_outlined, color: Color(0xFF2E7D32)),
            title: const Text("Nova Análise"),
            subtitle: const Text("Selecionar talhão e diagnosticar"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SelecaoTalhaoScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF1565C0)),
            title: const Text("Histórico"),
            subtitle: const Text("Leituras e relatórios salvos"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoricoScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined, color: Color(0xFF6A1B9A)),
            title: const Text("Mapa de Ocorrências"),
            subtitle: const Text("Visualizar focos no campo"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaScreen()));
            },
          ),

          // ÁREA DE GESTÃO (FILTRADA POR ROLE)
          if (temAcessoGestao) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text("ADMINISTRAÇÃO", 
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            ListTile(
              leading: Icon(isSuperAdmin ? Icons.domain : Icons.people, color: Colors.blue),
              title: Text(isSuperAdmin ? "Painel Global" : "Gerenciar Operadores"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isSuperAdmin ? const SuperAdminPage() : const AdminPage(),
                  ),
                );
              },
            ),
          ],

          const Spacer(),
          const Divider(),
          
          // BOTÃO DE SAIR UNIFICADO
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sair da Conta", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _confirmarSair(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmarSair(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair?"),
        content: const Text("Deseja realmente encerrar sua sessão?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await sl<AuthRepository>().logout();
              } catch (_) {}
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text("SAIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Cabeçalho do drawer com espaçamento manual ────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final dynamic user;
  final bool isSuperAdmin;

  const _DrawerHeader({required this.user, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bgColor =
        isSuperAdmin ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32);

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              isSuperAdmin ? Icons.admin_panel_settings : Icons.person,
              color: bgColor,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),

          // Nome
          Text(
            user?.name ?? 'Usuário',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),

          // E-mail
          Text(
            user?.email ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

          // Nome da empresa (apenas para admin/operador)
          if (!isSuperAdmin && user?.companyId != null) ...[
            const SizedBox(height: 2),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(user!.companyId as String)
                  .get(),
              builder: (context, snapshot) {
                final nome = snapshot.hasData && snapshot.data!.exists
                    ? (snapshot.data!.data()
                            as Map<String, dynamic>)['name'] ??
                        ''
                    : '';
                if (nome.isEmpty) return const SizedBox.shrink();
                return Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}