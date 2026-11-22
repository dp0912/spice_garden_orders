
import 'package:material_ui/material_ui.dart';

void main() {
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
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Spice Garden'),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu, size: 64),
              SizedBox(height: 16),
              Text(
                'Welcome to Spice Garden',
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 8),
              Text('Your daily food budget planner'),
            ],
          ),
        ),
      ),
    );
  }
}
