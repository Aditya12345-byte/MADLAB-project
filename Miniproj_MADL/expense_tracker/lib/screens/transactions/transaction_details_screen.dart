import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String transactionId;
  final AuthService authService;
  final DatabaseService databaseService;

  const TransactionDetailsScreen({
    Key? key,
    required this.transactionId,
    required this.authService,
    required this.databaseService,
  }) : super(key: key);

  @override
  _TransactionDetailsScreenState createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool _isLoading = true;
  Transaction? _transaction;
  Category? _category;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load transaction
      final transaction = await widget.databaseService.getTransactionById(widget.transactionId);
      if (transaction == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Load category
      final categories = await widget.databaseService.getCategories();
      final category = categories.firstWhere(
        (c) => c.id == transaction.categoryId,
        orElse: () => Category(
          id: 'unknown',
          name: 'Unknown',
          icon: Icons.help_outline.codePoint,
          color: Colors.grey.value,
          type: transaction.type,
        ),
      );

      if (mounted) {
        setState(() {
          _transaction = transaction;
          _category = category;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transaction details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load transaction details')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTransaction() async {
    if (_transaction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.databaseService.deleteTransaction(_transaction!.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate changes
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete transaction')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(child: Text('Transaction not found')),
      );
    }

    final isIncome = _transaction!.type == TransactionType.income;
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/edit-transaction',
                arguments: _transaction!.id,
              ).then((changed) {
                if (changed == true) {
                  _loadTransactionDetails();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with amount and type
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    isIncome ? 'Income' : 'Expense',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_transaction!.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(_transaction!.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transaction details
            _buildDetailItem(
              'Title',
              _transaction!.title,
              Icons.title,
            ),
            _buildDetailItem(
              'Category',
              _category?.name ?? 'Unknown',
              IconData(_category?.icon ?? Icons.category.codePoint,
                  fontFamily: 'MaterialIcons'),
              iconColor: _category != null ? Color(_category!.color) : null,
            ),
            _buildDetailItem(
              'Date',
              dateFormat.format(_transaction!.date),
              Icons.calendar_today,
            ),
            if (_transaction!.notes.isNotEmpty)
              _buildDetailItem(
                'Notes',
                _transaction!.notes,
                Icons.note,
              ),
            _buildDetailItem(
              'Created',
              '${dateFormat.format(_transaction!.createdAt)} at ${timeFormat.format(_transaction!.createdAt)}',
              Icons.access_time,
            ),
            const SizedBox(height: 24),

            // Delete button
            CustomButton(
              text: 'Delete Transaction',
              icon: Icons.delete,
              backgroundColor: Colors.red,
              onPressed: _deleteTransaction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData iconData,
      {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}