import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TodayTransactionScreen(),
    const HistoryScreen(),
    const ReportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class TodayTransactionScreen extends StatefulWidget {
  const TodayTransactionScreen({super.key});

  @override
  State<TodayTransactionScreen> createState() => _TodayTransactionScreenState();
}

class _TodayTransactionScreenState extends State<TodayTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _todayTransactions = [];
  double _todayTotalExpenses = 0.0;
  double _todayTotalIncome = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _transactionService.getTodayTransactions();
      final expenses = await _transactionService.getTodayTotalExpenses();
      final income = await _transactionService.getTodayTotalIncome();
      setState(() {
        _todayTransactions = transactions;
        _todayTotalExpenses = expenses;
        _todayTotalIncome = income;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTransaction(TransactionType type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transactionType: type),
      ),
    );
    
    if (result == true) {
      _loadTodayData();
    }
  }

  void _showDeleteDialog(Transaction transaction) async {
    final confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Transaction"),
          content: Text("Are you sure you want to delete this ${transaction.category} ${transaction.isIncome ? 'income' : 'expense'} of ₹${transaction.amount.toStringAsFixed(2)}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    
    if (confirm == true && transaction.id != null) {
      await _transactionService.deleteTransaction(transaction.id!);
      _loadTodayData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${transaction.category} ${transaction.isIncome ? 'income' : 'expense'} deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _todayTotalIncome - _todayTotalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Expense Tracker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Today's Summary Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Balance Card
                      _buildBalanceCard(balance),
                      const SizedBox(height: 16),
                      
                      // Income & Expense Boxes
                      Row(
                        children: [
                          Expanded(
                            child: _buildMoneyBox(
                              'Income',
                              _todayTotalIncome,
                              Colors.green,
                              Icons.arrow_upward,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMoneyBox(
                              'Expense',
                              _todayTotalExpenses,
                              Colors.red,
                              Icons.arrow_downward,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Add Transaction Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addTransaction(TransactionType.income),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Income'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addTransaction(TransactionType.expense),
                          icon: const Icon(Icons.remove, size: 20),
                          label: const Text('Add Expense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent Transactions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_todayTransactions.length} items',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Transactions List
                Expanded(
                  child: _todayTransactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _todayTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _todayTransactions[index];
                            return _buildTransactionItem(transaction);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;
    final balanceIcon = balance >= 0 ? Icons.trending_up : Icons.trending_down;
    final balanceText = balance >= 0 ? 'Positive' : 'Negative';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: balanceColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(balanceIcon, color: balanceColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceText,
                  style: TextStyle(
                    fontSize: 14,
                    color: balanceColor,
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

  Widget _buildMoneyBox(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: transaction.isIncome 
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: transaction.isIncome ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              Text(
                transaction.note!,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              _formatTime(transaction.date),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.isIncome ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.isIncome ? 'INCOME' : 'EXPENSE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: transaction.isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _showDeleteDialog(transaction),
              padding: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.receipt_long,
          size: 80,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        const Text(
          'No transactions today',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add your first income or expense to get started',
          style: TextStyle(
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}