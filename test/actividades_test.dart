import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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

Future<void> _esperarDB(WidgetTester tester) async {
  for (var i = 0; i < 80; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _flujo(WidgetTester tester, Future<void> Function() cuerpo) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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

Future<void> _crearUbicacion(
  WidgetTester tester, {
  String nombre = 'Parque Central',
}) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('drawer_ubicaciones')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('btn_nueva_ubicacion')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('ubicacion_nombre')), nombre);
  await tester.tap(find.byKey(const Key('btn_mapa')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('mapa_latitud')), '19.4326');
  await tester.enterText(find.byKey(const Key('mapa_longitud')), '-99.1332');
  await tester.tap(find.byKey(const Key('mapa_aceptar')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
  await tester.tap(find.byKey(const Key('ubicacion_guardar')));
  await _esperarDB(tester);
}

Future<void> _abrirActividades(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('drawer_actividades')));
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _elegirFecha(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('actividad_fecha')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _elegirHora(
  WidgetTester tester,
  Key key,
  int hora,
  int minuto,
) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final campos = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(campos.at(0), '$hora');
  await tester.enterText(campos.at(1), '$minuto');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _limpiarSnackBars(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
      .clearSnackBars();
  await tester.pumpAndSettle();
}

Future<void> _crearActividad(
  WidgetTester tester, {
  required String descripcion,
  required int horaIni,
  required int minIni,
  required int horaFin,
  required int minFin,
}) async {
  await tester.tap(find.byKey(const Key('btn_nueva_actividad')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('actividad_nombre')),
    descripcion,
  );
  await _elegirFecha(tester);
  await _elegirHora(
    tester,
    const Key('actividad_hora_inicio'),
    horaIni,
    minIni,
  );
  await _elegirHora(tester, const Key('actividad_hora_fin'), horaFin, minFin);
  await _scrollHasta(tester, find.byKey(const Key('actividad_guardar')));
  await tester.tap(find.byKey(const Key('actividad_guardar')));
  await _esperarDB(tester);
}

Future<void> _scrollHasta(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .ancestor(of: finder, matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(finder, 120, scrollable: scrollable);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('es');
  });

  setUp(() async {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.databasePathOverride = ':memory:';
    FlutterSecureStorage.setMockInitialValues({});
    MockBackend.instance.reset();
    await DatabaseHelper.instance.close();
  });

  testWidgets('crear una actividad y verla en el listado', (tester) async {
    await _flujo(tester, () async {
      await _crearUbicacion(tester);
      await _abrirActividades(tester);

      await _crearActividad(
        tester,
        descripcion: 'Correr en el parque',
        horaIni: 7,
        minIni: 0,
        horaFin: 8,
        minFin: 0,
      );

      expect(find.text('Correr en el parque'), findsOneWidget);
      expect(find.text('Aire libre'), findsOneWidget);
    });
  });

  testWidgets('se rechaza una actividad que se cruza de horario', (
    tester,
  ) async {
    await _flujo(tester, () async {
      await _crearUbicacion(tester);
      await _abrirActividades(tester);

      await _crearActividad(
        tester,
        descripcion: 'Correr',
        horaIni: 7,
        minIni: 0,
        horaFin: 8,
        minFin: 0,
      );
      expect(find.text('Correr'), findsOneWidget);
      expect(find.text('Crear actividad'), findsNothing);
      await _limpiarSnackBars(tester);

      await _crearActividad(
        tester,
        descripcion: 'Reunión',
        horaIni: 7,
        minIni: 30,
        horaFin: 8,
        minFin: 30,
      );

      expect(find.textContaining('Se cruza con "Correr"'), findsOneWidget);
      expect(find.text('Crear actividad'), findsOneWidget);
    });
  });

  testWidgets('se permite una actividad sin cruce', (tester) async {
    await _flujo(tester, () async {
      await _crearUbicacion(tester);
      await _abrirActividades(tester);

      await _crearActividad(
        tester,
        descripcion: 'Correr',
        horaIni: 7,
        minIni: 0,
        horaFin: 8,
        minFin: 0,
      );
      await _crearActividad(
        tester,
        descripcion: 'Desayuno',
        horaIni: 9,
        minIni: 0,
        horaFin: 10,
        minFin: 0,
      );

      expect(find.text('Correr'), findsOneWidget);
      expect(find.text('Desayuno'), findsOneWidget);
    });
  });

  testWidgets('editar una actividad persiste el cambio', (tester) async {
    await _flujo(tester, () async {
      await _crearUbicacion(tester);
      await _abrirActividades(tester);

      await _crearActividad(
        tester,
        descripcion: 'Correr',
        horaIni: 7,
        minIni: 0,
        horaFin: 8,
        minFin: 0,
      );

      await tester.tap(find.text('Correr'));
      await tester.pumpAndSettle();
      expect(find.text('Editar actividad'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('actividad_nombre')),
        'Correr 10 km',
      );
      await _scrollHasta(tester, find.byKey(const Key('actividad_guardar')));
      await tester.tap(find.byKey(const Key('actividad_guardar')));
      await _esperarDB(tester);

      expect(find.text('Correr 10 km'), findsOneWidget);
      expect(find.text('Correr'), findsNothing);
    });
  });

  testWidgets('eliminar una actividad pide confirmación y la borra', (
    tester,
  ) async {
    await _flujo(tester, () async {
      await _crearUbicacion(tester);
      await _abrirActividades(tester);

      await _crearActividad(
        tester,
        descripcion: 'A Eliminar',
        horaIni: 7,
        minIni: 0,
        horaFin: 8,
        minFin: 0,
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await _esperarDB(tester);

      expect(find.text('A Eliminar'), findsNothing);
      expect(find.text('Aún no tienes actividades'), findsOneWidget);
    });
  });

  testWidgets('validación: hora de fin no puede ser antes de inicio', (
    tester,
  ) async {
    await _flujo(tester, () async {
      await _crearUbicacion(tester);
      await _abrirActividades(tester);

      await tester.tap(find.byKey(const Key('btn_nueva_actividad')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('actividad_nombre')),
        'Actividad',
      );
      await _elegirFecha(tester);
      await _elegirHora(tester, const Key('actividad_hora_inicio'), 8, 0);
      await _elegirHora(tester, const Key('actividad_hora_fin'), 7, 0);

      await _scrollHasta(tester, find.byKey(const Key('actividad_guardar')));
      await tester.tap(find.byKey(const Key('actividad_guardar')));
      await tester.pumpAndSettle();

      expect(
        find.text('La hora de fin debe ser posterior a la de inicio'),
        findsOneWidget,
      );
    });
  });

  testWidgets('crear el primer evento creando la ubicación al vuelo', (
    tester,
  ) async {
    await _flujo(tester, () async {
      await tester.tap(find.byKey(const Key('fab_nueva_actividad')));
      await tester.pumpAndSettle();
      expect(find.text('Nueva actividad'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_nueva_ubicacion_inline')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('ubicacion_nombre')),
        'Mi lugar',
      );
      await tester.tap(find.byKey(const Key('btn_mapa')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('mapa_latitud')), '19.4326');
      await tester.enterText(
        find.byKey(const Key('mapa_longitud')),
        '-99.1332',
      );
      await tester.tap(find.byKey(const Key('mapa_aceptar')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('ubicacion_guardar')));
      await tester.tap(find.byKey(const Key('ubicacion_guardar')));
      await _esperarDB(tester);

      expect(find.text('Nueva actividad'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('actividad_nombre')),
        'Primer planazo',
      );
      await _elegirFecha(tester);
      await _elegirHora(tester, const Key('actividad_hora_inicio'), 8, 0);
      await _elegirHora(tester, const Key('actividad_hora_fin'), 9, 0);
      await _scrollHasta(tester, find.byKey(const Key('actividad_guardar')));
      await tester.tap(find.byKey(const Key('actividad_guardar')));
      await _esperarDB(tester);

      expect(find.text('Primer planazo'), findsOneWidget);
    });
  });
}
