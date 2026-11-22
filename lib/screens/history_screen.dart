import 'package:material_ui/material_ui.dart';

import '../data/order_history_repository.dart';
import '../models/order_plan.dart';
import '../utils/budget_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const burgundy = Color(0xFF7A2329);

  final _repository = OrderHistoryRepository.instance;

  late Future<List<OrderPlan>> _plansFuture;

  DateTime _selectedDate = DateTime.now();
  OrderPlan? _searchResult;

  bool _hasSearched = false;
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _plansFuture = _repository.getAllPlans();
  }

  // Display a message when an operation fails.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Choose the date to search.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDate = picked;
      _hasSearched = false;
      _searchResult = null;
      _searchError = null;
    });
  }

  // Find an order plan matching the selected date.
  Future<void> _searchByDate() async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final plan = await _repository.getPlanByDate(_selectedDate);

      if (!mounted) return;

      setState(() {
        _searchResult = plan;
        _hasSearched = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _searchError = 'Search failed: $error';
        _hasSearched = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Refresh the saved order list from SQLite.
  void _refreshPlans() {
    setState(() {
      _plansFuture = _repository.getAllPlans();
      _hasSearched = false;
      _searchResult = null;
      _searchError = null;
    });
  }

  // Display one saved order and its selected foods.
  Future<void> _showPlanDetails(OrderPlan plan) async {
    try {
      final items = await _repository.getPlanItems(plan.id);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Saved Order Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${plan.id}'),
                  const SizedBox(height: 8),
                  Text('Date: ${plan.planDate}'),
                  const SizedBox(height: 8),
                  Text(
                    'Target: '
                    '${formatCents(plan.targetCents)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: '
                    '${formatCents(plan.totalCents)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 28),
                  const Text(
                    'Selected Foods',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty) const Text('No food items found.'),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text(formatCents(item.priceCents)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Cannot load order details: $error');
      }
    }
  }

  // Card used for both search results and history.
  Widget _buildPlanCard(OrderPlan plan) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        isThreeLine: true,
        leading: const Icon(Icons.receipt_long, color: burgundy),
        title: Text(
          plan.planDate,
          style: const TextStyle(fontWeight: FontWeight.bold, color: burgundy),
        ),
        subtitle: Text(
          'Daily target: '
          '${formatCents(plan.targetCents)}\n'
          'Order total: '
          '${formatCents(plan.totalCents)}',
        ),
        trailing: const Icon(Icons.chevron_right, color: burgundy),
        onTap: () {
          _showPlanDetails(plan);
        },
      ),
    );
  }

  // Build the complete saved order history.
  Widget _buildHistoryList() {
    return FutureBuilder<List<OrderPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Unable to load order history: '
            '${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final plans = snapshot.data ?? [];

        if (plans.isEmpty) {
          return const Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No saved orders yet. '
                'Create a daily order plan first.',
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${plans.length} saved order plan(s)'),
            const SizedBox(height: 12),

            // Plans are already sorted in SQL.
            for (final plan in plans) _buildPlanCard(plan),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPlans,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Find an Order Plan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: burgundy,
            ),
          ),
          const SizedBox(height: 10),
          const Text('Choose a date to search for a saved order.'),
          const SizedBox(height: 16),

          // Date picker.
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text(formatPlanDate(_selectedDate)),
            onPressed: _pickDate,
          ),

          const SizedBox(height: 12),

          // Search button.
          ElevatedButton.icon(
            onPressed: _isSearching ? null : _searchByDate,
            icon: const Icon(Icons.search),
            label: Text(_isSearching ? 'Searching...' : 'Search Order'),
          ),

          const SizedBox(height: 20),

          // Display query errors.
          if (_searchError != null)
            Text(_searchError!, style: const TextStyle(color: Colors.red)),

          // Show found and not-found search results.
          if (_hasSearched) ...[
            const Text(
              'Search Result',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: burgundy,
              ),
            ),
            const SizedBox(height: 12),

            if (_searchResult == null)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No order plan found for '
                    '${formatPlanDate(_selectedDate)}.',
                  ),
                ),
              )
            else
              _buildPlanCard(_searchResult!),

            const SizedBox(height: 20),
          ],

          const Divider(height: 32),

          const Text(
            'All Saved Orders',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: burgundy,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Order plans sorted by date, newest first.'),
          const SizedBox(height: 16),

          // Database-backed order history list.
          _buildHistoryList(),
        ],
      ),
    );
  }
}
