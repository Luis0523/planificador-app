import '../config/constants.dart';
import '../database/database_helper.dart';
import '../models/ubicacion.dart';

/// CRUD local (SQLite) de ubicaciones.
class UbicacionService {
  UbicacionService._();
  static final UbicacionService instance = UbicacionService._();

  Future<int> crear(Ubicacion ubicacion) =>
      DatabaseHelper.instance.insert(Constants.tableUbicaciones, ubicacion.toMap());

  Future<List<Ubicacion>> listar(int idUsuario) async {
    final filas = await DatabaseHelper.instance.query(
      Constants.tableUbicaciones,
      where: '${'id_usuario'} = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha_creacion DESC',
    );
    return filas.map(Ubicacion.fromMap).toList();
  }

  Future<int> actualizar(Ubicacion ubicacion) =>
      DatabaseHelper.instance.update(
        Constants.tableUbicaciones,
        ubicacion.toMap(),
        where: 'id_ubicacion = ?',
        whereArgs: [ubicacion.idUbicacion],
      );

  /// Elimina la ubicación; sus actividades se borran en cascada (FK ON DELETE CASCADE).
  Future<int> eliminar(int idUbicacion) => DatabaseHelper.instance.delete(
        Constants.tableUbicaciones,
        where: 'id_ubicacion = ?',
        whereArgs: [idUbicacion],
      );
}
