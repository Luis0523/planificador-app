import '../config/constants.dart';
import '../database/database_helper.dart';
import '../models/actividad.dart';
import '../models/condicion_climatica.dart';
import '../models/historial_actividad.dart';
import '../utils/date_helpers.dart';

class ActividadService {
  ActividadService._();
  static final ActividadService instance = ActividadService._();

  Future<int> crear(Actividad actividad) => DatabaseHelper.instance.insert(
    Constants.tableActividades,
    actividad.toMap(),
  );

  Future<List<Actividad>> listarPorUbicacion(int idUbicacion) async {
    final filas = await DatabaseHelper.instance.query(
      Constants.tableActividades,
      where: 'id_ubicacion = ?',
      whereArgs: [idUbicacion],
      orderBy: 'fecha ASC, hora_inicio ASC',
    );
    return filas.map(Actividad.fromMap).toList();
  }

  Future<int> actualizar(Actividad actividad) => DatabaseHelper.instance.update(
    Constants.tableActividades,
    actividad.toMap(),
    where: 'id_actividad = ?',
    whereArgs: [actividad.idActividad],
  );

  Future<List<Actividad>> listarPendientes(List<int> idUbicaciones) async {
    if (idUbicaciones.isEmpty) return [];
    final placeholders = List.filled(idUbicaciones.length, '?').join(', ');
    final filas = await DatabaseHelper.instance.query(
      Constants.tableActividades,
      where:
          'id_ubicacion IN ($placeholders) AND estado IN (?, ?) AND fecha >= ?',
      whereArgs: [
        ...idUbicaciones,
        Constants.estadoPendiente,
        Constants.estadoReagendada,
        formatearFecha(DateTime.now()),
      ],
      orderBy: 'fecha ASC, hora_inicio ASC',
    );
    return filas.map(Actividad.fromMap).toList();
  }

  Future<int> eliminar(int idActividad) => DatabaseHelper.instance.delete(
    Constants.tableActividades,
    where: 'id_actividad = ?',
    whereArgs: [idActividad],
  );

  Future<Actividad?> obtenerActividadEnConflicto({
    required int idUbicacion,
    required String fecha,
    required String horaInicio,
    required String horaFin,
    int? idExcluida,
  }) async {
    final filas = await DatabaseHelper.instance.query(
      Constants.tableActividades,
      where: 'id_ubicacion = ? AND fecha = ? AND id_actividad != ?',
      whereArgs: [idUbicacion, fecha, idExcluida ?? -1],
    );
    for (final fila in filas) {
      final otra = Actividad.fromMap(fila);
      if (seCruzan(horaInicio, horaFin, otra.horaInicio, otra.horaFin)) {
        return otra;
      }
    }
    return null;
  }

  static bool seCruzan(String s1, String e1, String s2, String e2) =>
      s1.compareTo(e2) < 0 && s2.compareTo(e1) < 0;

  Future<List<CondicionClimatica>> listarCondiciones() async {
    final filas = await DatabaseHelper.instance.query(
      Constants.tableCondiciones,
      orderBy: 'id_condicion ASC',
    );
    return filas.map(CondicionClimatica.fromMap).toList();
  }

  Future<void> guardarCondiciones(
    int idActividad,
    List<int> idCondiciones,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    batch.delete(
      Constants.tableActividadCondicion,
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
    for (final id in idCondiciones) {
      batch.insert(Constants.tableActividadCondicion, {
        'id_actividad': idActividad,
        'id_condicion': id,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<int>> obtenerCondiciones(int idActividad) async {
    final filas = await DatabaseHelper.instance.query(
      Constants.tableActividadCondicion,
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
    return filas.map((f) => f['id_condicion'] as int).toList();
  }

  Future<Map<int, List<CondicionClimatica>>> condicionesPorActividad(
    List<int> idActividades,
  ) async {
    final resultado = <int, List<CondicionClimatica>>{};
    if (idActividades.isEmpty) return resultado;

    final placeholders = List.filled(idActividades.length, '?').join(', ');
    final pares = await DatabaseHelper.instance.query(
      Constants.tableActividadCondicion,
      where: 'id_actividad IN ($placeholders)',
      whereArgs: idActividades,
    );

    final idsCondiciones = pares
        .map((p) => p['id_condicion'] as int)
        .toSet()
        .toList();
    final condiciones = <int, CondicionClimatica>{};
    if (idsCondiciones.isNotEmpty) {
      final filas = await DatabaseHelper.instance.query(
        Constants.tableCondiciones,
        where:
            'id_condicion IN (${List.filled(idsCondiciones.length, '?').join(', ')})',
        whereArgs: idsCondiciones,
      );
      for (final fila in filas) {
        final c = CondicionClimatica.fromMap(fila);
        condiciones[c.idCondicion!] = c;
      }
    }

    for (final par in pares) {
      final idActividad = par['id_actividad'] as int;
      final idCondicion = par['id_condicion'] as int;
      resultado.putIfAbsent(idActividad, () => []);
      final condicion = condiciones[idCondicion];
      if (condicion != null) resultado[idActividad]!.add(condicion);
    }
    return resultado;
  }

  Future<void> marcarFinalizada(Actividad actividad) async {
    final ahora = DateTime.now().toIso8601String();
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        Constants.tableActividades,
        {'estado': Constants.estadoFinalizada, 'fecha_actualizacion': ahora},
        where: 'id_actividad = ?',
        whereArgs: [actividad.idActividad],
      );
      await txn.insert(
        Constants.tableHistorial,
        HistorialActividad(
          idActividad: actividad.idActividad!,
          estadoAnterior: actividad.estado,
          estadoNuevo: Constants.estadoFinalizada,
          fechaCambio: ahora,
        ).toMap(),
      );
    });
  }

  Future<void> reagendar(
    Actividad actividad, {
    required String nuevaFecha,
    required String nuevaHoraInicio,
    required String nuevaHoraFin,
  }) async {
    final ahora = DateTime.now().toIso8601String();
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        Constants.tableActividades,
        {
          'fecha': nuevaFecha,
          'hora_inicio': nuevaHoraInicio,
          'hora_fin': nuevaHoraFin,
          'estado': Constants.estadoReagendada,
          'fecha_actualizacion': ahora,
        },
        where: 'id_actividad = ?',
        whereArgs: [actividad.idActividad],
      );
      await txn.insert(
        Constants.tableHistorial,
        HistorialActividad(
          idActividad: actividad.idActividad!,
          estadoAnterior: actividad.estado,
          estadoNuevo: Constants.estadoReagendada,
          fechaCambio: ahora,
          comentario: 'Reagendado a $nuevaFecha $nuevaHoraInicio–$nuevaHoraFin',
        ).toMap(),
      );
    });
  }

  Future<List<HistorialActividad>> listarHistorial(int idActividad) async {
    final filas = await DatabaseHelper.instance.query(
      Constants.tableHistorial,
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
      orderBy: 'fecha_cambio DESC',
    );
    return filas.map(HistorialActividad.fromMap).toList();
  }
}
