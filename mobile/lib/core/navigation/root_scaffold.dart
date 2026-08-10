import 'package:flutter/material.dart';
import '../../../features/auth/data/models/auth_model.dart';
import '../../../features/auth/data/repositories/auth_repository.dart';
import '../../../features/auth/presentation/controller/session_controller.dart';
import '../../../features/auth/presentation/pages/admin_page.dart';
import '../../../features/auth/presentation/pages/super_admin_page.dart';
import '../../../features/diagnostico/presentation/pages/home_dashboard_screen.dart';
import '../../../features/diagnostico/presentation/pages/historico_screen.dart';
import '../../../features/diagnostico/presentation/pages/mapa_screen.dart';
import '../../../features/diagnostico/presentation/pages/selecao_talhao_screen.dart';
import '../../../features/relatorio/presentation/pages/relatorio_page.dart';
import '../../../features/prescricao/presentation/pages/prescricao_page.dart';
import '../../../features/settings/presentation/pages/settings_page.dart';
import '../di/injection_container.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _selectedIndex = 0;

  UserRole get _role => sl<SessionController>().usuario?.role ?? UserRole.operador;

  bool get _isOperador => _role == UserRole.operador;
  bool get _isAdmin => _role == UserRole.admin;

  List<Widget> get _screens {
    if (_isOperador) {
      return const [
        HomeDashboardScreen(),
        SelecaoTalhaoScreen(),
        HistoricoScreen(),
        MapaScreen(),
      ];
    } else if (_isAdmin) {
      return const [
        HomeDashboardScreen(),
        SelecaoTalhaoScreen(),
        AdminPage(),
        RelatorioPage(),
      ];
    } else {
      // superAdmin
      return const [
        HomeDashboardScreen(),
        SelecaoTalhaoScreen(),
        SuperAdminPage(),
        RelatorioPage(),
      ];
    }
  }

  List<NavigationDestination> get _destinations {
    if (_isOperador) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.center_focus_strong_outlined),
          selectedIcon: Icon(Icons.center_focus_strong),
          label: 'Analisar',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Histórico',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'Mais',
        ),
      ];
    } else if (_isAdmin) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Campo',
        ),
        NavigationDestination(
          icon: Icon(Icons.center_focus_strong_outlined),
          selectedIcon: Icon(Icons.center_focus_strong),
          label: 'Analisar',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Equipe',
        ),
        NavigationDestination(
          icon: Icon(Icons.picture_as_pdf_outlined),
          selectedIcon: Icon(Icons.picture_as_pdf),
          label: 'Relatório',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'Mais',
        ),
      ];
    } else {
      // superAdmin
      return const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Campo',
        ),
        NavigationDestination(
          icon: Icon(Icons.center_focus_strong_outlined),
          selectedIcon: Icon(Icons.center_focus_strong),
          label: 'Analisar',
        ),
        NavigationDestination(
          icon: Icon(Icons.domain_outlined),
          selectedIcon: Icon(Icons.domain),
          label: 'Empresas',
        ),
        NavigationDestination(
          icon: Icon(Icons.picture_as_pdf_outlined),
          selectedIcon: Icon(Icons.picture_as_pdf),
          label: 'Relatório',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'Mais',
        ),
      ];
    }
  }

  void _onDestinationSelected(int index) {
    // "Mais" tab opens bottom sheet instead of switching screen
    if (index == 4) {
      _abrirMaisSheet();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _abrirMaisSheet() {
    final session = sl<SessionController>();
    final nome = session.usuario?.name ?? '';

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (_isOperador)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Relatórios'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RelatorioPage()),
                    );
                  },
                ),
              if (!_isOperador)
                ListTile(
                  leading: const Icon(Icons.agriculture_outlined),
                  title: const Text('Prescrição de Máquina'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrescricaoPage()),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Sair · $nome',
                  style: const TextStyle(color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmarSair();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmarSair() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair?'),
        content: const Text('Deseja realmente encerrar sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await sl<AuthRepository>().logout();
              } catch (_) {}
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              }
            },
            child: const Text('SAIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    return PopScope(
      // Quando não está na aba inicial, voltar para ela antes de sair.
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: _destinations,
        ),
      ),
    );
  }
}
