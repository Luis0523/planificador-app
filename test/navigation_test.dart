import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planificador_actividades/main.dart';
import 'package:planificador_actividades/services/mock_backend.dart';

Future<void> _iniciarApp(WidgetTester tester) async {
  await tester.pumpWidget(const PlanificadorApp());
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const Key('login_correo')), 'demo@planificador.com');
  await tester.enterText(
      find.byKey(const Key('login_contrasena')), '123456');
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

Future<void> _abrirDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    MockBackend.instance.reset();
  });

  testWidgets('el dashboard saluda al usuario logueado', (tester) async {
    await _iniciarApp(tester);
    await _login(tester);

    expect(find.text('Hola, Alumno 👋'), findsOneWidget);
    expect(find.text('¿Qué planazo armamos hoy?'), findsOneWidget);
    expect(find.text('Próximas actividades'), findsOneWidget);
    expect(find.text('Ubicaciones guardadas'), findsOneWidget);
    expect(find.text('Crear planazo'), findsOneWidget);
  });

  testWidgets('el drawer muestra las secciones y cierra sesión',
      (tester) async {
    await _iniciarApp(tester);
    await _login(tester);

    await _abrirDrawer(tester);

    expect(find.byKey(const Key('drawer_inicio')), findsOneWidget);
    expect(find.byKey(const Key('drawer_ubicaciones')), findsOneWidget);
    expect(find.byKey(const Key('drawer_actividades')), findsOneWidget);
    expect(find.byKey(const Key('drawer_pendientes')), findsOneWidget);
    expect(find.byKey(const Key('drawer_perfil')), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('la navegación inferior cambia de módulo', (tester) async {
    await _iniciarApp(tester);
    await _login(tester);

    // Inicio (dashboard)
    expect(find.text('¿Qué planazo armamos hoy?'), findsOneWidget);

    // Ubicaciones
    await tester.tap(find.byKey(const Key('nav_ubicaciones')));
    await tester.pumpAndSettle();
    expect(find.text('Mis ubicaciones'), findsOneWidget);
    expect(find.byKey(const Key('btn_nueva_ubicacion')), findsOneWidget);

    // Pendientes
    await tester.tap(find.byKey(const Key('nav_pendientes')));
    await tester.pumpAndSettle();
    expect(find.text('Actividades pendientes'), findsOneWidget);
    expect(find.textContaining('Fase 7'), findsOneWidget);

    // Vuelta al inicio
    await tester.tap(find.byKey(const Key('nav_inicio')));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué planazo armamos hoy?'), findsOneWidget);
  });

  testWidgets('desde el drawer se abre Mi perfil', (tester) async {
    await _iniciarApp(tester);
    await _login(tester);

    await _abrirDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer_perfil')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('perfil_guardar')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Qué planazo armamos hoy?'), findsOneWidget);
  });

  testWidgets('desde el drawer se abre Mis actividades', (tester) async {
    await _iniciarApp(tester);
    await _login(tester);

    await _abrirDrawer(tester);
    await tester.tap(find.byKey(const Key('drawer_actividades')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fase 6'), findsOneWidget);
  });
}
