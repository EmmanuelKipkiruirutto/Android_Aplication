import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._();

  factory DBHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'restaurant.db');
    return await openDatabase(
      path,
      version: 1, // Set initial version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE food (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        name TEXT,
        price REAL,
        FOREIGN KEY (category_id) REFERENCES food_category (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_number INTEGER,
        food_id INTEGER,
        FOREIGN KEY (food_id) REFERENCES food (id)
      )
    ''');

    // Insert initial data
    await db.insert('food_category', {'name': 'Fruits and vegetables'});
    await db.insert('food_category', {'name': 'Carbohydrates'});
    await db.insert('food_category', {'name': 'Proteins'});
    await db.insert('food_category', {'name': 'Dairy'});

    await db.insert('food', {'category_id': 1, 'name': 'Bananas', 'price': 25.00});
    await db.insert('food', {'category_id': 1, 'name': 'Broccoli', 'price': 45.00});
    await db.insert('food', {'category_id': 1, 'name': 'Apples', 'price': 35.00});
    await db.insert('food', {'category_id': 2, 'name': 'Bread', 'price': 65.00});
    await db.insert('food', {'category_id': 2, 'name': 'Rice', 'price': 50.00});
    await db.insert('food', {'category_id': 2, 'name': 'Chapati', 'price': 20.00});
    await db.insert('food', {'category_id': 3, 'name': 'Beef', 'price': 200.00});
    await db.insert('food', {'category_id': 3, 'name': 'Beans', 'price': 50.00});
    await db.insert('food', {'category_id': 3, 'name': 'Eggs', 'price': 25.00});
    await db.insert('food', {'category_id': 4, 'name': 'Milk', 'price': 30.00});
    await db.insert('food', {'category_id': 4, 'name': 'Yoghurt', 'price': 120.00});
    await db.insert('food', {'category_id': 4, 'name': 'Mursik', 'price': 50.00});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrade logic if needed
  }

  Future<void> insertOrder(int tableNumber, int foodId) async {
    final db = await database;
    await db.insert('orders', {
      'table_number': tableNumber,
      'food_id': foodId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchOrders([int? tableNumber]) async {
    final db = await database;
    if (tableNumber != null) {
      return await db.query('orders', where: 'table_number = ?', whereArgs: [tableNumber]);
    } else {
      return await db.query('orders');
    }
  }

  Future<void> clearOrder(int tableNumber) async {
    final db = await database;
    await db.delete('orders', where: 'table_number = ?', whereArgs: [tableNumber]);
  }

  Future<List<Map<String, dynamic>>> fetchFoodCategories() async {
    final db = await database;
    return await db.query('food_category');
  }

  Future<List<Map<String, dynamic>>> fetchFoods(int categoryId) async {
    final db = await database;
    return await db.query('food', where: 'category_id = ?', whereArgs: [categoryId]);
  }
}

