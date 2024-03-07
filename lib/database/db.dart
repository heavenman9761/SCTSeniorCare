import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mobile/models/devicelist.dart';

final String tableName = 'deviceList';

class DBHelper {
  var _db;

  Future<Database> get database async {
    if (_db != null) return _db;
    _db = openDatabase(
      join(await getDatabasesPath(), 'DeviceList.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE deviceList (deviceID TEXT PRIMARY KEY, deviceType TEXT, accountID TEXT, lastState TEXT, createTime TEXT)",
        );
      },
      version: 1,
    );
    return _db;
  }

  Future<void> insertDeviceList(DeviceList deviceList) async {
    final db = await database;

    await db.insert(
      tableName,
      deviceList.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DeviceList>> deviceLists() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('deviceList');

    return List.generate(maps.length, (i) {
      return DeviceList(
        deviceID: maps[i]['deviceID'],
        deviceType: maps[i]['deviceType'],
        accountID: maps[i]['accountID'],
        lastState: maps[i]['lastState'],
        createTime: maps[i]['createTime'],
      );
    });
  }

  Future<void> updateDeviceList(DeviceList deviceList) async {
    final db = await database;

    await db.update(
      tableName,
      deviceList.toMap(),
      where: "deviceID = ?",
      whereArgs: [deviceList.deviceID],
    );
  }

  Future<void> deleteDeviceList(String deviceID) async {
    final db = await database;

    await db.delete(
      tableName,
      where: "deviceID = ?",
      whereArgs: [deviceID],
    );
  }

  Future<List<DeviceList>> findDeviceList(String deviceID) async {
    final db = await database;

    final List<Map<String, dynamic>> maps =
    await db.query('deviceList', where: 'deviceID = ?', whereArgs: [deviceID]);

    return List.generate(maps.length, (i) {
      return DeviceList(
        deviceID: maps[i]['deviceID'],
        deviceType: maps[i]['deviceType'],
        accountID: maps[i]['accountID'],
        lastState: maps[i]['lastState'],
        createTime: maps[i]['createTime'],
      );
    });
  }
}
