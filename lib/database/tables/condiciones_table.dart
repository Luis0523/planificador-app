import '../../config/constants.dart';
import 'actividades_table.dart';

class CondicionesTable {
  CondicionesTable._();

  static const String colId = 'id_condicion';
  static const String colNombre = 'nombre';
  static const String colDescripcion = 'descripcion';

  static String get createSql => '''
    CREATE TABLE ${Constants.tableCondiciones} (
      $colId INTEGER PRIMARY KEY AUTOINCREMENT,
      $colNombre TEXT NOT NULL,
      $colDescripcion TEXT
    )
  ''';

  /// Catálogo precargado en el onCreate (spec, sección 4).
  static final List<Map<String, Object?>> seed = [
    {'nombre': 'Soleado', 'descripcion': 'Cielo despejado, sol'},
    {'nombre': 'Lluvioso', 'descripcion': 'Lluvia o probabilidad alta de lluvia'},
    {'nombre': 'Nublado', 'descripcion': 'Cielo cubierto'},
    {'nombre': 'Ventoso', 'descripcion': 'Vientos fuertes'},
    {'nombre': 'Templado', 'descripcion': 'Temperatura agradable, sin extremos'},
    {'nombre': 'Nevado', 'descripcion': 'Nieve o temperatura bajo cero'},
  ];
}

/// Relación N:M entre actividades y condiciones climáticas deseables.
class ActividadCondicionTable {
  ActividadCondicionTable._();

  static const String colIdActividad = 'id_actividad';
  static const String colIdCondicion = 'id_condicion';

  static String get createSql => '''
    CREATE TABLE ${Constants.tableActividadCondicion} (
      $colIdActividad INTEGER NOT NULL,
      $colIdCondicion INTEGER NOT NULL,
      PRIMARY KEY ($colIdActividad, $colIdCondicion),
      FOREIGN KEY ($colIdActividad)
        REFERENCES ${Constants.tableActividades} (${ActividadesTable.colId})
        ON DELETE CASCADE,
      FOREIGN KEY ($colIdCondicion)
        REFERENCES ${Constants.tableCondiciones} (${CondicionesTable.colId})
        ON DELETE CASCADE
    )
  ''';
}
