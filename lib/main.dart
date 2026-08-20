import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/cambiar_contrasena_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const PlanificadorApp());
}

class PlanificadorApp extends StatelessWidget {
  const PlanificadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Planificador de Actividades',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide qué pantalla mostrar según el estado de autenticación:
/// - Sin sesión -> login
/// - Login con contraseña temporal -> forzar cambio de contraseña
/// - Sesión activa -> Home
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.desconocido:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.noAutenticado:
        return const LoginScreen();
      case AuthStatus.requiereCambio:
        return const CambiarContrasenaScreen();
      case AuthStatus.autenticado:
        return const HomeScreen();
    }
  }
}
