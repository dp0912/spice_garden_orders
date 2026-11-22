import 'package:material_ui/material_ui.dart';

import 'data/restaurant_database.dart';
import 'screens/history_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/plan_screen.dart';

// Application entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite and seed foods on first launch.
  await RestaurantDatabase.instance.database;

  runApp(const SpiceGardenApp());
}

// Restaurant application and custom theme.
class SpiceGardenApp extends StatelessWidget {
  const SpiceGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF7A2329);
    const cream = Color(0xFFFFF4E5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spice Garden',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: burgundy),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: burgundy,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: burgundy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// Home screen and navigation.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF7A2329);

    return Scaffold(
      appBar: AppBar(title: const Text('Spice Garden')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu, size: 85, color: burgundy),
              const SizedBox(height: 20),

              const Text(
                'Welcome to Spice Garden',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              const Text(
                'Your daily food budget planner',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Open the restaurant menu.
              ElevatedButton.icon(
                icon: const Icon(Icons.menu_book),
                label: const Text('View Menu'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MenuScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Open the daily order planner.
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: const Text('Plan Daily Order'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlanScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // NEW: View saved orders and search by date.
              ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Order History'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
