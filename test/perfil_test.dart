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

Future<void> _abrirPerfil(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('drawer_perfil')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    MockBackend.instance.reset();
  });

  testWidgets('el perfil muestra los datos del usuario logueado',
      (tester) async {
    await _iniciarApp(tester);
    await _login(tester);
    await _abrirPerfil(tester);

    expect(find.text('Alumno Demo'), findsWidgets);
    expect(find.text('demo@planificador.com'), findsWidgets);

    final nombre = tester
        .widget<TextFormField>(find.byKey(const Key('perfil_nombre_completo')));
    expect(nombre.controller?.text, 'Alumno Demo');

    final telefono = tester
        .widget<TextFormField>(find.byKey(const Key('perfil_telefono')));
    expect(telefono.controller?.text, '5551234567');

    // nombreUsuario, correo y contraseña son de solo lectura.
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('perfil_nombre_usuario')))
            .enabled,
        isFalse);
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('perfil_correo')))
            .enabled,
        isFalse);
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('perfil_contrasena')))
            .enabled,
        isFalse);
  });

  testWidgets('editar nombre y teléfono persiste al recargar la pantalla',
      (tester) async {
    await _iniciarApp(tester);
    await _login(tester);
    await _abrirPerfil(tester);

    await tester.enterText(
        find.byKey(const Key('perfil_nombre_completo')), 'Ana Pérez');
    await tester.enterText(find.byKey(const Key('perfil_telefono')), '5550002222');
    await tester.ensureVisible(find.byKey(const Key('perfil_guardar')));
    await tester.tap(find.byKey(const Key('perfil_guardar')));
    await tester.pumpAndSettle();

    expect(find.text('Perfil actualizado correctamente.'), findsOneWidget);

    // Volver a entrar al perfil: el cambio persiste.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _abrirPerfil(tester);

    final nombre = tester
        .widget<TextFormField>(find.byKey(const Key('perfil_nombre_completo')));
    expect(nombre.controller?.text, 'Ana Pérez');

    final telefono = tester
        .widget<TextFormField>(find.byKey(const Key('perfil_telefono')));
    expect(telefono.controller?.text, '5550002222');
  });

  testWidgets('validación: teléfono inválido no guarda', (tester) async {
    await _iniciarApp(tester);
    await _login(tester);
    await _abrirPerfil(tester);

    await tester.enterText(find.byKey(const Key('perfil_telefono')), 'abc');
    await tester.ensureVisible(find.byKey(const Key('perfil_guardar')));
    await tester.tap(find.byKey(const Key('perfil_guardar')));
    await tester.pumpAndSettle();

    expect(find.text('Teléfono inválido (solo dígitos)'), findsOneWidget);
    expect(find.text('Perfil actualizado correctamente.'), findsNothing);
  });
}
