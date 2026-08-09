import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;
  bool _senhaVisivel = false;
  bool _confirmarVisivel = false;

  final _authRepo = sl<AuthRepository>();
  final _session = sl<SessionController>();

  @override
  void dispose() {
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _atualizarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      // 1. Atualiza no Firebase e Firestore via Repositório
      await _authRepo.atualizarSenha(_novaSenhaController.text.trim());

      // 2. Atualiza a sessão local
      if (_session.usuario != null) {
        final usuarioAtualizado = _session.usuario!.copyWith(
          needsPasswordChange: false,
        );
        _session.setUsuario(usuarioAtualizado);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Senha definida com sucesso!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 3. Volta para o AuthWrapper, que roteia pelo role (operador → HomeDashboard, admin → AdminPage, etc.)
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Segurança"),
        backgroundColor: AppColors.primaryDark,
        automaticallyImplyLeading: false,
        actions: [
          // Opção de sair caso o usuário não queira trocar a senha agora
          IconButton(
            onPressed: () => _authRepo.logout(),
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Sair",
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primaryDark,
              padding: const EdgeInsets.only(bottom: 32),
              child: const Column(
                children: [
                  Icon(Icons.lock_reset, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Defina sua senha",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Você está usando uma senha provisória. Para sua segurança, crie uma senha pessoal de acesso.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      controller: _novaSenhaController,
                      obscureText: !_senhaVisivel,
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: "Nova Senha *",
                        hintText: "Mínimo 6 caracteres",
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? "Senha muito curta" : null,
                    ),
                    if (_novaSenhaController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _ForcaSenhaBar(senha: _novaSenhaController.text),
                    ],

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _confirmarSenhaController,
                      obscureText: !_confirmarVisivel,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: "Confirmar Senha *",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_confirmarVisivel ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _confirmarVisivel = !_confirmarVisivel),
                        ),
                      ),
                      validator: (v) {
                        if (v != _novaSenhaController.text) return "As senhas não coincidem";
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _atualizarSenha,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: _carregando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "SALVAR",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForcaSenhaBar extends StatelessWidget {
  final String senha;
  const _ForcaSenhaBar({required this.senha});

  int _calcularForca() {
    if (senha.length < 6) return 1;
    int p = 1;
    if (senha.length >= 8) p++;
    if (RegExp(r'[A-Z]').hasMatch(senha) && RegExp(r'[0-9]').hasMatch(senha)) p++;
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final forca = _calcularForca();
    final cores = [Colors.red, Colors.orange, Colors.green];
    final labels = ['Fraca', 'Média', 'Forte'];
    final cor = cores[forca - 1];
    final label = labels[forca - 1];

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: forca / 3,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(cor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}