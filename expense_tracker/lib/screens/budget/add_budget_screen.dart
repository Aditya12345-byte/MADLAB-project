import 'package:flutter/material.dart';
import 'package:expense_tracker/models/budget_model.dart';
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:expense_tracker/widgets/custom_text_field.dart';
import 'package:expense_tracker/utils/validators.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddBudgetScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final AuthService authService;
  final String? budgetId; // If provided, we're editing an existing budget

  const AddBudgetScreen({
    Key? key,
    required this.databaseService,
    required this.authService,
    this.budgetId,
  }) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String? _userId;
  String? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  bool _isEditing = false;
  Budget? _existingBudget;
  List<Category> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.budgetId != null;
    _loadUserData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await widget.authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userId = user.id;
        });
        
        // Load expense categories
        final categories = await widget.databaseService.getCategories();
        setState(() {
          _expenseCategories = categories.where((c) => c.type == 'expense').toList();
          if (_expenseCategories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _expenseCategories.first.name;
          }
        });

        // If editing, load the existing budget
        if (_isEditing && widget.budgetId != null) {
          final budget = await widget.databaseService.getBudgetById(widget.budgetId!);
          if (budget != null) {
            setState(() {
              _existingBudget = budget;
              _amountController.text = budget.amount.toString();
              _selectedCategory = budget.category;
              _startDate = budget.startDate;
              _endDate = budget.endDate;
            });
          }
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      final now = DateTime.now();
      
      if (_isEditing && _existingBudget != null) {
        // Update existing budget
        final updatedBudget = Budget(
          id: _existingBudget!.id,
          userId: _userId!,
          category: _selectedCategory!,
          amount: amount,
          startDate: _startDate,
          endDate: _endDate,
          spentAmount: _existingBudget!.spentAmount,
          createdAt: _existingBudget!.createdAt,
          updatedAt: now,
        );
        
        await widget.databaseService.updateBudget(updatedBudget);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated successfully')),
        );
      } else {
        // Create new budget
        final newBudget = Budget(
          id: const Uuid().v4(),
          userId: _userId!,
          category: _selectedCategory!,
          amount: amount,
          startDate: _startDate,
          endDate: _endDate,
          spentAmount: 0.0,
          createdAt: now,
          updatedAt: now,
        );
        
        await widget.databaseService.addBudget(newBudget);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget created successfully')),
        );
      }
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving budget: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Budget' : 'Add Budget'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category dropdown
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    
                    // Amount field
                    CustomTextField(
                      controller: _amountController,
                      labelText: 'Budget Amount',
                      hintText: 'Enter budget amount',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                    ),
                    const SizedBox(height: 16),
                    
                    // Date range
                    const Text(
                      'Budget Period',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateSelector(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: () => _selectStartDate(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateSelector(
                            label: 'End Date',
                            date: _endDate,
                            onTap: () => _selectEndDate(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Save button
                    CustomButton(
                      onPressed: _saveBudget,
                      text: _isEditing ? 'Update Budget' : 'Create Budget',
                      isLoading: _isLoading,
                      icon: _isEditing ? Icons.save : Icons.add,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          hint: const Text('Select Category'),
          items: _expenseCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category.name,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}