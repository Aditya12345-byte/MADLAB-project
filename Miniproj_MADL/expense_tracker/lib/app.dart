import 'package:flutter/material.dart';
import 'package:expense_tracker/screens/splash_screen.dart';
import 'package:expense_tracker/screens/auth/login_screen.dart';
import 'package:expense_tracker/screens/auth/register_screen.dart';
import 'package:expense_tracker/screens/dashboard/dashboard_screen.dart';
import 'package:expense_tracker/screens/transactions/add_transaction_screen.dart';
import 'package:expense_tracker/screens/transactions/transaction_list_screen.dart';
import 'package:expense_tracker/screens/transactions/transaction_details_screen.dart';
import 'package:expense_tracker/screens/budget/budget_screen.dart';
import 'package:expense_tracker/screens/budget/add_budget_screen.dart';
import 'package:expense_tracker/screens/analytics/analytics_screen.dart';
import 'package:expense_tracker/screens/goals/goals_screen.dart';
import 'package:expense_tracker/screens/goals/add_goal_screen.dart';
import 'package:expense_tracker/screens/settings/settings_screen.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseTrackerApp extends StatefulWidget {
  final AuthService authService;
  final DatabaseService databaseService;

  const ExpenseTrackerApp({
    Key? key,
    required this.authService,
    required this.databaseService,
  }) : super(key: key);

  @override
  _ExpenseTrackerAppState createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('darkMode') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Expense Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(authService: widget.authService),
        '/register': (context) => RegisterScreen(authService: widget.authService),
        '/dashboard': (context) => DashboardScreen(
              authService: widget.authService,
              databaseService: widget.databaseService,
            ),
        '/add-expense': (context) => AddTransactionScreen(
              type: TransactionType.expense,
              authService: widget.authService,
              databaseService: widget.databaseService,
            ),
        '/add-income': (context) => AddTransactionScreen(
              type: TransactionType.income,
              authService: widget.authService,
              databaseService: widget.databaseService,
            ),
        '/transactions': (context) => TransactionListScreen(
              authService: widget.authService,
              databaseService: widget.databaseService,
            ),
        '/transaction-details': (context) => TransactionDetailsScreen(
              transactionId: ModalRoute.of(context)!.settings.arguments as String,
              authService: widget.authService,
              databaseService: widget.databaseService,
            ),
        '/budget': (context) => BudgetScreen(
              databaseService: widget.databaseService,
              authService: widget.authService,
            ),
        '/add-budget': (context) => AddBudgetScreen(
              databaseService: widget.databaseService,
              authService: widget.authService,
            ),
        '/edit-budget': (context) => AddBudgetScreen(
              databaseService: widget.databaseService,
              authService: widget.authService,
              budgetId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/analytics': (context) => AnalyticsScreen(databaseService: widget.databaseService),
        '/goals': (context) => GoalsScreen(databaseService: widget.databaseService, authService: widget.authService),
        '/add-goal': (context) => AddGoalScreen(databaseService: widget.databaseService, authService: widget.authService),
        '/edit-goal': (context) => AddGoalScreen(
          databaseService: widget.databaseService,
          authService: widget.authService,
          goalId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/settings': (context) => SettingsScreen(
              authService: widget.authService,
              databaseService: widget.databaseService,
            ),
      },
    );
  }
}