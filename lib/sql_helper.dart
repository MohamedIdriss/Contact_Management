import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'newContacts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contact(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT,
        prenom TEXT,
        tel TEXT,
        photo TEXT,
        isfavorite INTEGER
      )
    ''');
  }

  // CRUD methods

  Future<int> insertContact(Map<String, dynamic> contact) async {
    Database db = await instance.database;
    return await db.insert('contact', contact);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    Database db = await instance.database;
    return await db.query('contact' ,orderBy: 'prenom');
  }

  Future<int> updateContact(Map<String, dynamic> contact) async {
    Database db = await instance.database;
    int id = contact['id'];
    return await db.update('contact', contact, where: 'id = ?', whereArgs: [id]);
  }
  Future<int>  favorisContact(int id ,int favoris) async {
    Database db = await instance.database;
    return await db.update('contact',  {'isfavorite' : favoris}, where: 'id = ?', whereArgs: [id]);
  }
  Future<List<Map<String, dynamic>>> getFavoris() async {
    Database db = await instance.database;
    return await db.query('contact',  where: 'isfavorite = ?', whereArgs: [0],orderBy: 'prenom');
  }

  Future<int> deleteContact(int id) async {
    Database db = await instance.database;
    return await db.delete('contact', where: 'id = ?', whereArgs: [id]);
  }
  Future<Map<String, dynamic>> getContactById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      'contact',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return results.first;
    }

    return {};
  }
}