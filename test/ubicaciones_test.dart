import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:planificador_actividades/database/database_helper.dart';
import 'package:planificador_actividades/main.dart';
import 'package:planificador_actividades/services/mock_backend.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login_correo')),
    'demo@planificador.com',
  );
  await tester.enterText(find.byKey(const Key('login_contrasena')), '123456');
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

Future<void> _irAUbicaciones(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('drawer_ubicaciones')));
  await tester.pumpAndSettle();
}

Future<void> _abrirFormulario(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('btn_nueva_ubicacion')));
  await tester.pumpAndSettle();
}

Future<void> _limpiarSnackBars(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
      .clearSnackBars();
  await tester.pumpAndSettle();
}

Future<void> _elegirPuntoEnMapa(
  WidgetTester tester, {
  String lat = '19.4326',
  String lon = '-99.1332',
}) async {
  await tester.tap(find.byKey(const Key('btn_mapa')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('mapa_latitud')), lat);
  await tester.enterText(find.byKey(const Key('mapa_longitud')), lon);
  await tester.tap(find.byKey(const Key('mapa_aceptar')));
  await tester.pumpAndSettle();
}

Future<void> _esperarDB(WidgetTester tester) async {
  for (var i = 0; i < 80; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _flujo(WidgetTester tester, Future<void> Function() cuerpo) async {
  await tester.runAsync(() async {
    await DatabaseHelper.instance.database;
    await tester.pumpWidget(const PlanificadorApp());
    await tester.pumpAndSettle();
    await _login(tester);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await cuerpo();
  });
}

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.databasePathOverride = ':memory:';
    FlutterSecureStorage.setMockInitialValues({});
    MockBackend.instance.reset();
    await DatabaseHelper.instance.close();
  });

  testWidgets('crear una ubicación y verla en el listado', (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);

      expect(find.text('Aún no tienes ubicaciones'), findsOneWidget);

      await _abrirFormulario(tester);
      await tester.enterText(
        find.byKey(const Key('ubicacion_nombre')),
        'Parque Central',
      );
      await tester.enterText(
        find.byKey(const Key('ubicacion_direccion')),
        'Centro',
      );
      await _elegirPuntoEnMapa(tester);
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('Parque Central'), findsOneWidget);
      expect(find.text('Aún no tienes ubicaciones'), findsNothing);
    });
  });

  testWidgets('si el GPS falla avisa y permite elegir el mapa', (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);
      await _abrirFormulario(tester);

      await tester.tap(find.byKey(const Key('btn_gps')));
      await _esperarDB(tester);
      expect(
        find.textContaining('No se pudo obtener tu ubicación'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ubicacion_sin_punto')), findsOneWidget);
      await _limpiarSnackBars(tester);

      await tester.enterText(
        find.byKey(const Key('ubicacion_nombre')),
        'Desde mapa',
      );
      await _elegirPuntoEnMapa(tester);
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('Desde mapa'), findsOneWidget);
    });
  });

  testWidgets('seleccionar en mapa (mock) llena las coordenadas', (
    tester,
  ) async {
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
        find.byKey(const Key('ubicacion_punto_seleccionado')),
        findsOneWidget,
      );
      expect(find.textContaining('20.5000'), findsWidgets);
      expect(find.textContaining('-100.5000'), findsWidgets);
    });
  });

  testWidgets('editar una ubicación persiste el cambio', (tester) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);

      await _abrirFormulario(tester);
      await tester.enterText(
        find.byKey(const Key('ubicacion_nombre')),
        'Parque Central',
      );
      await _elegirPuntoEnMapa(tester);
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      await tester.tap(find.text('Parque Central'));
      await tester.pumpAndSettle();
      expect(find.text('Editar ubicación'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('ubicacion_nombre')),
        'Parque Renombrado',
      );
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('Parque Renombrado'), findsOneWidget);
      expect(find.text('Parque Central'), findsNothing);
    });
  });

  testWidgets('eliminar una ubicación pide confirmación y la borra', (
    tester,
  ) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);

      await _abrirFormulario(tester);
      await tester.enterText(
        find.byKey(const Key('ubicacion_nombre')),
        'A Eliminar',
      );
      await _elegirPuntoEnMapa(tester, lat: '19.0', lon: '-99.0');
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('También se eliminarán las actividades'),
        findsOneWidget,
      );

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

  testWidgets('validación: nombre obligatorio y punto sin seleccionar', (
    tester,
  ) async {
    await _flujo(tester, () async {
      await _irAUbicaciones(tester);
      await _abrirFormulario(tester);

      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);
      expect(find.text('El nombre es obligatorio'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('ubicacion_nombre')),
        'Sin punto',
      );
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Selecciona el punto en el mapa o usa tu ubicación.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ubicacion_guardar')), findsOneWidget);
    });
  });
}
