import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:planificador_actividades/config/constants.dart';
import 'package:planificador_actividades/database/database_helper.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() {
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() => DatabaseHelper.instance.close());

  test('Fase 1: las 5 tablas se crean y el catálogo de condiciones se precarga',
      () async {
    final db = await DatabaseHelper.instance.database;

    final tablas = await db.query('sqlite_master', columns: ['name']);
    final nombres = tablas.map((t) => t['name']).toSet();

    expect(nombres, contains(Constants.tableUbicaciones));
    expect(nombres, contains(Constants.tableActividades));
    expect(nombres, contains(Constants.tableHistorial));
    expect(nombres, contains(Constants.tableCondiciones));
    expect(nombres, contains(Constants.tableActividadCondicion));

    final condiciones =
        await db.query(Constants.tableCondiciones, orderBy: 'id_condicion');
    expect(condiciones, hasLength(6));
    expect(condiciones.map((c) => c['nombre']),
        containsAll(['Soleado', 'Lluvioso', 'Nublado', 'Ventoso', 'Templado', 'Nevado']));
  });

  test('Fase 1: insertar ubicación + actividad + condiciones, y borrado en cascada',
      () async {
    final db = await DatabaseHelper.instance.database;

    final idUbicacion = await db.insert(Constants.tableUbicaciones, {
      'id_usuario': 1,
      'nombre': 'Parque Central',
      'direccion': 'Centro',
      'latitud': 19.4326,
      'longitud': -99.1332,
      'fecha_creacion': '2026-08-20T10:00:00',
      'fecha_actualizacion': '2026-08-20T10:00:00',
    });

    final idActividad = await db.insert(Constants.tableActividades, {
      'id_ubicacion': idUbicacion,
      'descripcion': 'Correr 5km',
      'fecha': '2026-08-25',
      'hora_inicio': '07:00',
      'hora_fin': '08:00',
      'tipo_actividad': 'aire_libre',
      'estado': 'pendiente',
      'fecha_creacion': '2026-08-20T10:05:00',
      'fecha_actualizacion': '2026-08-20T10:05:00',
    });

    // Relación N:M: asociar condiciones deseables
    final idSoleado =
        (await db.query(Constants.tableCondiciones, where: "nombre = 'Soleado'"))
            .single['id_condicion'] as int;
    final idTemplado =
        (await db.query(Constants.tableCondiciones, where: "nombre = 'Templado'"))
            .single['id_condicion'] as int;

    await db.insert(Constants.tableActividadCondicion,
        {'id_actividad': idActividad, 'id_condicion': idSoleado});
    await db.insert(Constants.tableActividadCondicion,
        {'id_actividad': idActividad, 'id_condicion': idTemplado});

    // Historial de la actividad
    await db.insert(Constants.tableHistorial, {
      'id_actividad': idActividad,
      'estado_anterior': 'pendiente',
      'estado_nuevo': 'finalizada',
      'fecha_cambio': '2026-08-25T08:30:00',
      'comentario': 'Prueba',
    });

    // Verificar que todo quedó insertado
    expect(
        await db.query(Constants.tableActividades), hasLength(1),
        reason: 'la actividad debe existir');
    expect(
        await db.query(Constants.tableActividadCondicion), hasLength(2),
        reason: 'la actividad debe tener 2 condiciones asociadas');
    expect(
        await db.query(Constants.tableHistorial), hasLength(1),
        reason: 'el historial debe tener 1 registro');

    // Borrado en cascada: al borrar la ubicación, la actividad,
    // sus condiciones asociadas y su historial deben desaparecer.
    await db.delete(Constants.tableUbicaciones,
        where: 'id_ubicacion = ?', whereArgs: [idUbicacion]);

    expect(
        await db.query(Constants.tableActividades), isEmpty,
        reason: 'ON DELETE CASCADE debe borrar las actividades de la ubicación');
    expect(
        await db.query(Constants.tableActividadCondicion), isEmpty,
        reason: 'las condiciones asociadas deben borrarse en cascada');
    expect(
        await db.query(Constants.tableHistorial), isEmpty,
        reason: 'el historial debe borrarse en cascada');
  });
}
