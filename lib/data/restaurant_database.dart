
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/food_item.dart';

class RestaurantDatabase {
  RestaurantDatabase._();

  static final RestaurantDatabase instance =
  RestaurantDatabase._();

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= _openDatabase();
  }

  // Open the persistent SQLite database on the device.
  Future<Database> _openDatabase() async {
    final dbPath = join(
      await getDatabasesPath(),
      'spice_garden.db',
    );

    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Table 1: Restaurant menu.
        await db.execute('''
          CREATE TABLE food_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price_cents INTEGER NOT NULL
              CHECK(price_cents > 0)
          )
        ''');

        // Table 2: Saved daily order plans.
        await db.execute('''
          CREATE TABLE order_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_date TEXT NOT NULL UNIQUE,
            target_cents INTEGER NOT NULL,
            total_cents INTEGER NOT NULL
          )
        ''');

        // Table 3: Foods in each saved order.
        await db.execute('''
          CREATE TABLE order_plan_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER NOT NULL,
            food_id INTEGER,
            item_name TEXT NOT NULL,
            price_cents INTEGER NOT NULL,
            FOREIGN KEY (plan_id)
              REFERENCES order_plans(id)
              ON DELETE CASCADE,
            FOREIGN KEY (food_id)
              REFERENCES food_items(id)
              ON DELETE SET NULL
          )
        ''');

        await _seedFoodItems(db);
      },
    );
  }

  // Seed 20 menu items during first database creation.
  Future<void> _seedFoodItems(Database db) async {
    final foods = [
      ['Masala Chai', 'Beverages', 250],
      ['Mango Lassi', 'Beverages', 450],
      ['Samosa', 'Starters', 550],
      ['Veg Pakora', 'Starters', 650],
      ['Aloo Tikki', 'Starters', 700],
      ['Paneer Tikka', 'Starters', 1399],
      ['Chilli Paneer', 'Starters', 1499],
      ['Tandoori Chicken', 'Starters', 1699],
      ['Butter Chicken', 'Main Course', 1899],
      ['Chicken Tikka Masala', 'Main Course', 1999],
      ['Palak Paneer', 'Main Course', 1699],
      ['Shahi Paneer', 'Main Course', 1799],
      ['Dal Makhani', 'Main Course', 1499],
      ['Chana Masala', 'Main Course', 1399],
      ['Veg Biryani', 'Rice', 1599],
      ['Chicken Biryani', 'Rice', 1899],
      ['Jeera Rice', 'Rice', 499],
      ['Butter Naan', 'Breads', 349],
      ['Garlic Naan', 'Breads', 399],
      ['Gulab Jamun', 'Desserts', 599],
    ];

    final batch = db.batch();

    for (final food in foods) {
      batch.insert('food_items', {
        'name': food[0] as String,
        'category': food[1] as String,
        'price_cents': food[2] as int,
      });
    }

    await batch.commit(noResult: true);
  }

  // Read all menu items, ordered by category and name.
  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;

    final rows = await db.query(
      'food_items',
      orderBy: 'category ASC, name ASC',
    );

    return rows.map(FoodItem.fromMap).toList();
  }
}
