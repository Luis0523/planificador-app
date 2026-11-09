import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/actividades_pendientes_provider.dart';
import 'providers/actividades_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/ubicaciones_provider.dart';
import 'screens/auth/cambiar_contrasena_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
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
        ChangeNotifierProvider(create: (_) => UbicacionesProvider()),
        ChangeNotifierProvider(create: (_) => ActividadesProvider()),
        ChangeNotifierProvider(create: (_) => ActividadesPendientesProvider()),
      ],
      child: MaterialApp(
        title: 'Planazo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.desconocido:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.noAutenticado:
        return const LoginScreen();
      case AuthStatus.requiereCambio:
        return const CambiarContrasenaScreen();
      case AuthStatus.autenticado:
        return const HomeScreen();
    }
  }
}
