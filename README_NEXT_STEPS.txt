Spice Garden Assignment 3 - Order Plan CRUD

This ZIP contains three files to add or update in your existing Flutter project:
  lib/data/order_plan_crud_repository.dart       (new)
  lib/screens/edit_order_screen.dart             (new)
  lib/screens/history_screen.dart                (updated)

IMPORTANT: It DOES NOT modify restaurant_database.dart, food_item.dart,
plan_screen.dart, or budget_utils.dart, which have uncommitted changes locally.

Steps:
1. In Android Studio, ensure you are inside spice_garden_orders.
2. Make sure there are no uncommitted changes to lib/screens/history_screen.dart.
3. Extract the ZIP into your project ROOT while preserving the folder structure.
4. In Terminal, run:
   dart format lib/data/order_plan_crud_repository.dart lib/screens/edit_order_screen.dart lib/screens/history_screen.dart
   flutter analyze
   flutter test
   flutter run -d emulator-5554
5. Test Order History -> Edit (pencil icon), changing target/date/foods.
6. Test Delete (trash icon) only on a disposable test order.
7. Inspect order_plans and order_plan_items in Android Studio Database Inspector.
8. Commit the three files:
   git add lib/data/order_plan_crud_repository.dart lib/screens/edit_order_screen.dart lib/screens/history_screen.dart
   git commit -m "Implement order plan update and delete in SQLite"
   git push origin main
   git status

Notes:
- The existing 2026-11-25 order remains until you deliberately edit/delete it.
- The schema already has ON DELETE CASCADE; deleting a plan removes its child rows.
- If a previously selected food has since been deleted from the menu,
  the edit screen asks you to choose current menu items before saving.
