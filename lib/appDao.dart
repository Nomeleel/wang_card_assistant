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
  final String colUrlScheme = 'url_scheme';

  Database database;

  void init() {
    initDataBase();
  }

  Future<void> initAndRun(Function fun) async {
    await initDataBase();
    fun();
  }

  Future<void> initDataBase() async {
    final String databasesPath = await getDatabasesPath();
    final String fullPath = join(databasesPath, 'local.db');
    if (!(await databaseExists(fullPath))) {
      final ByteData byteData =
          await rootBundle.load('assets/database/local.db');
      final File file = File(fullPath);
      file.writeAsBytes(byteData.buffer.asInt8List(0));
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
            $colBundleId TEXT,
            $colUrlScheme TEXT
          )'''
        );
      }
    );
    */
  }

  Future<void> insertMany(List<App> appList) async {
    final Batch batch = database.batch();
    final void Function(App) addData =
        (App app) => batch.insert(tableName, toMap(app));
    appList.forEach(addData);

    await batch.commit();
  }

  Future<void> deleteAll() async {
    await database.rawDelete('DELETE FROM $tableName');
  }

  Future<int> getCount() async {
    return Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $tableName'));
  }

  Future<List<App>> findAll() async {
    return mapList(await database.rawQuery('SELECT * FROM $tableName'));
  }

  Future<List<App>> findMany(int startIndex, int count) async {
    return mapList(await database
        .rawQuery('SELECT * FROM $tableName LIMIT $startIndex, $count'));
  }

  Map<String, dynamic> toMap(App app) {
    return <String, dynamic>{
      colId: app.id,
      colName: app.name,
      colDescription: app.description,
      colIconUrl: app.iconUrl,
      colPackageName: app.packageName,
      colBundleId: app.bundleId,
      colUrlScheme: app.urlScheme,
    };
  }

  App map(Map<String, dynamic> map) {
    return App(
      map[colId]?.toString(),
      map[colName]?.toString(),
      map[colDescription]?.toString(),
      map[colIconUrl]?.toString(),
      map[colPackageName]?.toString(),
      map[colBundleId]?.toString(),
      map[colUrlScheme]?.toString(),
    );
  }

  List<App> mapList(List<Map<String, dynamic>> mapList) {
    final List<App> appList = <App>[];
    final void Function(Map<String, dynamic>) add =
        (Map<String, dynamic> item) => appList.add(map(item));
    mapList.forEach(add);
    return appList;
  }
}
