import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final AuthService? authService;

  const AnalyticsScreen({
    Key? key,
    required this.databaseService,
    this.authService,
  }) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _userId;
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Week', 'Month', 'Year'];

  // Date range for filtering
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (widget.authService != null) {
      final user = await widget.authService!.getCurrentUser();
      if (user != null) {
        setState(() {
          _userId = user.id;
        });
        _loadTransactions();
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      // For preview or testing without auth
      setState(() {
        _userId = 'test-user';
      });
      _loadTransactions();
    }
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Week':
          _startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Month':
          _startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'Year':
          _startDate = DateTime(now.year - 1, now.month, now.day);
          break;
      }
      _endDate = now;
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await widget.databaseService.getTransactionsByDateRange(
        _userId!,
        _startDate,
        _endDate,
      );
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _updateDateRange,
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildIncomeTab(),
                _buildExpensesTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final incomeTransactions = _transactions.where((t) => t.type == TransactionType.income).toList();
    final expenseTransactions = _transactions.where((t) => t.type == TransactionType.expense).toList();
    
    final totalIncome = incomeTransactions.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpense = expenseTransactions.fold(0.0, (sum, item) => sum + item.amount);
    final balance = totalIncome - totalExpense;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(totalIncome, totalExpense, balance),
          const SizedBox(height: 24),
          const Text(
            'Income vs Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBarChart(totalIncome, totalExpense),
          const SizedBox(height: 24),
          const Text(
            'Daily Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLineChart(),
        ],
      ),
    );
  }

  Widget _buildIncomeTab() {
    final incomeTransactions = _transactions.where((t) => t.type == TransactionType.income).toList();
    final totalIncome = incomeTransactions.fold(0.0, (sum, item) => sum + item.amount);
    
    // Group by category
    final categoryMap = <String, double>{};
    for (var transaction in incomeTransactions) {
      final category = transaction.category;
      categoryMap[category] = (categoryMap[category] ?? 0) + transaction.amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Income',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Period: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Income by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPieChart(categoryMap, Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Income Sources',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCategoryList(categoryMap, totalIncome, Colors.green),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    final expenseTransactions = _transactions.where((t) => t.type == TransactionType.expense).toList();
    final totalExpense = expenseTransactions.fold(0.0, (sum, item) => sum + item.amount);
    
    // Group by category
    final categoryMap = <String, double>{};
    for (var transaction in expenseTransactions) {
      final category = transaction.category;
      categoryMap[category] = (categoryMap[category] ?? 0) + transaction.amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalExpense.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Period: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Expenses by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPieChart(categoryMap, Colors.red),
          const SizedBox(height: 24),
          const Text(
            'Expense Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCategoryList(categoryMap, totalExpense, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, double balance) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Income',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${income.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expenses',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${expense.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(double income, double expense) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: math.max(income, expense) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label;
                if (groupIndex == 0) {
                  label = 'Income: \$${income.toStringAsFixed(2)}';
                } else {
                  label = 'Expense: \$${expense.toStringAsFixed(2)}';
                }
                return BarTooltipItem(
                  label,
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  if (value == 0) {
                    text = 'Income';
                  } else if (value == 1) {
                    text = 'Expense';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(text, style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: Colors.green,
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: expense,
                  color: Colors.red,
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    // Group transactions by day
    final Map<DateTime, Map<String, double>> dailyData = {};
    
    for (var transaction in _transactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      dailyData[date] ??= {'income': 0.0, 'expense': 0.0};
      
      if (transaction.type == TransactionType.income) {
        dailyData[date]!['income'] = (dailyData[date]!['income'] ?? 0) + transaction.amount;
      } else {
        dailyData[date]!['expense'] = (dailyData[date]!['expense'] ?? 0) + transaction.amount;
      }
    }
    
    // Sort dates
    final sortedDates = dailyData.keys.toList()..sort();
    
    // Create spots for line chart
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    
    for (var i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final data = dailyData[date]!;
      incomeSpots.add(FlSpot(i.toDouble(), data['income'] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), data['expense'] ?? 0));
    }
    
    return SizedBox(
      height: 250,
      child: sortedDates.isEmpty
          ? const Center(child: Text('No data available'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                          final date = sortedDates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        if (flSpot.barIndex == 0) {
                          return LineTooltipItem(
                            'Income: \$${flSpot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white),
                          );
                        } else {
                          return LineTooltipItem(
                            'Expense: \$${flSpot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white),
                          );
                        }
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryData, Color color) {
    if (categoryData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      color.withOpacity(0.9),
      color.withOpacity(0.8),
      color.withOpacity(0.7),
      color.withOpacity(0.6),
      color.withOpacity(0.5),
      color.withOpacity(0.4),
      color.withOpacity(0.3),
    ];

    int colorIndex = 0;
    categoryData.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 0),
        ),
      );
      colorIndex++;
    });

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
          Center(
            child: Text(
              '${categoryData.length}\nCategories',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> categoryData, double total, Color color) {
    if (categoryData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Sort categories by amount (descending)
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final percentage = (entry.value / total * 100).toStringAsFixed(1);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.withOpacity(1 - (index * 0.1).clamp(0.0, 0.7)),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Import dart:math for max function
import 'dart:math' as math;