
import 'package:flutter_test/flutter_test.dart';
import 'package:spice_garden_orders/utils/budget_utils.dart';

void main() {
  group('Daily budget calculations', () {
    test('Converts dollar amounts to cents', () {
      expect(parseBudgetToCents('30.00'), 3000);
      expect(parseBudgetToCents('12.5'), 1250);
      expect(parseBudgetToCents('20'), 2000);
    });

    test('Rejects invalid target amounts', () {
      expect(parseBudgetToCents(''), isNull);
      expect(parseBudgetToCents('-5'), isNull);
      expect(parseBudgetToCents('abc'), isNull);
      expect(parseBudgetToCents('0'), isNull);
      expect(parseBudgetToCents('10.999'), isNull);
    });

    test('Allows food within the target', () {
      expect(
        canAddFood(
          currentTotalCents: 1899,
          itemPriceCents: 499,
          targetCents: 3000,
        ),
        isTrue,
      );
    });

    test('Rejects food exceeding the target', () {
      expect(
        canAddFood(
          currentTotalCents: 2398,
          itemPriceCents: 700,
          targetCents: 3000,
        ),
        isFalse,
      );
    });

    test('Allows an exact budget match', () {
      expect(
        canAddFood(
          currentTotalCents: 2000,
          itemPriceCents: 1000,
          targetCents: 3000,
        ),
        isTrue,
      );
    });

    test('Formats cents as dollars', () {
      expect(formatCents(2398), '\$23.98');
      expect(formatCents(602), '\$6.02');
    });
  });
}
