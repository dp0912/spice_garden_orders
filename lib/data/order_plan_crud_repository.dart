import '../models/food_item.dart';
import '../models/order_plan.dart';
import 'restaurant_database.dart';

// SQLite operations for editing and deleting a saved order plan.
class OrderPlanCrudRepository {
  OrderPlanCrudRepository._();

  static final OrderPlanCrudRepository instance = OrderPlanCrudRepository._();

  // Use food IDs to preselect the foods in an existing order.
  Future<Set<int>> getSelectedFoodIds(int planId) async {
    final db = await RestaurantDatabase.instance.database;
    final rows = await db.query(
      'order_plan_items',
      columns: ['food_id'],
      where: 'plan_id = ?',
      whereArgs: [planId],
    );

    // A food ID can be null if the menu item was deleted.
    return rows.map((row) => row['food_id']).whereType<int>().toSet();
  }

  // Count foods whose menu rows were deleted after the order was saved.
  Future<int> getDeletedFoodCount(int planId) async {
    final db = await RestaurantDatabase.instance.database;
    final rows = await db.query(
      'order_plan_items',
      columns: ['food_id'],
      where: 'plan_id = ? AND food_id IS NULL',
      whereArgs: [planId],
    );
    return rows.length;
  }

  // Update date, budget, and selected foods in one SQLite transaction.
  Future<void> updateOrderPlan({
    required int planId,
    required DateTime date,
    required int targetCents,
    required List<FoodItem> selectedFoods,
  }) async {
    if (targetCents <= 0) {
      throw ArgumentError('Daily budget must be positive.');
    }
    if (selectedFoods.isEmpty) {
      throw ArgumentError('Select at least one food item.');
    }
    if (selectedFoods.map((food) => food.id).toSet().length !=
        selectedFoods.length) {
      throw ArgumentError('Duplicate food items are not allowed.');
    }

    final planDate = formatPlanDate(date);
    final db = await RestaurantDatabase.instance.database;

    await db.transaction((txn) async {
      final original = await txn.query(
        'order_plans',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [planId],
        limit: 1,
      );
      if (original.isEmpty) {
        throw StateError('This order plan no longer exists.');
      }

      // Another order is allowed on a different date, not the same date.
      final duplicate = await txn.query(
        'order_plans',
        columns: ['id'],
        where: 'plan_date = ? AND id <> ?',
        whereArgs: [planDate, planId],
        limit: 1,
      );
      if (duplicate.isNotEmpty) {
        throw DuplicateOrderDateException(planDate);
      }

      // Re-read prices from SQLite so we cannot save stale menu prices.
      final latestItems = <Map<String, Object?>>[];
      var totalCents = 0;
      for (final food in selectedFoods) {
        final currentRows = await txn.query(
          'food_items',
          columns: ['id', 'name', 'price_cents'],
          where: 'id = ?',
          whereArgs: [food.id],
          limit: 1,
        );
        if (currentRows.isEmpty) {
          throw StateError('A selected food was removed from the menu.');
        }
        final current = currentRows.first;
        totalCents += current['price_cents'] as int;
        latestItems.add(current);
      }

      if (totalCents > targetCents) {
        throw ArgumentError('Order total exceeds the daily budget.');
      }

      await txn.update(
        'order_plans',
        {
          'plan_date': planDate,
          'target_cents': targetCents,
          'total_cents': totalCents,
        },
        where: 'id = ?',
        whereArgs: [planId],
      );

      // Replace the previous selected foods atomically.
      await txn.delete(
        'order_plan_items',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );
      for (final food in latestItems) {
        await txn.insert('order_plan_items', {
          'plan_id': planId,
          'food_id': food['id'],
          'item_name': food['name'],
          'price_cents': food['price_cents'],
        });
      }
    });
  }

  // DELETE: Remove a complete order (child rows cascade in SQLite).
  Future<void> deleteOrderPlan(int planId) async {
    final db = await RestaurantDatabase.instance.database;
    await db.transaction((txn) async {
      final deleted = await txn.delete(
        'order_plans',
        where: 'id = ?',
        whereArgs: [planId],
      );
      if (deleted != 1) {
        throw StateError('This order plan no longer exists.');
      }
    });
  }
}
