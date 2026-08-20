import '../../config/constants.dart';

class UbicacionesTable {
  UbicacionesTable._();

  static const String colId = 'id_ubicacion';
  static const String colIdUsuario = 'id_usuario';
  static const String colNombre = 'nombre';
  static const String colDireccion = 'direccion';
  static const String colLatitud = 'latitud';
  static const String colLongitud = 'longitud';
  static const String colFechaCreacion = 'fecha_creacion';
  static const String colFechaActualizacion = 'fecha_actualizacion';

  static String get createSql => '''
    CREATE TABLE ${Constants.tableUbicaciones} (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colIdUsuario INTEGER NOT NULL,
      $colNombre TEXT NOT NULL,
      $colDireccion TEXT,
      $colLatitud REAL NOT NULL,
      $colLongitud REAL NOT NULL,
      $colFechaCreacion TEXT NOT NULL,
      $colFechaActualizacion TEXT NOT NULL
    )
  ''';
}
