import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/widgets/transaction_list_item.dart';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends StatefulWidget {
  final AuthService authService;
  final DatabaseService databaseService;

  const TransactionListScreen({
    Key? key,
    required this.authService,
    required this.databaseService,
  }) : super(key: key);

  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String? _userId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _filterTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await widget.authService.getCurrentUser();
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      _userId = user.id;

      final transactions = await widget.databaseService.getTransactions(
        userId: user.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _allTransactions = transactions;
        _filterTransactions();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    if (_allTransactions.isEmpty) {
      setState(() {
        _filteredTransactions = [];
      });
      return;
    }

    List<Transaction> filtered = [];

    // Filter by tab (All, Income, Expense)
    switch (_tabController.index) {
      case 0: // All
        filtered = List.from(_allTransactions);
        break;
      case 1: // Income
        filtered = _allTransactions
            .where((transaction) => transaction.type == TransactionType.income)
            .toList();
        break;
      case 2: // Expense
        filtered = _allTransactions
            .where((transaction) => transaction.type == TransactionType.expense)
            .toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((transaction) =>
              transaction.title.toLowerCase().contains(query) ||
              transaction.notes.toLowerCase().contains(query))
          .toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(String id) async {
    try {
      final success = await widget.databaseService.deleteTransaction(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
        _loadTransactions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date range and search
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Date range display
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _selectDateRange(context),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Search field
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search transactions',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _filterTransactions();
                        },
                      ),
                    ],
                  ),
                ),
                // Transaction list
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try a different search term'
                                    : 'Add your first transaction',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_searchQuery.isEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomButton(
                                      text: 'Add Expense',
                                      icon: Icons.remove_circle_outline,
                                      backgroundColor: Colors.red,
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/add-expense');
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    CustomButton(
                                      text: 'Add Income',
                                      icon: Icons.add_circle_outline,
                                      backgroundColor: Colors.green,
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/add-income');
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTransactions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];
                              return Dismissible(
                                key: Key(transaction.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: const Text(
                                            'Are you sure you want to delete this transaction?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) {
                                  _deleteTransaction(transaction.id);
                                },
                                child: TransactionListItem(
                                  transaction: transaction,
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      '/transaction-details',
                                      arguments: transaction.id,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
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