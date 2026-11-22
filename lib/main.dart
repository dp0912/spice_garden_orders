
import 'package:material_ui/material_ui.dart';

import 'data/restaurant_database.dart';
import 'screens/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and seed the database on first launch.
  await RestaurantDatabase.instance.database;

  runApp(const SpiceGardenApp());
}

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: burgundy,
        ),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: burgundy,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: burgundy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 16,
            ),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF7A2329);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spice Garden'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_menu,
                size: 85,
                color: burgundy,
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Spice Garden',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your daily food budget planner',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.menu_book),
                label: const Text('View Menu'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const MenuScreen(),
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
