/// Converts a dollar amount such as "30.50" into integer cents.
/// Returns null when the input is invalid or not positive.
int? parseBudgetToCents(String input) {
  final value = input.trim();

  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
    return null;
  }

  final parts = value.split('.');
  final dollars = int.tryParse(parts[0]);

  if (dollars == null) return null;

  final cents = parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0;

  final total = dollars * 100 + cents;
  return total > 0 ? total : null;
}

/// Returns true only when adding the item stays within budget.
bool canAddFood({
  required int currentTotalCents,
  required int itemPriceCents,
  required int? targetCents,
}) {
  if (targetCents == null || targetCents <= 0) {
    return false;
  }

  return currentTotalCents + itemPriceCents <= targetCents;
}

/// Formats integer cents as a CAD dollar amount.
String formatCents(int value) {
  final negative = value < 0;
  final absolute = value.abs();

  final dollars = absolute ~/ 100;
  final cents = (absolute % 100).toString().padLeft(2, '0');

  return '${negative ? '-' : ''}\$$dollars.$cents';
}
