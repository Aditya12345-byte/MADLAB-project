import 'package:flutter/material.dart';
import 'package:expense_tracker/models/budget_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final AuthService? authService;

  const BudgetScreen({
    Key? key,
    required this.databaseService,
    this.authService,
  }) : super(key: key);

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Budget> _budgets = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.authService != null) {
      final user = await widget.authService!.getCurrentUser();
      if (user != null) {
        setState(() {
          _userId = user.id;
        });
        _loadBudgets();
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      // For preview or testing without auth
      setState(() {
        _userId = 'test-user';
      });
      _loadBudgets();
    }
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final budgets = await widget.databaseService.getBudgets(_userId!);
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budgets: $e')),
      );
    }
  }

  void _navigateToAddBudget() {
    Navigator.of(context).pushNamed('/add-budget').then((_) {
      _loadBudgets();
    });
  }

  void _navigateToEditBudget(Budget budget) {
    Navigator.of(context).pushNamed(
      '/edit-budget',
      arguments: budget.id,
    ).then((_) {
      _loadBudgets();
    });
  }

  Future<void> _deleteBudget(Budget budget) async {
    try {
      await widget.databaseService.deleteBudget(budget.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted successfully')),
      );
      _loadBudgets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting budget: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudgets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? _buildEmptyState()
              : _buildBudgetList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBudget,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No budgets yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a budget to track your spending',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: _navigateToAddBudget,
            text: 'Create Budget',
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _budgets.length,
      itemBuilder: (context, index) {
        final budget = _budgets[index];
        return _buildBudgetCard(budget);
      },
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final percentUsed = budget.percentageUsed.clamp(0.0, 100.0);
    final isOverBudget = budget.isOverBudget;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditBudget(budget),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      budget.category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditBudget(budget);
                      } else if (value == 'delete') {
                        _deleteBudget(budget);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${dateFormat.format(budget.startDate)} - ${dateFormat.format(budget.endDate)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: \$${budget.spentAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOverBudget ? Colors.red : Colors.black,
                      fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    'Budget: \$${budget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentUsed / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: \$${budget.remainingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOverBudget ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${percentUsed.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isOverBudget ? Colors.red : Colors.black,
                      fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}