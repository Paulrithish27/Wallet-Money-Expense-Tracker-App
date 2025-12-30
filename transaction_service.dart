import '../models/transaction.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  List<Transaction> _transactions = [];

  final List<String> _expenseCategories = ['Food', 'Travel', 'Shopping', 'Entertainment', 'Bills', 'Other'];
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Business', 'Investment', 'Gift', 'Other'];

  Future<List<Transaction>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_transactions.reversed);
  }

  Future<List<Transaction>> getTodayTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return _transactions.where((transaction) {
      return transaction.date.year == now.year &&
          transaction.date.month == now.month &&
          transaction.date.day == now.day;
    }).toList();
  }

  Future<List<Transaction>> getMonthlyTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return _transactions.where((transaction) {
      return transaction.date.year == now.year && transaction.date.month == now.month;
    }).toList();
  }

  Future<List<Transaction>> getExpenses() async {
    final transactions = await getTransactions();
    return transactions.where((t) => t.isExpense).toList();
  }

  Future<List<Transaction>> getIncomes() async {
    final transactions = await getTransactions();
    return transactions.where((t) => t.isIncome).toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newId = _transactions.isEmpty ? 1 : (_transactions.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    _transactions.add(Transaction(
      id: newId,
      amount: transaction.amount,
      category: transaction.category,
      date: transaction.date,
      note: transaction.note,
      type: transaction.type,
    ));
  }

  Future<void> deleteTransaction(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _transactions.removeWhere((transaction) => transaction.id == id);
  }

  Future<void> deleteAllTransactions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _transactions.clear();
  }

  Future<double> getTodayTotalExpenses() async {
    final todayTransactions = await getTodayTransactions();
    double total = 0.0;
    for (var transaction in todayTransactions) {
      if (transaction.isExpense) {
        total += transaction.amount;
      }
    }
    return total;
  }

  Future<double> getTodayTotalIncome() async {
    final todayTransactions = await getTodayTransactions();
    double total = 0.0;
    for (var transaction in todayTransactions) {
      if (transaction.isIncome) {
        total += transaction.amount;
      }
    }
    return total;
  }

  Future<Map<String, dynamic>> getMonthlySummary() async {
    final monthlyTransactions = await getMonthlyTransactions();
    
    double totalExpenses = 0.0;
    double totalIncome = 0.0;
    
    for (var transaction in monthlyTransactions) {
      if (transaction.isExpense) {
        totalExpenses += transaction.amount;
      } else {
        totalIncome += transaction.amount;
      }
    }
    
    double balance = totalIncome - totalExpenses;
    
    Map<String, double> expensesByCategory = {};
    Map<String, double> incomeByCategory = {};
    
    for (var transaction in monthlyTransactions) {
      if (transaction.isExpense) {
        expensesByCategory.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      } else {
        incomeByCategory.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    
    Map<String, double> expensePercentages = {};
    expensesByCategory.forEach((category, amount) {
      expensePercentages[category] = totalExpenses > 0 ? (amount / totalExpenses * 100) : 0;
    });

    Map<String, double> incomePercentages = {};
    incomeByCategory.forEach((category, amount) {
      incomePercentages[category] = totalIncome > 0 ? (amount / totalIncome * 100) : 0;
    });

    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'balance': balance,
      'expensesByCategory': expensesByCategory,
      'incomeByCategory': incomeByCategory,
      'expensePercentages': expensePercentages,
      'incomePercentages': incomePercentages,
    };
  }

  List<String> getExpenseCategories() => List.from(_expenseCategories);
  List<String> getIncomeCategories() => List.from(_incomeCategories);

  void addExpenseCategory(String category) {
    if (!_expenseCategories.contains(category)) {
      _expenseCategories.add(category);
    }
  }

  void addIncomeCategory(String category) {
    if (!_incomeCategories.contains(category)) {
      _incomeCategories.add(category);
    }
  }

  void removeExpenseCategory(String category) {
    if (category != 'Other' && _expenseCategories.contains(category)) {
      _expenseCategories.remove(category);
      _transactions.removeWhere((transaction) => 
        transaction.isExpense && transaction.category == category);
    }
  }

  void removeIncomeCategory(String category) {
    if (category != 'Other' && _incomeCategories.contains(category)) {
      _incomeCategories.remove(category);
      _transactions.removeWhere((transaction) => 
        transaction.isIncome && transaction.category == category);
    }
  }
}