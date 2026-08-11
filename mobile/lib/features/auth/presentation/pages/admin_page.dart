import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Imports baseados na sua estrutura de pastas
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/auth_model.dart';
import '../controller/session_controller.dart';
import 'add_user_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _session = sl<SessionController>();
  final _firestore = FirebaseFirestore.instance;
  late Future<String> _companyNameFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _companyNameFuture = _fetchCompanyName(_session.usuario?.companyId ?? '');
  }

  Future<String> _fetchCompanyName(String companyId) async {
    if (companyId.isEmpty) return 'Empresa';
    try {
      final doc = await _firestore.collection('companies').doc(companyId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['name'] ?? 'Empresa';
      }
    } catch (_) {}
    return 'Empresa';
  }

  Future<void> _enviarAcessoWhatsApp(UserModel user) async {
    final numeroLimpo = user.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (numeroLimpo.length < 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Telefone inválido para envio.")),
        );
      }
      return;
    }

    final mensagem = "Olá ${user.name}! 🌱\nSua conta no HectarIA está ativa.\n📧 Login: ${user.email}";
    final url = Uri.parse("https://wa.me/55$numeroLimpo?text=${Uri.encodeComponent(mensagem)}");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o WhatsApp.")),
        );
      }
    }
  }

  void _confirmarExclusao(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir?"),
        content: Text("Remover o acesso de ${user.name}? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(user.uid).delete();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao excluir: $e")),
                  );
                }
              }
            },
            child: const Text("EXCLUIR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyId = _session.usuario?.companyId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão de Operadores"),
      ),
      body: Column(
        children: [
          FutureBuilder<String>(
            future: _companyNameFuture,
            builder: (context, snap) {
              final nomeEmpresa = snap.data ?? '...';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.primaryContainer,
                child: Row(
                  children: [
                    const Icon(Icons.business, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nomeEmpresa,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Olá, ${_session.usuario?.name ?? ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou e-mail...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('companyId', isEqualTo: companyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados."));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;
                final docs = _searchQuery.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                        final user = UserModel.fromMap(
                            doc.data() as Map<String, dynamic>);
                        return user.name
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            user.email
                                .toLowerCase()
                                .contains(_searchQuery);
                      }).toList();

                if (allDocs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Nenhum usuário cadastrado',
                    message: 'Adicione operadores ou administradores usando o botão abaixo.',
                  );
                }

                if (docs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Sem resultados',
                    message: 'Nenhum usuário encontrado para a busca.',
                  );
                }

                final usuarios = docs
                    .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
                    .toList();
                final admins = usuarios.where((u) => u.role == UserRole.admin).toList();
                final operadores = usuarios.where((u) => u.role == UserRole.operador).toList();

                final items = <Widget>[];

                // Seção Administradores
                items.add(_ListaHeader(
                  titulo: 'Administradores',
                  count: admins.length,
                ));
                if (admins.isEmpty) {
                  items.add(const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Nenhum', style: TextStyle(color: AppColors.textTertiary)),
                  ));
                } else {
                  for (final user in admins) {
                    items.add(_UserCard(
                      user: user,
                      isMe: user.uid == _session.usuario?.uid,
                      onWhatsApp: () => _enviarAcessoWhatsApp(user),
                      onExcluir: () => _confirmarExclusao(user),
                    ));
                  }
                }

                items.add(const SizedBox(height: 8));

                // Seção Operadores
                items.add(_ListaHeader(
                  titulo: 'Operadores',
                  count: operadores.length,
                ));
                if (operadores.isEmpty) {
                  items.add(const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Nenhum', style: TextStyle(color: AppColors.textTertiary)),
                  ));
                } else {
                  for (final user in operadores) {
                    items.add(_UserCard(
                      user: user,
                      isMe: user.uid == _session.usuario?.uid,
                      onWhatsApp: () => _enviarAcessoWhatsApp(user),
                      onExcluir: () => _confirmarExclusao(user),
                    ));
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: items,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddUserPage()),
        ),
        label: const Text("NOVO OPERADOR", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────────

class _ListaHeader extends StatelessWidget {
  final String titulo;
  final int count;
  const _ListaHeader({required this.titulo, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          Text(
            '$titulo ($count)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final VoidCallback onWhatsApp;
  final VoidCallback onExcluir;

  const _UserCard({
    required this.user,
    required this.isMe,
    required this.onWhatsApp,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == UserRole.admin;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.orange.shade100 : AppColors.primaryContainer,
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: isAdmin ? Colors.orange : AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: const Text(
                  'Você',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: AppColors.primary, size: 20),
                onPressed: onWhatsApp,
                tooltip: "Enviar Acesso",
              ),
            if (!isMe)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                onPressed: onExcluir,
                tooltip: "Excluir",
              ),
          ],
        ),
      ),
    );
  }
}