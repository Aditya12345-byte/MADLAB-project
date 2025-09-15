import 'package:flutter/material.dart';
import 'package:expense_tracker/models/goal_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:expense_tracker/widgets/custom_text_field.dart';
import 'package:expense_tracker/utils/validators.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddGoalScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final AuthService authService;
  final String? goalId; // If provided, we're editing an existing goal

  const AddGoalScreen({
    Key? key,
    required this.databaseService,
    required this.authService,
    this.goalId,
  }) : super(key: key);

  @override
  _AddGoalScreenState createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  
  String? _userId;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  bool _isLoading = false;
  bool _isEditing = false;
  Goal? _existingGoal;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.goalId != null;
    _loadUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
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

        // If editing, load the existing goal
        if (_isEditing && widget.goalId != null) {
          final goal = await widget.databaseService.getGoalById(widget.goalId!);
          if (goal != null) {
            setState(() {
              _existingGoal = goal;
              _titleController.text = goal.title;
              _descriptionController.text = goal.description ?? '';
              _targetAmountController.text = goal.targetAmount.toString();
              _currentAmountController.text = goal.currentAmount.toString();
              _targetDate = goal.targetDate;
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

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final targetAmount = double.parse(_targetAmountController.text);
      final currentAmount = double.parse(_currentAmountController.text);
      
      final now = DateTime.now();
      
      if (_isEditing && _existingGoal != null) {
        // Update existing goal
        final updatedGoal = Goal(
          id: _existingGoal!.id,
          userId: _userId!,
          title: title,
          description: description.isNotEmpty ? description : null,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          targetDate: _targetDate,
          createdAt: _existingGoal!.createdAt,
          updatedAt: now,
        );
        
        await widget.databaseService.updateGoal(updatedGoal);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated successfully')),
        );
      } else {
        // Create new goal
        final newGoal = Goal(
          id: const Uuid().v4(),
          userId: _userId!,
          title: title,
          description: description.isNotEmpty ? description : null,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          targetDate: _targetDate,
          createdAt: now,
          updatedAt: now,
        );
        
        await widget.databaseService.addGoal(newGoal);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal created successfully')),
        );
      }
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goal: $e')),
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
        title: Text(_isEditing ? 'Edit Goal' : 'Add Goal'),
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
                    // Title field
                    CustomTextField(
                      controller: _titleController,
                      labelText: 'Goal Title',
                      hintText: 'Enter goal title',
                      prefixIcon: Icons.title,
                      validator: Validators.validateTitle,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    CustomTextField(
                      controller: _descriptionController,
                      labelText: 'Description (Optional)',
                      hintText: 'Enter goal description',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Target amount field
                    CustomTextField(
                      controller: _targetAmountController,
                      labelText: 'Target Amount',
                      hintText: 'Enter target amount',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                    ),
                    const SizedBox(height: 16),
                    
                    // Current amount field
                    CustomTextField(
                      controller: _currentAmountController,
                      labelText: 'Current Savings',
                      hintText: 'Enter current savings amount',
                      prefixIcon: Icons.savings,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                    ),
                    const SizedBox(height: 16),
                    
                    // Target date selector
                    const Text(
                      'Target Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    
                    // Save button
                    CustomButton(
                      onPressed: _saveGoal,
                      text: _isEditing ? 'Update Goal' : 'Create Goal',
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

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('MMM d, yyyy');
    return InkWell(
      onTap: () => _selectTargetDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(_targetDate),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}