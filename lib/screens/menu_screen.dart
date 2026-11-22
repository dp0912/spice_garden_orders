
import 'package:material_ui/material_ui.dart';

import '../data/restaurant_database.dart';
import '../models/food_item.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<FoodItem>> _foodItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  // Load restaurant foods from the SQLite database.
  void _loadFoodItems() {
    _foodItemsFuture =
        RestaurantDatabase.instance.getAllFoodItems();
  }

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF7A2329);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spice Garden Menu'),
      ),
      body: FutureBuilder<List<FoodItem>>(
        future: _foodItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Database error: ${snapshot.error}',
              ),
            );
          }

          final foods = snapshot.data ?? [];

          if (foods.isEmpty) {
            return const Center(
              child: Text('No food items available.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 42,
                      color: burgundy,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${foods.length} menu items available',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: burgundy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Freshly prepared Indian favourites',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor:
                          Color(0xFFF1DFD2),
                          child: Icon(
                            Icons.restaurant,
                            color: burgundy,
                          ),
                        ),
                        title: Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(food.category),
                        trailing: Text(
                          food.formattedPrice,
                          style: const TextStyle(
                            color: burgundy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
