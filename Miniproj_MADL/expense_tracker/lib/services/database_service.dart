import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/models/user_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/budget_model.dart';
import 'package:expense_tracker/models/goal_model.dart';
import 'package:expense_tracker/models/category_model.dart';

class DatabaseService {
  // Storage keys
  static const String _transactionsKey = 'transactions';
  static const String _budgetsKey = 'budgets';
  static const String _goalsKey = 'goals';
  static const String _categoriesKey = 'categories';

  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Initialize default categories if not exists
  Future<void> initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if categories exist, if not create default ones
    if (!prefs.containsKey(_categoriesKey)) {
      final defaultCategories = [
        ...Category.defaultExpenseCategories,
        ...Category.defaultIncomeCategories,
      ];
      
      final categoriesJson = defaultCategories
          .map((category) => jsonEncode(category.toJson()))
          .toList();
      
      await prefs.setStringList(_categoriesKey, categoriesJson);
    }
  }

  // TRANSACTIONS
  Future<List<Transaction>> getTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    List<Transaction> transactions = transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .where((transaction) => transaction.userId == userId)
        .toList();
    
    // Filter by date range if provided
    if (startDate != null) {
      transactions = transactions
          .where((transaction) => transaction.date.isAfter(startDate) || 
                                  transaction.date.isAtSameMomentAs(startDate))
          .toList();
    }
    
    if (endDate != null) {
      transactions = transactions
          .where((transaction) => transaction.date.isBefore(endDate) || 
                                  transaction.date.isAtSameMomentAs(endDate))
          .toList();
    }
    
    return transactions;
  }

  Future<Transaction?> getTransactionById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    try {
      return transactionsJson
          .map((json) => Transaction.fromJson(jsonDecode(json)))
          .firstWhere((transaction) => transaction.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    // Add new transaction
    transactionsJson.add(jsonEncode(transaction.toJson()));
    
    return await prefs.setStringList(_transactionsKey, transactionsJson);
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    // Convert to list of transactions
    final transactions = transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
    
    // Find and update transaction
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      
      // Convert back to JSON strings
      final updatedJson = transactions
          .map((transaction) => jsonEncode(transaction.toJson()))
          .toList();
      
      return await prefs.setStringList(_transactionsKey, updatedJson);
    }
    
    return false;
  }

  Future<bool> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    // Convert to list of transactions
    final transactions = transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
    
    // Remove transaction
    final initialLength = transactions.length;
    transactions.removeWhere((transaction) => transaction.id == id);
    
    if (transactions.length < initialLength) {
      // Convert back to JSON strings
      final updatedJson = transactions
          .map((transaction) => jsonEncode(transaction.toJson()))
          .toList();
      
      return await prefs.setStringList(_transactionsKey, updatedJson);
    }
    
    return false;
  }

  // BUDGETS
  Future<List<Budget>> getBudgets(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = prefs.getStringList(_budgetsKey) ?? [];
    
    return budgetsJson
        .map((json) => Budget.fromJson(jsonDecode(json)))
        .where((budget) => budget.userId == userId)
        .toList();
  }

  Future<Budget?> getBudgetById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = prefs.getStringList(_budgetsKey) ?? [];
    
    try {
      return budgetsJson
          .map((json) => Budget.fromJson(jsonDecode(json)))
          .firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addBudget(Budget budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = prefs.getStringList(_budgetsKey) ?? [];
    
    // Add new budget
    budgetsJson.add(jsonEncode(budget.toJson()));
    
    return await prefs.setStringList(_budgetsKey, budgetsJson);
  }

  Future<bool> updateBudget(Budget budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = prefs.getStringList(_budgetsKey) ?? [];
    
    // Convert to list of budgets
    final budgets = budgetsJson
        .map((json) => Budget.fromJson(jsonDecode(json)))
        .toList();
    
    // Find and update budget
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      budgets[index] = budget;
      
      // Convert back to JSON strings
      final updatedJson = budgets
          .map((budget) => jsonEncode(budget.toJson()))
          .toList();
      
      return await prefs.setStringList(_budgetsKey, updatedJson);
    }
    
    return false;
  }

  Future<bool> deleteBudget(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = prefs.getStringList(_budgetsKey) ?? [];
    
    // Convert to list of budgets
    final budgets = budgetsJson
        .map((json) => Budget.fromJson(jsonDecode(json)))
        .toList();
    
    // Remove budget
    final initialLength = budgets.length;
    budgets.removeWhere((budget) => budget.id == id);
    
    if (budgets.length < initialLength) {
      // Convert back to JSON strings
      final updatedJson = budgets
          .map((budget) => jsonEncode(budget.toJson()))
          .toList();
      
      return await prefs.setStringList(_budgetsKey, updatedJson);
    }
    
    return false;
  }

  // GOALS
  Future<List<Goal>> getGoals(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    
    return goalsJson
        .map((json) => Goal.fromJson(jsonDecode(json)))
        .where((goal) => goal.userId == userId)
        .toList();
  }

  Future<Goal?> getGoalById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    
    try {
      return goalsJson
          .map((json) => Goal.fromJson(jsonDecode(json)))
          .firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    
    // Add new goal
    goalsJson.add(jsonEncode(goal.toJson()));
    
    return await prefs.setStringList(_goalsKey, goalsJson);
  }

  Future<bool> updateGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    
    // Convert to list of goals
    final goals = goalsJson
        .map((json) => Goal.fromJson(jsonDecode(json)))
        .toList();
    
    // Find and update goal
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      
      // Convert back to JSON strings
      final updatedJson = goals
          .map((goal) => jsonEncode(goal.toJson()))
          .toList();
      
      return await prefs.setStringList(_goalsKey, updatedJson);
    }
    
    return false;
  }

  Future<bool> deleteGoal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    
    // Convert to list of goals
    final goals = goalsJson
        .map((json) => Goal.fromJson(jsonDecode(json)))
        .toList();
    
    // Remove goal
    final initialLength = goals.length;
    goals.removeWhere((goal) => goal.id == id);
    
    if (goals.length < initialLength) {
      // Convert back to JSON strings
      final updatedJson = goals
          .map((goal) => jsonEncode(goal.toJson()))
          .toList();
      
      return await prefs.setStringList(_goalsKey, updatedJson);
    }
    
    return false;
  }

  // CATEGORIES
  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
    
    return categoriesJson
        .map((json) => Category.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<Category>> getCategoriesByType(TransactionType type) async {
    final categories = await getCategories();
    return categories.where((category) => category.type == type).toList();
  }

  Future<bool> addCategory(Category category) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
    
    // Add new category
    categoriesJson.add(jsonEncode(category.toJson()));
    
    return await prefs.setStringList(_categoriesKey, categoriesJson);
  }

  Future<bool> updateCategory(Category category) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
    
    // Convert to list of categories
    final categories = categoriesJson
        .map((json) => Category.fromJson(jsonDecode(json)))
        .toList();
    
    // Find and update category
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      
      // Convert back to JSON strings
      final updatedJson = categories
          .map((category) => jsonEncode(category.toJson()))
          .toList();
      
      return await prefs.setStringList(_categoriesKey, updatedJson);
    }
    
    return false;
  }

  Future<bool> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
    
    // Convert to list of categories
    final categories = categoriesJson
        .map((json) => Category.fromJson(jsonDecode(json)))
        .toList();
    
    // Remove category
    final initialLength = categories.length;
    categories.removeWhere((category) => category.id == id);
    
    if (categories.length < initialLength) {
      // Convert back to JSON strings
      final updatedJson = categories
          .map((category) => jsonEncode(category.toJson()))
          .toList();
      
      return await prefs.setStringList(_categoriesKey, updatedJson);
    }
    
    return false;
  }

  // STATISTICS AND REPORTS
  Future<Map<String, double>> getCategoryTotals({
    required String userId,
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    final filteredTransactions = transactions
        .where((transaction) => transaction.type == type)
        .toList();
    
    final Map<String, double> categoryTotals = {};
    
    for (final transaction in filteredTransactions) {
      final categoryId = transaction.categoryId;
      final amount = transaction.amount;
      
      if (categoryTotals.containsKey(categoryId)) {
        categoryTotals[categoryId] = categoryTotals[categoryId]! + amount;
      } else {
        categoryTotals[categoryId] = amount;
      }
    }
    
    return categoryTotals;
  }

  Future<Map<DateTime, double>> getDailyTotals({
    required String userId,
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    final filteredTransactions = transactions
        .where((transaction) => transaction.type == type)
        .toList();
    
    final Map<DateTime, double> dailyTotals = {};
    
    for (final transaction in filteredTransactions) {
      // Normalize date to remove time component
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      final amount = transaction.amount;
      
      if (dailyTotals.containsKey(date)) {
        dailyTotals[date] = dailyTotals[date]! + amount;
      } else {
        dailyTotals[date] = amount;
      }
    }
    
    return dailyTotals;
  }

  Future<Map<int, double>> getMonthlyTotals({
    required String userId,
    required TransactionType type,
    required int year,
  }) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    
    final transactions = await getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    
    final filteredTransactions = transactions
        .where((transaction) => transaction.type == type)
        .toList();
    
    final Map<int, double> monthlyTotals = {};
    
    for (final transaction in filteredTransactions) {
      final month = transaction.date.month;
      final amount = transaction.amount;
      
      if (monthlyTotals.containsKey(month)) {
        monthlyTotals[month] = monthlyTotals[month]! + amount;
      } else {
        monthlyTotals[month] = amount;
      }
    }
    
    return monthlyTotals;
  }
}