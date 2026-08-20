import '../../config/constants.dart';
import 'actividades_table.dart';

class HistorialTable {
  HistorialTable._();

  static const String colId = 'id_historial';
  static const String colIdActividad = 'id_actividad';
  static const String colEstadoAnterior = 'estado_anterior';
  static const String colEstadoNuevo = 'estado_nuevo';
  static const String colFechaCambio = 'fecha_cambio';
  static const String colComentario = 'comentario';

  static String get createSql => '''
    CREATE TABLE ${Constants.tableHistorial} (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colIdActividad INTEGER NOT NULL,
      $colEstadoAnterior TEXT NOT NULL,
      $colEstadoNuevo TEXT NOT NULL,
      $colFechaCambio TEXT NOT NULL,
      $colComentario TEXT,
      FOREIGN KEY ($colIdActividad)
        REFERENCES ${Constants.tableActividades} (${ActividadesTable.colId})
        ON DELETE CASCADE
    )
  ''';
}
