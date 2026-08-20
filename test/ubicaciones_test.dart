import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:planificador_actividades/config/constants.dart';
import 'package:planificador_actividades/database/database_helper.dart';
import 'package:planificador_actividades/main.dart';
import 'package:planificador_actividades/services/mock_backend.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const Key('login_correo')), 'demo@planificador.com');
  await tester.enterText(
      find.byKey(const Key('login_contrasena')), '123456');
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

Future<void> _irAUbicaciones(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav_ubicaciones')));
  await tester.pumpAndSettle();
}

Future<void> _abrirFormulario(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('btn_nueva_ubicacion')));
  await tester.pumpAndSettle();
}

/// Espera a que las operaciones reales de SQLite terminen y la UI se asiente.
Future<void> _esperarDB(WidgetTester tester) async {
  await Future<void>.delayed(const Duration(milliseconds: 250));
  await tester.pumpAndSettle();
}

/// Corre la app dentro de `runAsync` para que las operaciones reales de
/// SQLite (sqflite ffi) puedan completar.
Future<void> _flujo(WidgetTester tester, Future<void> Function() cuerpo) async {
  await tester.runAsync(() async {
    await DatabaseHelper.instance.database; // abre la BD de una vez
    await tester.pumpWidget(const PlanificadorApp());
    await tester.pumpAndSettle();
    await _login(tester);
    // Deja que la carga inicial (ubicaciones) termine.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await cuerpo();
  });
}

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    FlutterSecureStorage.setMockInitialValues({});
    MockBackend.instance.reset();
    await DatabaseHelper.instance.close();
    // Borra el archivo de la BD para aislar cada test.
    await deleteDatabase(join(await getDatabasesPath(), Constants.dbName));
  });

  testWidgets('crear una ubicación y verla en el listado', (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);

      expect(find.text('Aún no tienes ubicaciones'), findsOneWidget);

      await _abrirFormulario(tester);
      await tester.enterText(
          find.byKey(const Key('ubicacion_nombre')), 'Parque Central');
      await tester.enterText(
          find.byKey(const Key('ubicacion_direccion')), 'Centro');
      await tester.enterText(
          find.byKey(const Key('ubicacion_latitud')), '19.4326');
      await tester.enterText(
          find.byKey(const Key('ubicacion_longitud')), '-99.1332');
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('Parque Central'), findsOneWidget);
      expect(find.text('Aún no tienes ubicaciones'), findsNothing);
    });
  });

  testWidgets('crear por GPS (mock) llena coordenadas y guarda',
      (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);
      await _abrirFormulario(tester);

      await tester.tap(find.byKey(const Key('btn_gps')));
      await _esperarDB(tester);

      expect(
          find.textContaining('Se usó una ubicación de ejemplo'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('ubicacion_latitud')))
            .controller
            ?.text,
        '19.432600',
      );

      await tester.enterText(
          find.byKey(const Key('ubicacion_nombre')), 'Desde GPS');
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('Desde GPS'), findsOneWidget);
    });
  });

  testWidgets('seleccionar en mapa (mock) llena las coordenadas',
      (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);
      await _abrirFormulario(tester);

      await tester.tap(find.byKey(const Key('btn_mapa')));
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar en el mapa'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('mapa_latitud')), '20.5');
      await tester.enterText(find.byKey(const Key('mapa_longitud')), '-100.5');
      await tester.tap(find.byKey(const Key('mapa_aceptar')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('ubicacion_latitud')))
            .controller
            ?.text,
        '20.500000',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('ubicacion_longitud')))
            .controller
            ?.text,
        '-100.500000',
      );
    });
  });

  testWidgets('editar una ubicación persiste el cambio', (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);

      await _abrirFormulario(tester);
      await tester.enterText(
          find.byKey(const Key('ubicacion_nombre')), 'Parque Central');
      await tester.enterText(
          find.byKey(const Key('ubicacion_latitud')), '19.4326');
      await tester.enterText(
          find.byKey(const Key('ubicacion_longitud')), '-99.1332');
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      // Editar tocando la tarjeta.
      await tester.tap(find.text('Parque Central'));
      await tester.pumpAndSettle();
      expect(find.text('Editar ubicación'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('ubicacion_nombre')), 'Parque Renombrado');
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('Parque Renombrado'), findsOneWidget);
      expect(find.text('Parque Central'), findsNothing);
    });
  });

  testWidgets('eliminar una ubicación pide confirmación y la borra',
      (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);

      await _abrirFormulario(tester);
      await tester.enterText(
          find.byKey(const Key('ubicacion_nombre')), 'A Eliminar');
      await tester.enterText(find.byKey(const Key('ubicacion_latitud')), '19.0');
      await tester.enterText(
          find.byKey(const Key('ubicacion_longitud')), '-99.0');
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('También se eliminarán las actividades'),
          findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('A Eliminar'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await _esperarDB(tester);

      expect(find.text('A Eliminar'), findsNothing);
      expect(find.text('Aún no tienes ubicaciones'), findsOneWidget);
    });
  });

  testWidgets('validación: nombre y coordenadas obligatorios', (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);
      await _abrirFormulario(tester);

      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('Ingresa una latitud válida'), findsOneWidget);
      expect(find.text('Ingresa una longitud válida'), findsOneWidget);
    });
  });
}
