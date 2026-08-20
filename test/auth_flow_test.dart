import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planificador_actividades/main.dart';

Future<void> _iniciarApp(WidgetTester tester) async {
  await tester.pumpWidget(const PlanificadorApp());
  await tester.pumpAndSettle();
}

Future<void> _login(
  WidgetTester tester, {
  String correo = 'demo@planificador.com',
  String contrasena = '123456',
}) async {
  await tester.enterText(find.byKey(const Key('login_correo')), correo);
  await tester.enterText(find.byKey(const Key('login_contrasena')), contrasena);
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('login con credenciales demo llega al Home', (tester) async {
    await _iniciarApp(tester);

    await _login(tester);

    expect(find.text('Módulos próximamente'), findsOneWidget);
  });

  testWidgets('login con contraseña temporal fuerza el cambio de contraseña',
      (tester) async {
    await _iniciarApp(tester);

    await _login(tester, contrasena: 'temporal123');

    expect(find.text('Cambiar contraseña'), findsOneWidget);

    // Contraseñas que no coinciden: se rechaza.
    await tester.enterText(find.byKey(const Key('nueva_contrasena')), 'nueva123');
    await tester.enterText(find.byKey(const Key('confirmar_contrasena')), 'distinta');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    // Corrige la confirmación: ahora sí llega al Home.
    await tester.enterText(find.byKey(const Key('confirmar_contrasena')), 'nueva123');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Módulos próximamente'), findsOneWidget);
  });

  testWidgets('campos vacíos en login muestran validación', (tester) async {
    await _iniciarApp(tester);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('El correo es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
  });

  testWidgets('credenciales incorrectas muestran error', (tester) async {
    await _iniciarApp(tester);

    await _login(tester, contrasena: 'incorrecta');

    expect(find.text('Credenciales incorrectas'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
  });

  testWidgets('registro exitoso vuelve a login con mensaje', (tester) async {
    await _iniciarApp(tester);

    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('registro_nombre_completo')), 'Ana Pérez');
    await tester.enterText(find.byKey(const Key('registro_nombre_usuario')), 'ana');
    await tester.enterText(find.byKey(const Key('registro_correo')), 'ana@correo.com');
    await tester.enterText(find.byKey(const Key('registro_telefono')), '5550001111');
    await tester.enterText(find.byKey(const Key('registro_contrasena')), 'secreta1');
    await tester.enterText(find.byKey(const Key('registro_confirmar')), 'secreta1');
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Cuenta creada. Ahora puedes iniciar sesión.'), findsOneWidget);
  });

  testWidgets('logout regresa a login y no conserva sesión', (tester) async {
    await _iniciarApp(tester);
    await _login(tester);

    expect(find.text('Módulos próximamente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton_logout')));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsOneWidget);

    // Al reabrir la app (nuevo tree) ya no hay sesión activa.
    await tester.pumpWidget(const SizedBox());
    await _iniciarApp(tester);
    expect(find.text('Inicia sesión'), findsOneWidget);
  });
}
