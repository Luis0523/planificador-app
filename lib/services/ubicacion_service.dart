import '../config/constants.dart';
import '../database/database_helper.dart';
import '../models/ubicacion.dart';

class UbicacionService {
  UbicacionService._();
  static final UbicacionService instance = UbicacionService._();

  Future<int> crear(Ubicacion ubicacion) => DatabaseHelper.instance.insert(
    Constants.tableUbicaciones,
    ubicacion.toMap(),
  );

  Future<List<Ubicacion>> listar(String idUsuario) async {
    final filas = await DatabaseHelper.instance.query(
      Constants.tableUbicaciones,
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha_creacion DESC',
    );
    return filas.map(Ubicacion.fromMap).toList();
  }

  Future<int> actualizar(Ubicacion ubicacion) => DatabaseHelper.instance.update(
    Constants.tableUbicaciones,
    ubicacion.toMap(),
    where: 'id_ubicacion = ?',
    whereArgs: [ubicacion.idUbicacion],
  );

  Future<int> eliminar(int idUbicacion) => DatabaseHelper.instance.delete(
    Constants.tableUbicaciones,
    where: 'id_ubicacion = ?',
    whereArgs: [idUbicacion],
  );
}
