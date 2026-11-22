class OrderPlan {
  final int id;
  final String planDate;
  final int targetCents;
  final int totalCents;

  const OrderPlan({
    required this.id,
    required this.planDate,
    required this.targetCents,
    required this.totalCents,
  });

  // Convert a SQLite order_plans row into an object.
  factory OrderPlan.fromMap(Map<String, Object?> map) {
    return OrderPlan(
      id: map['id'] as int,
      planDate: map['plan_date'] as String,
      targetCents: map['target_cents'] as int,
      totalCents: map['total_cents'] as int,
    );
  }
}

// A saved snapshot of one food in an order.
class SavedOrderItem {
  final String name;
  final int priceCents;

  const SavedOrderItem({required this.name, required this.priceCents});

  // Convert a SQLite order_plan_items row into an object.
  factory SavedOrderItem.fromMap(Map<String, Object?> map) {
    return SavedOrderItem(
      name: map['item_name'] as String,
      priceCents: map['price_cents'] as int,
    );
  }
}

// Dates use YYYY-MM-DD so they sort correctly in SQLite.
String formatPlanDate(DateTime date) {
  final year = date.year;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
