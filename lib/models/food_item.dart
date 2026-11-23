class FoodItem {
  final int id;
  final String name;
  final String category;
  final int priceCents;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
  });

  // Convert a SQLite row into a FoodItem object.
  factory FoodItem.fromMap(Map<String, Object?> map) {
    return FoodItem(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      priceCents: map['price_cents'] as int,
    );
  }

  // Display an integer price in Canadian dollars.
  String get formattedPrice {
    return '\$${(priceCents / 100).toStringAsFixed(2)}';
  }
}
