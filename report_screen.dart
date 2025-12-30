import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/transaction_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TransactionService _transactionService = TransactionService();
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  int _activeChartIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _transactionService.getMonthlySummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _summary = {
          'totalExpenses': 0.0,
          'totalIncome': 0.0,
          'balance': 0.0,
          'expensesByCategory': {},
          'incomeByCategory': {},
          'expensePercentages': {},
          'incomePercentages': {},
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReportContent(),
    );
  }

  Widget _buildReportContent() {
    final totalExpenses = (_summary['totalExpenses'] as double?) ?? 0.0;
    final totalIncome = (_summary['totalIncome'] as double?) ?? 0.0;
    final balance = (_summary['balance'] as double?) ?? 0.0;
    final expensesByCategory = (_summary['expensesByCategory'] as Map<String, dynamic>?) ?? {};
    final incomeByCategory = (_summary['incomeByCategory'] as Map<String, dynamic>?) ?? {};
    final expensePercentages = (_summary['expensePercentages'] as Map<String, dynamic>?) ?? {};
    final incomePercentages = (_summary['incomePercentages'] as Map<String, dynamic>?) ?? {};

    final hasExpenses = expensesByCategory.isNotEmpty;
    final hasIncome = incomeByCategory.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monthly Financial Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'Total Income',
                  totalIncome,
                  Colors.green,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancialCard(
                  'Total Expenses',
                  totalExpenses,
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          _buildBalanceCard(balance),
          
          const SizedBox(height: 24),

          if (hasExpenses || hasIncome) ...[
            const Text(
              'Spending & Income Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildChartTypeButton(
                      'Expenses',
                      0,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildChartTypeButton(
                      'Income',
                      1,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (_activeChartIndex == 0 && hasExpenses) 
              _buildPieChartSection(expensesByCategory, expensePercentages, Colors.red, 'Expenses')
            else if (_activeChartIndex == 1 && hasIncome)
              _buildPieChartSection(incomeByCategory, incomePercentages, Colors.green, 'Income')
            else
              _buildNoDataChart(),
            
            const SizedBox(height: 24),
          ],

          if (hasExpenses) ...[
            const Text(
              'Expense Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._buildCategoryItems(
              expensesByCategory, 
              expensePercentages, 
              Colors.red
            ),
            const SizedBox(height: 24),
          ],

          if (hasIncome) ...[
            const Text(
              'Income Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._buildCategoryItems(
              incomeByCategory, 
              incomePercentages, 
              Colors.green
            ),
            const SizedBox(height: 24),
          ],

          if (!hasExpenses && !hasIncome)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(String text, int index, Color color) {
    final isSelected = _activeChartIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeChartIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartSection(
    Map<String, dynamic> data, 
    Map<String, dynamic> percentages, 
    Color primaryColor, 
    String title
  ) {
    return Column(
      children: [
        Container(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: _buildPieChartSections(data, percentages, primaryColor),
              centerSpaceRadius: 50,
              sectionsSpace: 4,
              startDegreeOffset: 90,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$title Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ..._buildChartLegend(data, primaryColor),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, dynamic> data, 
    Map<String, dynamic> percentages, 
    Color primaryColor
  ) {
    final List<Color> colors = [
      primaryColor,
      primaryColor.withOpacity(0.8),
      primaryColor.withOpacity(0.6),
      primaryColor.withOpacity(0.4),
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.teal,
    ];

    int colorIndex = 0;
    return data.entries.map((entry) {
      final category = entry.key;
      final percentage = percentages[category] != null ? (percentages[category] as num).toDouble() : 0.0;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      final radius = percentage > 10 ? 60.0 : 50.0;

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildChartLegend(Map<String, dynamic> data, Color primaryColor) {
    return data.entries.map((entry) {
      final category = entry.key;
      final amount = (entry.value as num).toDouble();
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildNoDataChart() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(String title, double amount, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;
    final balanceText = balance >= 0 ? 'Surplus' : 'Deficit';

    return Card(
      elevation: 2,
      color: balanceColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              balance >= 0 ? Icons.trending_up : Icons.trending_down,
              color: balanceColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly $balanceText',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '₹${balance.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryItems(
    Map<String, dynamic> byCategory, 
    Map<String, dynamic> percentages, 
    Color color
  ) {
    return byCategory.entries.map((entry) {
      final category = entry.key;
      final amount = (entry.value as num).toDouble();
      final percentage = percentages[category] != null ? (percentages[category] as num).toDouble() : 0.0;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('₹${amount.toStringAsFixed(2)}'),
          trailing: SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Column(
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No transactions this month',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            'Add some income and expenses to see your financial report',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      )
    );
  }
}