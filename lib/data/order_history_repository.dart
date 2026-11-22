import '../models/order_plan.dart';
import 'restaurant_database.dart';

class OrderHistoryRepository {
  OrderHistoryRepository._();

  static final OrderHistoryRepository instance = OrderHistoryRepository._();

  // Get all saved plans, newest date first.
  Future<List<OrderPlan>> getAllPlans() async {
    final db = await RestaurantDatabase.instance.database;

    final rows = await db.query(
      'order_plans',
      orderBy: 'plan_date DESC, id DESC',
    );

    return rows.map(OrderPlan.fromMap).toList();
  }

  // Search SQLite for the plan saved on a specific date.
  Future<OrderPlan?> getPlanByDate(DateTime date) async {
    final db = await RestaurantDatabase.instance.database;

    final rows = await db.query(
      'order_plans',
      where: 'plan_date = ?',
      whereArgs: [formatPlanDate(date)],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return OrderPlan.fromMap(rows.first);
  }

  // Read the foods belonging to a specific saved order.
  Future<List<SavedOrderItem>> getPlanItems(int planId) async {
    final db = await RestaurantDatabase.instance.database;

    final rows = await db.query(
      'order_plan_items',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'id ASC',
    );

    return rows.map(SavedOrderItem.fromMap).toList();
  }
}
