import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../config/constants.dart';
import 'tables/actividades_table.dart';
import 'tables/condiciones_table.dart';
import 'tables/historial_table.dart';
import 'tables/ubicaciones_table.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, Constants.dbName),
      version: Constants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  /// Se ejecuta en cada conexión abierta. Sin esto, ON DELETE CASCADE no funciona.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(UbicacionesTable.createSql);
    await db.execute(ActividadesTable.createSql);
    await db.execute(HistorialTable.createSql);
    await db.execute(CondicionesTable.createSql);
    await db.execute(ActividadCondicionTable.createSql);

    await _precargarCondiciones(db);
  }

  Future<void> _precargarCondiciones(Database db) async {
    final batch = db.batch();
    for (final condicion in CondicionesTable.seed) {
      batch.insert(Constants.tableCondiciones, condicion);
    }
    await batch.commit(noResult: true);
  }

  // ---- Métodos genéricos usados por los services ----

  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
