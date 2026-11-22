import 'package:material_ui/material_ui.dart';

import '../data/food_repository.dart';
import '../data/restaurant_database.dart';
import '../models/food_item.dart';

const _burgundy = Color(0xFF7A2329);

// Displays the SQLite menu and provides CRUD operations.
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
    _foodItemsFuture = RestaurantDatabase.instance.getAllFoodItems();
  }

  // Reload the menu after changes to the database.
  void _refreshMenu() {
    setState(() {
      _foodItemsFuture = RestaurantDatabase.instance.getAllFoodItems();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Show the form for adding a food.
  Future<void> _addFood() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => const _FoodFormDialog(),
    );

    if (!mounted) return;

    if (saved == true) {
      _refreshMenu();
      _showMessage('Food item added successfully.');
    }
  }

  // Show the form with existing values for editing.
  Future<void> _editFood(FoodItem food) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _FoodFormDialog(food: food),
    );

    if (!mounted) return;

    if (saved == true) {
      _refreshMenu();
      _showMessage('Food item updated successfully.');
    }
  }

  // Confirm before deleting a food.
  Future<void> _deleteFood(FoodItem food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food Item?'),
        content: Text(
          'Are you sure you want to delete '
          '"${food.name}" from the menu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final deleted = await FoodRepository.instance.deleteFoodItem(food.id);

      if (!mounted) return;

      if (deleted == 0) {
        _showMessage('Food item was not found.');
        return;
      }

      _refreshMenu();
      _showMessage('Food item deleted successfully.');
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to delete food: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spice Garden Menu'),
        actions: [
          IconButton(
            tooltip: 'Refresh menu',
            onPressed: _refreshMenu,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFood,
        backgroundColor: _burgundy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),

      body: FutureBuilder<List<FoodItem>>(
        future: _foodItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Database error: ${snapshot.error}'));
          }

          final foods = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 42,
                      color: _burgundy,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${foods.length} menu items available',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: _burgundy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Freshly prepared Indian favourites'),
                  ],
                ),
              ),

              Expanded(
                child: foods.isEmpty
                    ? const Center(child: Text('No food items available.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        itemCount: foods.length,
                        itemBuilder: (context, index) {
                          final food = foods[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFF1DFD2),
                                child: Icon(Icons.restaurant, color: _burgundy),
                              ),
                              title: Text(
                                food.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(food.category),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    food.formattedPrice,
                                    style: const TextStyle(
                                      color: _burgundy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit ${food.name}',
                                    icon: const Icon(
                                      Icons.edit,
                                      color: _burgundy,
                                    ),
                                    onPressed: () => _editFood(food),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete ${food.name}',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteFood(food),
                                  ),
                                ],
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

// Form used for both adding and updating food items.
class _FoodFormDialog extends StatefulWidget {
  final FoodItem? food;

  const _FoodFormDialog({this.food});

  @override
  State<_FoodFormDialog> createState() => _FoodFormDialogState();
}

class _FoodFormDialogState extends State<_FoodFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.food?.name ?? '');

    _categoryController = TextEditingController(
      text: widget.food?.category ?? '',
    );

    _priceController = TextEditingController(
      text: widget.food == null
          ? ''
          : (widget.food!.priceCents / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Convert a validated dollar amount into integer cents.
  int _parsePriceCents(String value) {
    final parts = value.trim().split('.');
    final dollars = int.parse(parts[0]);

    final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));

    return dollars * 100 + cents;
  }

  // Validate and write the food to SQLite.
  Future<void> _saveFood() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final name = _nameController.text.trim();
      final category = _categoryController.text.trim();
      final priceCents = _parsePriceCents(_priceController.text);

      if (widget.food == null) {
        await FoodRepository.instance.addFoodItem(
          name: name,
          category: category,
          priceCents: priceCents,
        );
      } else {
        final updated = await FoodRepository.instance.updateFoodItem(
          id: widget.food!.id,
          name: name,
          category: category,
          priceCents: priceCents,
        );

        if (updated == 0) {
          throw StateError('Food item no longer exists.');
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to save food: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.food != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Food Item' : 'Add Food Item'),

      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Food Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a food name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a category.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price (CAD)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  final validFormat = RegExp(r'^\d+(\.\d{1,2})?$')
                      .hasMatch(text);

                  if (!validFormat) {
                    return 'Enter a valid price (e.g. 12.50).';
                  }

                  if (_parsePriceCents(text) <= 0) {
                    return 'Price must be greater than zero.';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveFood,
          child: Text(
            _saving
                ? 'Saving...'
                : isEditing
                ? 'Update'
                : 'Add',
          ),
        ),
      ],
    );
  }
}
