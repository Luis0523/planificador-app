import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:planificador_actividades/config/constants.dart';
import 'package:planificador_actividades/database/database_helper.dart';
import 'package:planificador_actividades/models/actividad.dart';
import 'package:planificador_actividades/services/actividad_service.dart';
import 'package:planificador_actividades/services/probabilidad_service.dart';

String _ahora() => DateTime.now().toIso8601String();

Actividad _actividad({
  required int idUbicacion,
  String descripcion = 'Test actividad',
  String fecha = '2099-01-15',
  String horaInicio = '09:00',
  String horaFin = '10:00',
  String tipo = 'aire_libre',
  String estado = 'pendiente',
}) => Actividad(
  idUbicacion: idUbicacion,
  descripcion: descripcion,
  fecha: fecha,
  horaInicio: horaInicio,
  horaFin: horaFin,
  tipoActividad: tipo,
  estado: estado,
  fechaCreacion: _ahora(),
  fechaActualizacion: _ahora(),
);

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.databasePathOverride = ':memory:';
    DatabaseHelper.instance.close();
  });

  tearDown(() => DatabaseHelper.instance.close());

  group('ProbabilidadService', () {
    final service = ProbabilidadService.instance;

    test('aire_libre + condicion deseada = Alta', () {
      expect(
        service.calcular(
          tipoActividad: 'aire_libre',
          condicionesDeseables: ['Soleado', 'Templado'],
          condicionReal: 'Soleado',
        ),
        ProbabilidadNivel.alta,
      );
    });

    test('aire_libre + Lluvioso no deseado = Baja', () {
      expect(
        service.calcular(
          tipoActividad: 'aire_libre',
          condicionesDeseables: ['Soleado'],
          condicionReal: 'Lluvioso',
        ),
        ProbabilidadNivel.baja,
      );
    });

    test('aire_libre + Nevado no deseado = Baja', () {
      expect(
        service.calcular(
          tipoActividad: 'aire_libre',
          condicionesDeseables: ['Soleado'],
          condicionReal: 'Nevado',
        ),
        ProbabilidadNivel.baja,
      );
    });

    test('aire_libre + Ventoso no deseado = Baja', () {
      expect(
        service.calcular(
          tipoActividad: 'aire_libre',
          condicionesDeseables: ['Soleado'],
          condicionReal: 'Ventoso',
        ),
        ProbabilidadNivel.baja,
      );
    });

    test('aire_libre + condicion neutra no deseada = Media', () {
      expect(
        service.calcular(
          tipoActividad: 'aire_libre',
          condicionesDeseables: ['Soleado'],
          condicionReal: 'Nublado',
        ),
        ProbabilidadNivel.media,
      );
    });

    test('interior + Lluvioso no deseado = Media', () {
      expect(
        service.calcular(
          tipoActividad: 'interior',
          condicionesDeseables: ['Soleado'],
          condicionReal: 'Lluvioso',
        ),
        ProbabilidadNivel.media,
      );
    });

    test('interior + condicion deseada = Alta', () {
      expect(
        service.calcular(
          tipoActividad: 'interior',
          condicionesDeseables: ['Templado'],
          condicionReal: 'Templado',
        ),
        ProbabilidadNivel.alta,
      );
    });

    test('sin condiciones deseables + adversa = Baja', () {
      expect(
        service.calcular(
          tipoActividad: 'aire_libre',
          condicionesDeseables: [],
          condicionReal: 'Lluvioso',
        ),
        ProbabilidadNivel.baja,
      );
    });

    test('sin condiciones deseables + neutra = Media', () {
      expect(
        service.calcular(
          tipoActividad: 'aire_libre',
          condicionesDeseables: [],
          condicionReal: 'Templado',
        ),
        ProbabilidadNivel.media,
      );
    });
  });

  group('ActividadService historial', () {
    test('marcarFinalizada actualiza estado e inserta en historial', () async {
      final db = await DatabaseHelper.instance.database;
      final service = ActividadService.instance;

      final idUb = await db.insert(Constants.tableUbicaciones, {
        'id_usuario': 'u1',
        'nombre': 'Ubi',
        'latitud': 14.0,
        'longitud': -90.0,
        'fecha_creacion': _ahora(),
        'fecha_actualizacion': _ahora(),
      });

      final idAct = await service.crear(_actividad(idUbicacion: idUb));
      final actividad = (await service.listarPorUbicacion(idUb))
          .firstWhere((a) => a.idActividad == idAct);

      await service.marcarFinalizada(actividad);

      final filas = await db.query(
        Constants.tableActividades,
        where: 'id_actividad = ?',
        whereArgs: [idAct],
      );
      expect(filas.first['estado'], Constants.estadoFinalizada);

      final historial = await service.listarHistorial(idAct);
      expect(historial, hasLength(1));
      expect(historial.first.estadoAnterior, Constants.estadoPendiente);
      expect(historial.first.estadoNuevo, Constants.estadoFinalizada);
    });

    test(
      'reagendar actualiza fecha/horas/estado e inserta en historial',
      () async {
        final db = await DatabaseHelper.instance.database;
        final service = ActividadService.instance;

        final idUb = await db.insert(Constants.tableUbicaciones, {
          'id_usuario': 'u1',
          'nombre': 'Ubi',
          'latitud': 14.0,
          'longitud': -90.0,
          'fecha_creacion': _ahora(),
          'fecha_actualizacion': _ahora(),
        });

        final idAct = await service.crear(_actividad(idUbicacion: idUb));
        final actividad = (await service.listarPorUbicacion(idUb))
            .firstWhere((a) => a.idActividad == idAct);

        await service.reagendar(
          actividad,
          nuevaFecha: '2099-03-20',
          nuevaHoraInicio: '14:00',
          nuevaHoraFin: '15:30',
        );

        final filas = await db.query(
          Constants.tableActividades,
          where: 'id_actividad = ?',
          whereArgs: [idAct],
        );
        expect(filas.first['fecha'], '2099-03-20');
        expect(filas.first['hora_inicio'], '14:00');
        expect(filas.first['hora_fin'], '15:30');
        expect(filas.first['estado'], Constants.estadoReagendada);

        final historial = await service.listarHistorial(idAct);
        expect(historial, hasLength(1));
        expect(historial.first.estadoAnterior, Constants.estadoPendiente);
        expect(historial.first.estadoNuevo, Constants.estadoReagendada);
        expect(historial.first.comentario, isNotNull);
      },
    );

    test('historial acumula cambios en orden descendente', () async {
      final db = await DatabaseHelper.instance.database;
      final service = ActividadService.instance;

      final idUb = await db.insert(Constants.tableUbicaciones, {
        'id_usuario': 'u1',
        'nombre': 'Ubi',
        'latitud': 14.0,
        'longitud': -90.0,
        'fecha_creacion': _ahora(),
        'fecha_actualizacion': _ahora(),
      });

      final idAct = await service.crear(_actividad(idUbicacion: idUb));
      var actividad = (await service.listarPorUbicacion(idUb))
          .firstWhere((a) => a.idActividad == idAct);

      await service.reagendar(
        actividad,
        nuevaFecha: '2099-02-01',
        nuevaHoraInicio: '10:00',
        nuevaHoraFin: '11:00',
      );

      actividad = (await service.listarPorUbicacion(idUb))
          .firstWhere((a) => a.idActividad == idAct);

      await service.marcarFinalizada(actividad);

      final historial = await service.listarHistorial(idAct);
      expect(historial, hasLength(2));
      expect(historial.first.estadoNuevo, Constants.estadoFinalizada);
      expect(historial.last.estadoNuevo, Constants.estadoReagendada);
    });
  });

  group('ActividadService.listarPendientes', () {
    test('solo devuelve actividades pendiente y reagendada', () async {
      final db = await DatabaseHelper.instance.database;
      final service = ActividadService.instance;

      final idUb = await db.insert(Constants.tableUbicaciones, {
        'id_usuario': 'u1',
        'nombre': 'Ubi',
        'latitud': 14.0,
        'longitud': -90.0,
        'fecha_creacion': _ahora(),
        'fecha_actualizacion': _ahora(),
      });

      await service.crear(
        _actividad(
          idUbicacion: idUb,
          descripcion: 'Pendiente',
          estado: 'pendiente',
        ),
      );
      await service.crear(
        _actividad(
          idUbicacion: idUb,
          descripcion: 'Reagendada',
          estado: 'reagendada',
        ),
      );
      await service.crear(
        _actividad(
          idUbicacion: idUb,
          descripcion: 'Finalizada',
          estado: 'finalizada',
        ),
      );

      final pendientes = await service.listarPendientes([idUb]);
      expect(pendientes, hasLength(2));
      expect(pendientes.map((a) => a.descripcion).toSet(), {
        'Pendiente',
        'Reagendada',
      });
    });

    test('devuelve vacio si no hay ubicaciones', () async {
      final pendientes = await ActividadService.instance.listarPendientes([]);
      expect(pendientes, isEmpty);
    });

    test('no devuelve actividades de fechas pasadas', () async {
      final db = await DatabaseHelper.instance.database;
      final service = ActividadService.instance;

      final idUb = await db.insert(Constants.tableUbicaciones, {
        'id_usuario': 'u1',
        'nombre': 'Ubi',
        'latitud': 14.0,
        'longitud': -90.0,
        'fecha_creacion': _ahora(),
        'fecha_actualizacion': _ahora(),
      });

      await service.crear(
        _actividad(
          idUbicacion: idUb,
          descripcion: 'Pasada',
          fecha: '2000-01-01',
        ),
      );
      await service.crear(
        _actividad(
          idUbicacion: idUb,
          descripcion: 'Futura',
          fecha: '2099-01-15',
        ),
      );

      final pendientes = await service.listarPendientes([idUb]);
      expect(pendientes.map((a) => a.descripcion), ['Futura']);
    });

    test('devuelve vacio si todas las actividades estan finalizadas', () async {
      final db = await DatabaseHelper.instance.database;
      final service = ActividadService.instance;

      final idUb = await db.insert(Constants.tableUbicaciones, {
        'id_usuario': 'u1',
        'nombre': 'Ubi',
        'latitud': 14.0,
        'longitud': -90.0,
        'fecha_creacion': _ahora(),
        'fecha_actualizacion': _ahora(),
      });

      await service.crear(
        _actividad(idUbicacion: idUb, descripcion: 'A', estado: 'finalizada'),
      );
      await service.crear(
        _actividad(idUbicacion: idUb, descripcion: 'B', estado: 'finalizada'),
      );

      final pendientes = await service.listarPendientes([idUb]);
      expect(pendientes, isEmpty);
    });
  });
}
