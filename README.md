
# 🌶️ Spice Garden — Food Ordering & Daily Budget Planner

A Flutter and Dart Android app for browsing an Indian restaurant menu, creating date-based meal plans, and keeping food selections within a daily budget. Orders and menu items are stored locally with SQLite.

**Developer:** Dhruvin Patel  
**Course:** SOFE 4640U — Mobile Application Development, Ontario Tech University (Fall 2026)

## Features

- **Restaurant menu:** 20 Indian food items seeded automatically on first install, with categories and prices in CAD.
- **Food CRUD:** Add, edit, and delete foods with input validation and confirmation.
- **Daily order planner:** Choose a date, set a daily budget, and select foods with a live total and remaining balance.
- **Budget enforcement:** Prevent selections and saved orders that exceed the target.
- **Saved orders:** Store plans and itemized foods in SQLite, search by date, and view plans sorted newest first.
- **Order CRUD:** Edit a saved plan's date, target, or selected foods; delete plans with confirmation.

## Tech Stack

| Technology | Role |
|---|---|
| Flutter / Dart / `material_ui` | UI, navigation, and application logic |
| SQLite / `sqflite` | Local persistent storage and CRUD |
| `path` | Database file path |
| `flutter_test` | Budget unit tests and widget tests |

## Getting Started

Requires the Flutter SDK, Android Studio, and an Android emulator or connected Android device.

```bash
git clone https://github.com/dp0912/spice_garden_orders.git
cd spice_garden_orders
flutter pub get
flutter devices
flutter run
```

Use `flutter run -d DEVICE_ID` if multiple devices are available.

On first launch, the app creates `spice_garden.db` and seeds 20 food items. Subsequent launches preserve stored data.

## SQLite Database

| Table | Description |
|---|---|
| `food_items` | Food names, categories, and prices |
| `order_plans` | Unique plan dates, daily targets, and totals |
| `order_plan_items` | Selected foods with saved names and prices |

Prices are stored as **integer cents** to avoid rounding errors. SQLite **transactions** keep multi-table order saves and updates consistent.

Foreign keys cascade order deletion while preserving saved item details when a menu item is deleted. One order plan is allowed per date.

## Project Structure

```text
lib/
├── main.dart     # Entry point, theme, navigation
├── data/         # SQLite and CRUD repositories
├── models/       # Food and order models
├── screens/      # Menu, planner, history, edit screens
└── utils/        # Budget and currency helpers
test/             # Unit and widget tests
```

## Testing

```bash
flutter analyze
flutter test
```

To inspect database records, run the Android app and open **Android Studio → App Inspection → Database Inspector**.

**Note:** Spice Garden is an academic order-planning prototype. It does not process payments or send orders to a restaurant. Android is the primary tested platform.

---

**Developed by [Dhruvin Patel](https://github.com/dp0912) · SOFE 4640U · Fall 2026**
