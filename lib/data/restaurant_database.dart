import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/food_item.dart';

// Used when an order already exists for a selected date.
class DuplicateOrderDateException implements Exception {
  final String date;

  const DuplicateOrderDateException(this.date);

  @override
  String toString() => 'An order plan already exists for $date.';
}

class RestaurantDatabase {
  RestaurantDatabase._();

  static final RestaurantDatabase instance = RestaurantDatabase._();

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= _openDatabase();
  }

  // Open the persistent SQLite database.
  Future<Database> _openDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'spice_garden.db');

    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Restaurant menu table.
        await db.execute('''
          CREATE TABLE food_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price_cents INTEGER NOT NULL
              CHECK(price_cents > 0)
          )
        ''');

        // Saved order plans.
        await db.execute('''
          CREATE TABLE order_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_date TEXT NOT NULL UNIQUE,
            target_cents INTEGER NOT NULL,
            total_cents INTEGER NOT NULL
          )
        ''');

        // Selected foods belonging to each saved plan.
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

  // Insert 20 restaurant foods on first installation.
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

  // Read the restaurant menu.
  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;

    final rows = await db.query(
      'food_items',
      orderBy: 'category ASC, name ASC',
    );

    return rows.map(FoodItem.fromMap).toList();
  }

  // Convert a date into the ISO format used by SQLite.
  String _dateToString(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Save a complete order plan and its foods atomically.
  Future<int> saveOrderPlan({
    required DateTime date,
    required int targetCents,
    required List<FoodItem> selectedFoods,
  }) async {
    // Validate the incoming order before writing.
    if (targetCents <= 0) {
      throw ArgumentError('Budget must be positive.');
    }

    if (selectedFoods.isEmpty) {
      throw ArgumentError('Select at least one food item.');
    }

    final uniqueIds = selectedFoods.map((food) => food.id).toSet();

    if (uniqueIds.length != selectedFoods.length) {
      throw ArgumentError('Duplicate food items detected.');
    }

    final totalCents = selectedFoods.fold<int>(
      0,
      (sum, food) => sum + food.priceCents,
    );

    if (totalCents > targetCents) {
      throw ArgumentError('Order exceeds the daily budget.');
    }

    final selectedDate = _dateToString(date);
    final db = await database;

    // If any insert fails, the entire order is rolled back.
    return db.transaction<int>((txn) async {
      // Allow one order plan per date for now.
      final existing = await txn.query(
        'order_plans',
        columns: ['id'],
        where: 'plan_date = ?',
        whereArgs: [selectedDate],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw DuplicateOrderDateException(selectedDate);
      }

      // Insert the order plan and obtain its ID.
      final planId = await txn.insert('order_plans', {
        'plan_date': selectedDate,
        'target_cents': targetCents,
        'total_cents': totalCents,
      });

      // Save snapshots of the selected food items.
      for (final food in selectedFoods) {
        await txn.insert('order_plan_items', {
          'plan_id': planId,
          'food_id': food.id,
          'item_name': food.name,
          'price_cents': food.priceCents,
        });
      }

      return planId;
    });
  }
}
