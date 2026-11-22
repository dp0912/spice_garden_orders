
import 'package:flutter_test/flutter_test.dart';
import 'package:spice_garden_orders/main.dart';

void main() {
  testWidgets('Spice Garden home screen loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(const SpiceGardenApp());

        expect(
          find.text('Welcome to Spice Garden'),
          findsOneWidget,
        );
      });
}
