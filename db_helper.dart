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

        // 2. เพิ่มข้อมูลสินค้าตัวอย่าง ชิ้นที่ 1
        await db.insert('products', {
          'barcode': '8853042000963',
          'name': 'ยาทาแผลสด โพวิโดน-ไอโอดีน (ตราเสือดาว)',
          'price': 15.0,
        });

        // 3. เพิ่มข้อมูลสินค้าตัวอย่าง ชิ้นที่ 2
        await db.insert('products', {
          'barcode': '8853593004328',
          'name': 'ยาทาแผลสด',
          'price': 20.0,
        });
      }, // ปิด onCreate
    ); // ปิด openDatabase
  }

  // 1. ค้นหาสินค้าจากบาร์โค้ด
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

  // 2. เพิ่มหรืออัปเดตราคา
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

  // 3. ดึงรายการสินค้าทั้งหมด
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }

  // 4. แก้ไขชื่อและราคา
  static Future<int> updateProduct(
    String barcode,
    String name,
    double price,
  ) async {
    final db = await database;
    return await db.update(
      'products',
      {'name': name, 'price': price},
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }

  // 5. ลบสินค้าออกจากฐานข้อมูล
  static Future<int> deleteProduct(String barcode) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }
}
