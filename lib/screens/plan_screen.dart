
import 'package:material_ui/material_ui.dart';

import '../data/restaurant_database.dart';
import '../models/food_item.dart';
import '../utils/budget_utils.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const burgundy = Color(0xFF7A2329);

  final TextEditingController _budgetController =
  TextEditingController();

  final Set<int> _selectedFoodIds = {};

  late Future<List<FoodItem>> _foodItemsFuture;

  DateTime _selectedDate = DateTime.now();
  int _totalCents = 0;

  @override
  void initState() {
    super.initState();

    // Read food items from the existing SQLite database.
    _foodItemsFuture =
        RestaurantDatabase.instance.getAllFoodItems();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // Convert the selected date to a readable string.
  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Open a calendar to choose the order date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Display a warning at the bottom of the screen.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Add or remove a food without exceeding the budget.
  void _toggleFood(FoodItem food) {
    // Allow removing an already selected food.
    if (_selectedFoodIds.contains(food.id)) {
      setState(() {
        _selectedFoodIds.remove(food.id);
        _totalCents -= food.priceCents;
      });
      return;
    }

    final targetCents =
    parseBudgetToCents(_budgetController.text);

    if (targetCents == null) {
      _showMessage(
        'Enter a valid daily budget first.',
      );
      return;
    }

    if (!canAddFood(
      currentTotalCents: _totalCents,
      itemPriceCents: food.priceCents,
      targetCents: targetCents,
    )) {
      final remainingCents =
          targetCents - _totalCents;

      _showMessage(
        'Budget exceeded! Only '
            '${formatCents(remainingCents)} remaining.',
      );
      return;
    }

    setState(() {
      _selectedFoodIds.add(food.id);
      _totalCents += food.priceCents;
    });
  }

  // Display the target, selected total and remaining budget.
  Widget _buildBudgetSummary(int? targetCents) {
    final remainingCents =
    targetCents == null ? 0 : targetCents - _totalCents;

    final overBudget =
        targetCents != null && _totalCents > targetCents;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: burgundy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Selected items: ${_selectedFoodIds.length}',
            ),
            const SizedBox(height: 8),
            Text(
              'Daily target: '
                  '${targetCents == null ? 'Not set' : formatCents(targetCents)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Selected total: ${formatCents(_totalCents)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining: '
                  '${targetCents == null ? '--' : formatCents(remainingCents)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: overBudget ? Colors.red : burgundy,
              ),
            ),
            if (overBudget) ...[
              const SizedBox(height: 12),
              const Text(
                'Your current selection exceeds the '
                    'updated budget. Increase the budget '
                    'or remove some food items.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetCents =
    parseBudgetToCents(_budgetController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Daily Order'),
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
                'Unable to load foods: ${snapshot.error}',
              ),
            );
          }

          final foods = snapshot.data ?? [];

          if (foods.isEmpty) {
            return const Center(
              child: Text('No foods available.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Create your daily food plan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: burgundy,
                ),
              ),
              const SizedBox(height: 16),

              // Daily budget input.
              TextField(
                controller: _budgetController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Target cost per day (CAD)',
                  hintText: 'e.g. 30.00',
                  prefixIcon:
                  const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  errorText: _budgetController.text.isNotEmpty &&
                      targetCents == null
                      ? 'Enter a positive amount, up to 2 decimals.'
                      : null,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              // Order date.
              const Text(
                'Select order date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickDate,
                label: Text(
                  _formatDate(_selectedDate),
                ),
              ),
              const SizedBox(height: 16),

              _buildBudgetSummary(targetCents),

              const SizedBox(height: 20),
              const Text(
                'Choose Food Items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: burgundy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select foods without exceeding '
                    'your daily target.',
              ),
              const SizedBox(height: 12),

              // Select food items loaded from SQLite.
              ...foods.map((food) {
                final isSelected =
                _selectedFoodIds.contains(food.id);

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  color: isSelected
                      ? const Color(0xFFFFE5D1)
                      : Colors.white,
                  child: CheckboxListTile(
                    value: isSelected,
                    activeColor: burgundy,
                    controlAffinity:
                    ListTileControlAffinity.leading,
                    title: Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(food.category),
                    secondary: Text(
                      food.formattedPrice,
                      style: const TextStyle(
                        color: burgundy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onChanged: (_) {
                      _toggleFood(food);
                    },
                  ),
                );
              }),

              const SizedBox(height: 16),
              const Text(
                'Selected foods are currently held '
                    'in app state. Database saving will '
                    'be added in the next stage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
