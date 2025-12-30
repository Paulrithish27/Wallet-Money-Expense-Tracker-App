import 'package:flutter/material.dart';
import '../services/transaction_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TransactionService _transactionService = TransactionService();
  List<String> _expenseCategories = [];
  List<String> _incomeCategories = [];
  
  final TextEditingController _newCategoryController = TextEditingController();
  String _selectedTab = 'expense';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _expenseCategories = _transactionService.getExpenseCategories();
    _incomeCategories = _transactionService.getIncomeCategories();
  }

  void _addCategory() {
    if (_newCategoryController.text.trim().isEmpty) return;
    
    final newCategory = _newCategoryController.text.trim();
    setState(() {
      if (_selectedTab == 'expense') {
        _transactionService.addExpenseCategory(newCategory);
        _expenseCategories = _transactionService.getExpenseCategories();
      } else {
        _transactionService.addIncomeCategory(newCategory);
        _incomeCategories = _transactionService.getIncomeCategories();
      }
      _newCategoryController.clear();
    });
  }

  void _removeCategory(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Category'),
        content: const Text('Are you sure you want to remove this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (_selectedTab == 'expense') {
                  final category = _expenseCategories[index];
                  _transactionService.removeExpenseCategory(category);
                  _expenseCategories = _transactionService.getExpenseCategories();
                } else {
                  final category = _incomeCategories[index];
                  _transactionService.removeIncomeCategory(category);
                  _incomeCategories = _transactionService.getIncomeCategories();
                }
              });
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories = _selectedTab == 'expense' ? _expenseCategories : _incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'expense'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'expense' ? Colors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Expense Categories',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 'expense' ? Colors.white : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'income'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'income' ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Income Categories',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 'income' ? Colors.white : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: InputDecoration(
                      hintText: 'Add new category...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Categories:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: currentCategories.isEmpty
                ? const Center(
                    child: Text(
                      'No categories added',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: currentCategories.length,
                    itemBuilder: (context, index) {
                      final category = currentCategories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _selectedTab == 'expense' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: _selectedTab == 'expense' ? Colors.red : Colors.green,
                          ),
                          title: Text(category),
                          trailing: category != 'Other' ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeCategory(index),
                          ) : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }
}