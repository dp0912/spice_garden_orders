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

  final TextEditingController _budgetController = TextEditingController();

  final Set<int> _selectedFoodIds = {};

  late Future<List<FoodItem>> _foodItemsFuture;

  DateTime _selectedDate = DateTime.now();
  int _totalCents = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Load food items from SQLite.
    _foodItemsFuture = RestaurantDatabase.instance.getAllFoodItems();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // Format dates consistently for display.
  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Let the user pick an order date.
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

  // Show validation or database messages.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // Select or deselect food while enforcing the budget.
  void _toggleFood(FoodItem food) {
    if (_selectedFoodIds.contains(food.id)) {
      setState(() {
        _selectedFoodIds.remove(food.id);
        _totalCents -= food.priceCents;
      });
      return;
    }

    final targetCents = parseBudgetToCents(_budgetController.text);

    if (targetCents == null) {
      _showMessage('Enter a valid daily budget first.');
      return;
    }

    if (!canAddFood(
      currentTotalCents: _totalCents,
      itemPriceCents: food.priceCents,
      targetCents: targetCents,
    )) {
      final remaining = targetCents - _totalCents;

      _showMessage(
        'Budget exceeded! Only '
        '${formatCents(remaining)} remaining.',
      );
      return;
    }

    setState(() {
      _selectedFoodIds.add(food.id);
      _totalCents += food.priceCents;
    });
  }

  // Save the date, budget and selected foods into SQLite.
  Future<void> _saveOrderPlan(List<FoodItem> allFoods) async {
    if (_isSaving) return;

    final targetCents = parseBudgetToCents(_budgetController.text);

    if (targetCents == null) {
      _showMessage('Please enter a valid daily budget.');
      return;
    }

    final selectedFoods = allFoods
        .where((food) => _selectedFoodIds.contains(food.id))
        .toList();

    if (selectedFoods.isEmpty) {
      _showMessage('Please select at least one food item.');
      return;
    }

    // Recalculate the total before saving.
    final actualTotal = selectedFoods.fold<int>(
      0,
      (sum, food) => sum + food.priceCents,
    );

    if (actualTotal > targetCents) {
      _showMessage('Cannot save: order exceeds the daily budget.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Store the order in a SQLite transaction.
      final planId = await RestaurantDatabase.instance.saveOrderPlan(
        date: _selectedDate,
        targetCents: targetCents,
        selectedFoods: selectedFoods,
      );

      if (!mounted) return;

      // Display the saved order confirmation.
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Order Saved!'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your order plan was saved '
                    'successfully in SQLite.',
                  ),
                  const SizedBox(height: 12),
                  Text('Order ID: $planId'),
                  Text('Date: ${_formatDate(_selectedDate)}'),
                  Text(
                    'Daily Budget: '
                    '${formatCents(targetCents)}',
                  ),
                  Text(
                    'Total Cost: '
                    '${formatCents(actualTotal)}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Selected Foods:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  for (final food in selectedFoods)
                    Text(
                      '${food.name} - '
                      '${food.formattedPrice}',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      // Return Home after the user closes the dialog.
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DuplicateOrderDateException catch (error) {
      if (mounted) {
        _showMessage(error.toString());
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        _showMessage(error.message.toString());
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to save order: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Build the summary card.
  Widget _buildBudgetSummary(int? targetCents) {
    final remainingCents = targetCents == null ? 0 : targetCents - _totalCents;

    final overBudget = targetCents != null && _totalCents > targetCents;

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
            Text('Selected items: ${_selectedFoodIds.length}'),
            const SizedBox(height: 8),
            Text(
              'Daily target: '
              '${targetCents == null ? 'Not set' : formatCents(targetCents)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Selected total: ${formatCents(_totalCents)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
    final targetCents = parseBudgetToCents(_budgetController.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Daily Order')),
      body: FutureBuilder<List<FoodItem>>(
        future: _foodItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load foods: ${snapshot.error}'),
            );
          }

          final foods = snapshot.data ?? [];

          if (foods.isEmpty) {
            return const Center(child: Text('No foods available.'));
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

              // Daily target input.
              TextField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Target cost per day (CAD)',
                  hintText: 'e.g. 30.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  errorText:
                      _budgetController.text.isNotEmpty && targetCents == null
                      ? 'Enter a positive amount, up to 2 decimals.'
                      : null,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Select order date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Date picker button.
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickDate,
                label: Text(_formatDate(_selectedDate)),
              ),
              const SizedBox(height: 16),

              // Show the calculated budget.
              _buildBudgetSummary(targetCents),
              const SizedBox(height: 16),

              // NEW: Save the selected order into SQLite.
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveOrderPlan(foods),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Order Plan'),
              ),

              const SizedBox(height: 22),
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

              // Food selection list.
              ...foods.map((food) {
                final isSelected = _selectedFoodIds.contains(food.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected ? const Color(0xFFFFE5D1) : Colors.white,
                  child: CheckboxListTile(
                    value: isSelected,
                    activeColor: burgundy,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      food.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
