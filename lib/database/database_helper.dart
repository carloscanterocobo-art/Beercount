import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/beer_type.dart';
import '../models/consumption.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  static const int _databaseVersion = 2;

  /// Devuelve la instancia de la base de datos.
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Abre o crea la base de datos local.
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return databaseFactoryFfiWeb.openDatabase(
        'beercount.db',
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: _createDatabase,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'beercount.db');

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea todas las tablas de la aplicación.
  Future<void> _createDatabase(Database db, int version) async {
    await _createBeerTypesTable(db);
    await _insertDefaultBeerTypes(db);

    await db.execute('''
      CREATE TABLE consumptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        beer_type_id INTEGER NOT NULL,
        date_time TEXT NOT NULL,
        price_cents INTEGER,
        FOREIGN KEY (beer_type_id)
          REFERENCES beer_types (id)
      )
    ''');

    await _createSettingsTable(db);
  }

  /// Crea el catálogo de tipos de bebida.
  Future<void> _createBeerTypesTable(Database db) async {
    await db.execute('''
      CREATE TABLE beer_types (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        volume_ml INTEGER NOT NULL,
        is_beer INTEGER NOT NULL CHECK (is_beer IN (0, 1))
      )
    ''');
  }

  /// Introduce los seis tipos de bebida predefinidos.
  Future<void> _insertDefaultBeerTypes(Database db) async {
    final beerTypes = [
      {'id': 1, 'name': 'Caña', 'volume_ml': 250, 'is_beer': 1},
      {'id': 2, 'name': 'Botellín', 'volume_ml': 250, 'is_beer': 1},
      {'id': 3, 'name': 'Tercio', 'volume_ml': 330, 'is_beer': 1},
      {'id': 4, 'name': 'Jarra', 'volume_ml': 500, 'is_beer': 1},
      {'id': 5, 'name': 'Litro', 'volume_ml': 1000, 'is_beer': 1},
      {'id': 6, 'name': 'Cubata', 'volume_ml': 500, 'is_beer': 0},
    ];

    for (final beerType in beerTypes) {
      await db.insert('beer_types', beerType);
    }
  }

  /// Crea la tabla de preferencias.
  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.insert('settings', {'key': 'economic_tracking', 'value': 'false'});
  }

  /// Actualiza una base de datos de una versión anterior.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBeerTypesTable(db);
      await _insertDefaultBeerTypes(db);
    }
  }

  // --------------------------------------------------
  // TIPOS DE BEBIDA
  // --------------------------------------------------

  /// Devuelve los seis tipos de bebida disponibles.
  Future<List<BeerType>> getBeerTypes() async {
    final db = await database;

    final result = await db.query('beer_types', orderBy: 'id ASC');

    return result.map((map) => BeerType.fromMap(map)).toList();
  }

  // --------------------------------------------------
  // CONSUMICIONES
  // --------------------------------------------------

  /// Registra una consumición y devuelve su identificador.
  Future<int> insertConsumption(Consumption consumption) async {
    final db = await database;

    return db.insert('consumptions', consumption.toMap()..remove('id'));
  }

  /// Devuelve todas las consumiciones, de más reciente a más antigua.
  Future<List<Consumption>> getAllConsumptions() async {
    final db = await database;

    final result = await db.query(
      'consumptions',
      orderBy: 'date_time DESC, id DESC',
    );

    return result.map((map) => Consumption.fromMap(map)).toList();
  }

  /// Devuelve las consumiciones de un tipo de bebida.
  Future<List<Consumption>> getConsumptionsByBeerType(int beerTypeId) async {
    final db = await database;

    final result = await db.query(
      'consumptions',
      where: 'beer_type_id = ?',
      whereArgs: [beerTypeId],
      orderBy: 'date_time DESC, id DESC',
    );

    return result.map((map) => Consumption.fromMap(map)).toList();
  }

  /// Elimina la última consumición de un tipo de bebida.
  Future<bool> deleteLatestConsumption(int beerTypeId) async {
    final db = await database;

    final result = await db.query(
      'consumptions',
      columns: ['id'],
      where: 'beer_type_id = ?',
      whereArgs: [beerTypeId],
      orderBy: 'date_time DESC, id DESC',
      limit: 1,
    );

    if (result.isEmpty) return false;

    await db.delete(
      'consumptions',
      where: 'id = ?',
      whereArgs: [result.first['id']],
    );

    return true;
  }

  /// Modifica una consumición existente.
  Future<int> updateConsumption(Consumption consumption) async {
    if (consumption.id == null) {
      throw ArgumentError('La consumición debe tener un identificador.');
    }

    final db = await database;

    final values = consumption.toMap()..remove('id');

    return db.update(
      'consumptions',
      values,
      where: 'id = ?',
      whereArgs: [consumption.id],
    );
  }

  /// Elimina una consumición por su identificador.
  Future<int> deleteConsumption(int id) async {
    final db = await database;

    return db.delete('consumptions', where: 'id = ?', whereArgs: [id]);
  }

  /// Devuelve el número de consumiciones de cada tipo.
  Future<Map<int, int>> getConsumptionCounts() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT beer_type_id, COUNT(*) AS total
      FROM consumptions
      GROUP BY beer_type_id
    ''');

    final counts = <int, int>{};

    for (final row in result) {
      counts[row['beer_type_id'] as int] = row['total'] as int;
    }

    return counts;
  }

  // --------------------------------------------------
  // CONFIGURACIÓN
  // --------------------------------------------------

  /// Consulta si el seguimiento económico está activado.
  Future<bool> getEconomicTrackingEnabled() async {
    final db = await database;

    final result = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['economic_tracking'],
      limit: 1,
    );

    if (result.isEmpty) return false;

    return result.first['value'] == 'true';
  }

  /// Activa o desactiva el seguimiento económico.
  Future<void> setEconomicTrackingEnabled(bool enabled) async {
    final db = await database;

    await db.insert('settings', {
      'key': 'economic_tracking',
      'value': enabled.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
