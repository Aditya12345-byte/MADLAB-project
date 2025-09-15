import 'package:flutter/material.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:expense_tracker/widgets/transaction_list_item.dart';
import 'package:expense_tracker/widgets/summary_card.dart';
import 'package:expense_tracker/widgets/chart_card.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  final DatabaseService databaseService;

  const DashboardScreen({
    Key? key,
    required this.authService,
    required this.databaseService,
  }) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _userName = '';
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  List<Transaction> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = await widget.authService.getCurrentUser();
      if (user == null) {
        // Navigate to login if no user found
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Set user name
      _userName = user.name;

      // Get transactions for the current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final transactions = await widget.databaseService.getTransactions(
        userId: user.id,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Calculate totals
      double income = 0;
      double expense = 0;

      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      // Get recent transactions (last 5)
      final recentTransactions = transactions
        ..sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _balance = income - expense;
        _recentTransactions = recentTransactions.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Balance: ₹${_balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Transactions'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to transactions screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/analytics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Budget'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/budget');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Goals'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/goals');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await widget.authService.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Hello, $_userName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to your financial dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Income',
                            amount: _totalIncome,
                            icon: Icons.arrow_downward,
                            iconColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SummaryCard(
                            title: 'Expense',
                            amount: _totalExpense,
                            icon: Icons.arrow_upward,
                            iconColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SummaryCard(
                      title: 'Balance',
                      amount: _balance,
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.blue,
                      isLarge: true,
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Add Expense',
                            icon: Icons.remove_circle_outline,
                            backgroundColor: Colors.red,
                            onPressed: () {
                              Navigator.of(context).pushNamed('/add-expense');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Add Income',
                            icon: Icons.add_circle_outline,
                            backgroundColor: Colors.green,
                            onPressed: () {
                              Navigator.of(context).pushNamed('/add-income');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'View Budget',
                            icon: Icons.pie_chart_outline,
                            backgroundColor: Colors.orange,
                            onPressed: () {
                              Navigator.of(context).pushNamed('/budget');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Set Goals',
                            icon: Icons.flag_outlined,
                            backgroundColor: Colors.purple,
                            onPressed: () {
                              Navigator.of(context).pushNamed('/goals');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Spending Chart
                    const Text(
                      'Monthly Spending',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ChartCard(
                      income: _totalIncome,
                      expense: _totalExpense,
                    ),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to all transactions
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _recentTransactions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No transactions yet. Add your first transaction!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentTransactions.length,
                            itemBuilder: (context, index) {
                              return TransactionListItem(
                                transaction: _recentTransactions[index],
                                onTap: () {
                                  // Navigate to transaction details
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Add Expense',
                    icon: Icons.remove_circle_outline,
                    backgroundColor: Colors.red,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/add-expense');
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Add Income',
                    icon: Icons.add_circle_outline,
                    backgroundColor: Colors.green,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/add-income');
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}