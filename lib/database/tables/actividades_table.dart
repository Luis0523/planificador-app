import '../../config/constants.dart';
import 'ubicaciones_table.dart';

class ActividadesTable {
  ActividadesTable._();

  static const String colId = 'id_actividad';
  static const String colIdUbicacion = 'id_ubicacion';
  static const String colDescripcion = 'descripcion';
  static const String colFecha = 'fecha';
  static const String colHoraInicio = 'hora_inicio';
  static const String colHoraFin = 'hora_fin';
  static const String colTipoActividad = 'tipo_actividad';
  static const String colEstado = 'estado';
  static const String colFechaCreacion = 'fecha_creacion';
  static const String colFechaActualizacion = 'fecha_actualizacion';

  static String get createSql => '''
    CREATE TABLE ${Constants.tableActividades} (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colIdUbicacion INTEGER NOT NULL,
      $colDescripcion TEXT NOT NULL,
      $colFecha TEXT NOT NULL,
      $colHoraInicio TEXT NOT NULL,
      $colHoraFin TEXT NOT NULL,
      $colTipoActividad TEXT NOT NULL,
      $colEstado TEXT NOT NULL,
      $colFechaCreacion TEXT NOT NULL,
      $colFechaActualizacion TEXT NOT NULL,
      FOREIGN KEY ($colIdUbicacion)
        REFERENCES ${Constants.tableUbicaciones} (${UbicacionesTable.colId})
        ON DELETE CASCADE
    )
  ''';
}
