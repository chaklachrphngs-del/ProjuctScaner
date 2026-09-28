import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'grocery_price.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. สร้างตารางเก็บสินค้า
        await db.execute('''
          CREATE TABLE products(
            barcode TEXT PRIMARY KEY,
            name TEXT,
            price REAL
          )
        ''');

        // 2. เพิ่มข้อมูลสินค้าตัวอย่าง (ยาทาแผลสด ตราเสือดาว)
        await db.insert('products', {
          'barcode': '8853042000963',
          'name': 'ยาทาแผลสด โพวิโดน-ไอโอดีน (ตราเสือดาว)',
          'price': 15.0,
        });
      },
    );
  }

  // ค้นหาสินค้าจากบาร์โค้ด
  static Future<Map<String, dynamic>?> getProduct(String barcode) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // เพิ่มหรืออัปเดตราคา
  static Future<void> insertOrUpdateProduct(
    String barcode,
    String name,
    double price,
  ) async {
    final db = await database;
    await db.insert('products', {
      'barcode': barcode,
      'name': name,
      'price': price,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
