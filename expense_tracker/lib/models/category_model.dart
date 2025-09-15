import 'package:flutter/material.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final Color color;
  final IconData icon;
  final bool isDefault;
  final bool isExpense; // true for expense, false for income
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.icon,
    this.isDefault = false,
    required this.isExpense,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      color: Color(json['color']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      isDefault: json['isDefault'] ?? false,
      isExpense: json['isExpense'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
      'isDefault': isDefault,
      'isExpense': isExpense,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    Color? color,
    IconData? icon,
    bool? isDefault,
    bool? isExpense,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isExpense: isExpense ?? this.isExpense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Default categories for expenses
final List<Category> defaultExpenseCategories = [
  Category(
    id: 'exp-food',
    userId: 'default',
    name: 'Food & Dining',
    color: Colors.orange,
    icon: Icons.restaurant,
    isDefault: true,
    isExpense: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'exp-transport',
    userId: 'default',
    name: 'Transportation',
    color: Colors.blue,
    icon: Icons.directions_car,
    isDefault: true,
    isExpense: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'exp-shopping',
    userId: 'default',
    name: 'Shopping',
    color: Colors.purple,
    icon: Icons.shopping_bag,
    isDefault: true,
    isExpense: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'exp-bills',
    userId: 'default',
    name: 'Bills & Utilities',
    color: Colors.red,
    icon: Icons.receipt,
    isDefault: true,
    isExpense: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'exp-entertainment',
    userId: 'default',
    name: 'Entertainment',
    color: Colors.pink,
    icon: Icons.movie,
    isDefault: true,
    isExpense: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'exp-health',
    userId: 'default',
    name: 'Health & Medical',
    color: Colors.green,
    icon: Icons.medical_services,
    isDefault: true,
    isExpense: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

// Default categories for income
final List<Category> defaultIncomeCategories = [
  Category(
    id: 'inc-salary',
    userId: 'default',
    name: 'Salary',
    color: Colors.green,
    icon: Icons.work,
    isDefault: true,
    isExpense: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'inc-freelance',
    userId: 'default',
    name: 'Freelance',
    color: Colors.blue,
    icon: Icons.computer,
    isDefault: true,
    isExpense: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'inc-investment',
    userId: 'default',
    name: 'Investments',
    color: Colors.amber,
    icon: Icons.trending_up,
    isDefault: true,
    isExpense: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Category(
    id: 'inc-gifts',
    userId: 'default',
    name: 'Gifts',
    color: Colors.purple,
    icon: Icons.card_giftcard,
    isDefault: true,
    isExpense: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];