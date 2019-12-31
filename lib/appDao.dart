import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';

class AppDao {
  final String tableName = 'app';
  final String colId = 'id';
  final String colName = 'name';
  final String colDescription = 'description';
  final String colIconUrl = 'icon_url';
  final String colPackageName = 'package_name';
  final String colBundleId = 'bundle_id';

  Database database;

  void init() {
    initDataBase();
  }

  Future initAndRun(Function fun) async {
    await initDataBase().then(fun);
  }

  Future initDataBase() async {
    var databasesPath = await getDatabasesPath();
    String fullPath = join(databasesPath, 'local.db');
    if (!(await databaseExists(fullPath))) {
        ByteData byteData = await rootBundle.load('assets/database/local.db');
        File(fullPath)..writeAsBytes(byteData.buffer.asInt8List(0));
    }

    database = await openDatabase(fullPath);

    /*
    database = await openDatabase(fullPath, version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''CREATE TABLE $tableName (
            $colId TEXT PRIMARY KEY, 
            $colName TEXT, 
            $colDescription TEXT, 
            $colIconUrl TEXT,
            $colPackageName TEXT,
            $colBundleId TEXT
          )'''
        );
      }
    );
    */
  }

  Future insertMany(List<App> appList) async {
    Batch batch = database.batch();
    appList.forEach((item) => batch.insert(tableName, toMap(item)));
    
    await batch.commit();
  }

  Future deleteAll() async {
    await database.rawDelete('DELETE FROM $tableName');
  }

  Future<int> getCount() async {
    return Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM $tableName'));
  }

  Future<List<App>> findAll() async {
    return mapList(await database.rawQuery('SELECT * FROM $tableName'));
  }

  Future<List<App>> findMany(int startIndex, int count) async {
    return mapList(await database.rawQuery('SELECT * FROM $tableName LIMIT $startIndex, $count'));
  }

  Map<String, dynamic> toMap(App app) {
    return <String, dynamic> {
      colId: app.id,
      colName: app.name,
      colDescription: app.description,
      colIconUrl: app.iconUrl,
      colPackageName: app.packageName,
      colBundleId: app.bundleId,
    };
  }

  App map(Map<String, dynamic> map) {
    return App(
      map[colId],
      map[colName],
      map[colDescription],
      map[colIconUrl],
      map[colPackageName],
      map[colBundleId],
    );
  }

  List<App> mapList(List<Map<String, dynamic>> mapList) {
    var appList = List<App>();
    mapList.forEach((item) => appList.add(map(item)));
    return appList;
  }

}