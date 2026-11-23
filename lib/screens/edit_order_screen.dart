import 'package:material_ui/material_ui.dart';

import '../data/order_plan_crud_repository.dart';
import '../data/restaurant_database.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';
import '../utils/budget_utils.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderPlan plan;

  const EditOrderScreen({super.key, required this.plan});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderData {
  final List<FoodItem> foods;
  final int unavailableItems;

  const _EditOrderData(this.foods, this.unavailableItems);
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  static const burgundy = Color(0xFF7A2329);
  final Set<int> _selectedFoodIds = <int>{};

  late final TextEditingController _budgetController;
  late final Future<_EditOrderData> _loadFuture;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.parse(widget.plan.planDate);
    _budgetController = TextEditingController(
      text: (widget.plan.targetCents / 100).toStringAsFixed(2),
    );
    _loadFuture = _loadCurrentOrder();
  }

  Future<_EditOrderData> _loadCurrentOrder() async {
    final foods = await RestaurantDatabase.instance.getAllFoodItems();
    final oldIds = await OrderPlanCrudRepository.instance.getSelectedFoodIds(
      widget.plan.id,
    );
    _selectedFoodIds.addAll(oldIds);
    final menuIds = foods.map((food) => food.id).toSet();
    final deletedCount = await OrderPlanCrudRepository.instance
        .getDeletedFoodCount(widget.plan.id);
    return _EditOrderData(
      foods,
      deletedCount + oldIds.difference(menuIds).length,
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _saveChanges(List<FoodItem> allFoods) async {
    if (_isSaving) return;
    final targetCents = parseBudgetToCents(_budgetController.text);
    if (targetCents == null) {
      _showMessage('Enter a valid, positive daily budget.');
      return;
    }

    final selectedFoods = allFoods
        .where((food) => _selectedFoodIds.contains(food.id))
        .toList();
    if (selectedFoods.isEmpty) {
      _showMessage('Select at least one food item.');
      return;
    }

    final totalCents = selectedFoods.fold<int>(
      0,
      (sum, food) => sum + food.priceCents,
    );
    if (totalCents > targetCents) {
      _showMessage('Order total exceeds the daily budget.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await OrderPlanCrudRepository.instance.updateOrderPlan(
        planId: widget.plan.id,
        date: _selectedDate,
        targetCents: targetCents,
        selectedFoods: selectedFoods,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DuplicateOrderDateException catch (error) {
      if (mounted) _showMessage(error.toString());
    } on ArgumentError catch (error) {
      if (mounted) _showMessage(error.message.toString());
    } catch (error) {
      if (mounted) _showMessage('Unable to update order: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetCents = parseBudgetToCents(_budgetController.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Order Plan')),
      body: FutureBuilder<_EditOrderData>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load order: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;
          final foods = data.foods;
          final selectedFoods = foods
              .where((food) => _selectedFoodIds.contains(food.id))
              .toList();
          final totalCents = selectedFoods.fold<int>(
            0,
            (sum, food) => sum + food.priceCents,
          );
          final remaining = budgetCents == null
              ? null
              : budgetCents - totalCents;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Edit your saved daily food plan',
                style: TextStyle(
                  color: burgundy,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text('Order ID: ${widget.plan.id}'),
              const SizedBox(height: 20),
              TextField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Target cost per day (CAD)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  errorText: budgetCents == null
                      ? 'Enter a positive amount with up to 2 decimals.'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(formatPlanDate(_selectedDate)),
              ),
              const SizedBox(height: 14),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Updated Order Summary',
                        style: TextStyle(
                          color: burgundy,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Selected foods: ${selectedFoods.length}'),
                      const SizedBox(height: 6),
                      Text(
                        'Budget: ${budgetCents == null ? 'Invalid' : formatCents(budgetCents)}',
                      ),
                      const SizedBox(height: 6),
                      Text('Total: ${formatCents(totalCents)}'),
                      const SizedBox(height: 6),
                      Text(
                        'Remaining: ${remaining == null ? '--' : formatCents(remaining)}',
                      ),
                      if (remaining != null && remaining < 0) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Over budget! Remove an item or raise the budget.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (data.unavailableItems > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Some previously selected foods are no longer on the '
                  'menu. Choose replacements before saving.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveChanges(foods),
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? 'Updating...' : 'Update Order Plan'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose Food Items',
                style: TextStyle(
                  color: burgundy,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              for (final food in foods)
                Card(
                  color: _selectedFoodIds.contains(food.id)
                      ? const Color(0xFFFFE5D1)
                      : Colors.white,
                  child: CheckboxListTile(
                    value: _selectedFoodIds.contains(food.id),
                    activeColor: burgundy,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(food.name),
                    subtitle: Text(food.category),
                    secondary: Text(
                      food.formattedPrice,
                      style: const TextStyle(
                        color: burgundy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onChanged: _isSaving
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedFoodIds.add(food.id);
                              } else {
                                _selectedFoodIds.remove(food.id);
                              }
                            });
                          },
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
