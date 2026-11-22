import 'restaurant_database.dart';

class FoodRepository {
  FoodRepository._();

  static final FoodRepository instance = FoodRepository._();

  // Validate food information before modifying SQLite.
  void _validateFood(String name, String category, int priceCents) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Food name cannot be empty.');
    }

    if (category.trim().isEmpty) {
      throw ArgumentError('Category cannot be empty.');
    }

    if (priceCents <= 0) {
      throw ArgumentError('Price must be greater than zero.');
    }
  }

  // CREATE: Add a new food item to the menu.
  Future<int> addFoodItem({
    required String name,
    required String category,
    required int priceCents,
  }) async {
    _validateFood(name, category, priceCents);

    final db = await RestaurantDatabase.instance.database;

    return db.insert('food_items', {
      'name': name.trim(),
      'category': category.trim(),
      'price_cents': priceCents,
    });
  }

  // UPDATE: Change the name, category, or price of a food.
  Future<int> updateFoodItem({
    required int id,
    required String name,
    required String category,
    required int priceCents,
  }) async {
    _validateFood(name, category, priceCents);

    final db = await RestaurantDatabase.instance.database;

    return db.update(
      'food_items',
      {
        'name': name.trim(),
        'category': category.trim(),
        'price_cents': priceCents,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE: Remove a selected food item from the menu.
  Future<int> deleteFoodItem(int id) async {
    final db = await RestaurantDatabase.instance.database;

    return db.delete('food_items', where: 'id = ?', whereArgs: [id]);
  }
}
