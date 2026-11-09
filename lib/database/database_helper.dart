import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../config/constants.dart';

/// Única clase que abre y crea la base de datos SQLite local.
///
/// Aquí están todas las instrucciones SQL para que el archivo se pueda
/// explicar de arriba a abajo sin saltar entre varios archivos.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  /// Permite que las pruebas usen una base en memoria (':memory:').
  @visibleForTesting
  static String? databasePathOverride;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final ruta = databasePathOverride ??
        join(await getDatabasesPath(), Constants.dbName);
    return openDatabase(
      ruta,
      version: Constants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Sin esta instrucción, ON DELETE CASCADE no funciona en SQLite.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${Constants.tableUbicaciones} (
        id_ubicacion INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario TEXT NOT NULL,
        nombre TEXT NOT NULL,
        direccion TEXT,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        fecha_creacion TEXT NOT NULL,
        fecha_actualizacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Constants.tableActividades} (
        id_actividad INTEGER PRIMARY KEY AUTOINCREMENT,
        id_ubicacion INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora_inicio TEXT NOT NULL,
        hora_fin TEXT NOT NULL,
        tipo_actividad TEXT NOT NULL,
        estado TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        fecha_actualizacion TEXT NOT NULL,
        FOREIGN KEY (id_ubicacion)
          REFERENCES ${Constants.tableUbicaciones} (id_ubicacion)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Constants.tableHistorial} (
        id_historial INTEGER PRIMARY KEY AUTOINCREMENT,
        id_actividad INTEGER NOT NULL,
        estado_anterior TEXT NOT NULL,
        estado_nuevo TEXT NOT NULL,
        fecha_cambio TEXT NOT NULL,
        comentario TEXT,
        FOREIGN KEY (id_actividad)
          REFERENCES ${Constants.tableActividades} (id_actividad)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Constants.tableCondiciones} (
        id_condicion INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Constants.tableActividadCondicion} (
        id_actividad INTEGER NOT NULL,
        id_condicion INTEGER NOT NULL,
        PRIMARY KEY (id_actividad, id_condicion),
        FOREIGN KEY (id_actividad)
          REFERENCES ${Constants.tableActividades} (id_actividad)
          ON DELETE CASCADE,
        FOREIGN KEY (id_condicion)
          REFERENCES ${Constants.tableCondiciones} (id_condicion)
          ON DELETE CASCADE
      )
    ''');

    await _precargarCondiciones(db);
  }

  /// Catálogo fijo de condiciones climáticas del enunciado.
  Future<void> _precargarCondiciones(Database db) async {
    const condiciones = [
      {'nombre': 'Soleado', 'descripcion': 'Cielo despejado, sol'},
      {'nombre': 'Lluvioso', 'descripcion': 'Lluvia o probabilidad alta de lluvia'},
      {'nombre': 'Nublado', 'descripcion': 'Cielo cubierto'},
      {'nombre': 'Ventoso', 'descripcion': 'Vientos fuertes'},
      {'nombre': 'Templado', 'descripcion': 'Temperatura agradable'},
      {'nombre': 'Nevado', 'descripcion': 'Nieve o temperatura bajo cero'},
    ];
    final batch = db.batch();
    for (final condicion in condiciones) {
      batch.insert(Constants.tableCondiciones, condicion);
    }
    await batch.commit(noResult: true);
  }

  /// En desarrollo no hay datos que conservar: si cambia el esquema se
  /// recrean las tablas (los hijos primero para respetar las llaves foráneas).
  Future<void> _onUpgrade(Database db, int anterior, int nueva) async {
    for (final tabla in [
      Constants.tableActividadCondicion,
      Constants.tableHistorial,
      Constants.tableActividades,
      Constants.tableCondiciones,
      Constants.tableUbicaciones,
    ]) {
      await db.execute('DROP TABLE IF EXISTS $tabla');
    }
    await _onCreate(db, nueva);
  }

  // ---- Operaciones genéricas usadas por los services ----

  Future<int> insert(String tabla, Map<String, Object?> valores) async {
    final db = await database;
    return db.insert(tabla, valores);
  }

  Future<int> update(
    String tabla,
    Map<String, Object?> valores, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(tabla, valores, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String tabla, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(tabla, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, Object?>>> query(
    String tabla, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(
      tabla,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? argumentos,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, argumentos);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
