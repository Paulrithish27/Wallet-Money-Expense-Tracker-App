enum TransactionType {
  expense,
  income,
}

class Transaction {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final TransactionType type;

  Transaction({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'type': type == TransactionType.income ? 'income' : 'expense',
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'] is int ? (map['amount'] as int).toDouble() : map['amount'],
      category: map['category'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      note: map['note'],
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
}