import 'package:flutter/material.dart';
import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final authService = AuthService();
  final databaseService = DatabaseService();
  await databaseService.initialize();
  
  runApp(ExpenseTrackerApp(
    authService: authService,
    databaseService: databaseService,
  ));
}