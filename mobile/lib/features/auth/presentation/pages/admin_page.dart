import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Imports baseados na sua estrutura de pastas
import '../../../../core/di/injection_container.dart';
import '../../data/models/auth_model.dart';
import '../controller/session_controller.dart';
import '../widgets/custom_drawer.dart'; // Import do seu novo Drawer
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
      // Adicionado o Drawer que você criou
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          FutureBuilder<String>(
            future: _companyNameFuture,
            builder: (context, snap) {
              final nomeEmpresa = snap.data ?? '...';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.green.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Color(0xFF2E7D32), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nomeEmpresa,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Olá, ${_session.usuario?.name ?? ''}',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
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
                  return const Center(child: Text("Nenhum operador cadastrado."));
                }

                if (docs.isEmpty) {
                  return const Center(
                      child: Text("Nenhum resultado para a busca."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = UserModel.fromMap(docs[index].data() as Map<String, dynamic>);
                    final isMe = user.uid == _session.usuario?.uid;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.role == UserRole.admin ? Colors.orange.shade100 : Colors.green.shade100,
                          child: Icon(
                            user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.person,
                            color: user.role == UserRole.admin ? Colors.orange : Colors.green,
                          ),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 20),
                                onPressed: () => _enviarAcessoWhatsApp(user),
                                tooltip: "Enviar Acesso",
                              ),
                            if (!isMe)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                onPressed: () => _confirmarExclusao(user),
                                tooltip: "Excluir",
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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