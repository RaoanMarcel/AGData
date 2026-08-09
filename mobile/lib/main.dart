import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'features/diagnostico/presentation/pages/home_dashboard_screen.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/super_admin_page.dart';
import 'features/auth/presentation/pages/admin_page.dart';
import 'features/diagnostico/presentation/pages/selecao_talhao_screen.dart';
import 'features/auth/presentation/pages/change_password_page.dart';
import 'features/auth/data/models/auth_model.dart';
import 'features/auth/presentation/controller/session_controller.dart';
import 'features/diagnostico/data/datasources/database_service.dart';
import 'infra/repositories/sync_repository.dart';
import 'infra/services/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await DatabaseService.initialize();
      await di.init();
      final syncRepo = sl<SyncRepository>();
      await syncRepo.sincronizarLeituras();
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Erro ao carregar arquivo .env: $e');
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'];
      options.tracesSampleRate = 1.0;
      // ignore: experimental_member_use
      options.profilesSampleRate = 1.0;
    },
    appRunner: () async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
      }

      try {
        await DatabaseService.initialize();
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
      }

      await di.init();

      try {
        await Workmanager().initialize(
          callbackDispatcher,
        );

        await Workmanager().registerPeriodicTask(
          "sync-task-id",
          "syncTask",
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
      } catch (e) {
        debugPrint('Erro no Workmanager: $e');
      }

      sl<ConnectivityService>().configurarOuvinteDeSincronizacao();
      _dispararSincronizacaoAutomatica();

      runApp(SentryWidget(child: const AGDataApp()));
    },
  );
}

void _dispararSincronizacaoAutomatica() async {
  final syncRepo = sl<SyncRepository>();
  try {
    await syncRepo.sincronizarLeituras();
  } catch (e, stackTrace) {
    await Sentry.captureException(e, stackTrace: stackTrace);
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget _page = const _SplashScreen(key: ValueKey('splash'));

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (!mounted) return;

    if (user == null) {
      setState(() => _page = const LoginPage(key: ValueKey('login')));
      return;
    }

    setState(() => _page = const _SplashScreen(key: ValueKey('splash')));

    try {
      final session = sl<SessionController>();
      if (session.usuario == null) await session.inicializarUsuario();

      if (!mounted) return;

      final usuario = session.usuario;
      if (usuario == null) {
        await FirebaseAuth.instance.signOut();
        return;
      }

      final Widget dest;
      if (usuario.needsPasswordChange) {
        dest = const ChangePasswordPage(key: ValueKey('change-pw'));
      } else if (usuario.role == UserRole.superAdmin) {
        dest = const SuperAdminPage(key: ValueKey('super-admin'));
      } else if (usuario.role == UserRole.admin) {
        dest = const AdminPage(key: ValueKey('admin'));
      } else {
        dest = const HomeDashboardScreen(key: ValueKey('home'));
      }

      if (mounted) setState(() => _page = dest);
    } catch (e) {
      debugPrint("Erro fatal na carga da sessão: $e");
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _page,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.green)),
    );
  }
}

class AGDataApp extends StatelessWidget {
  const AGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGdata',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/super-admin': (context) => const SuperAdminPage(),
        '/admin': (context) => const AdminPage(),
        '/selecao-talhao': (context) => const SelecaoTalhaoScreen(),
      },
    );
  }
}
