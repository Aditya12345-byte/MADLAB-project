import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    this.onTap,
  }) : super(key: key);

  @override
  _TransactionListItemState createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem> {
  Category? _category;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    try {
      final categories = await _databaseService.getCategories();
      final category = categories.firstWhere(
        (c) => c.id == widget.transaction.categoryId,
        orElse: () => Category(
          id: 'unknown',
          name: 'Unknown',
          icon: Icons.help_outline.codePoint,
          color: Colors.grey.value,
          type: widget.transaction.type,
        ),
      );

      if (mounted) {
        setState(() {
          _category = category;
        });
      }
    } catch (e) {
      debugPrint('Error loading category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == TransactionType.income;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormat.format(widget.transaction.date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _category != null
                      ? Color(_category!.color).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _category != null
                      ? IconData(_category!.icon, fontFamily: 'MaterialIcons')
                      : Icons.help_outline,
                  color: _category != null
                      ? Color(_category!.color)
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _category?.name ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '${isIncome ? '+' : '-'}₹${widget.transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}