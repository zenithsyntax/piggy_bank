import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category.dart';
import 'database_provider.dart';
import 'date_range_provider.dart';

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    return loadTransactions();
  }

  Future<List<TransactionModel>> loadTransactions() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('transactions', orderBy: 'date DESC');
      final transactions = maps.map((e) => TransactionModel.fromMap(e)).toList();
      state = AsyncValue.data(transactions);
      return transactions;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addTransaction({
    required String memberId,
    required String categoryId,
    required double amount,
    required CategoryType type,
    required DateTime date,
    String note = '',
  }) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final newTransaction = TransactionModel(
        id: const Uuid().v4(),
        memberId: memberId,
        categoryId: categoryId,
        amount: amount,
        type: type,
        date: date,
        note: note,
      );
      await db.insert('transactions', newTransaction.toMap());
      await loadTransactions();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
      await loadTransactions();
    } catch (e) {
      // Handle error
    }
  }
  
    Future<void> deleteTransaction(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
      await loadTransactions();
    } catch (e) {
      // Handle error
    }
  }
}

// Derived provider for filtered transactions by member and date range
final filteredTransactionsProvider = Provider.family<List<TransactionModel>, String>((ref, memberId) {
  final transactions = ref.watch(transactionsProvider).asData?.value ?? [];
  final dateRange = ref.watch(currentDateRangeProvider);
  
  return transactions.where((t) {
    if (t.memberId != memberId) return false;
    // Check if date is within range [start, end)
    // Actually, let's use inclusive start and exclusive end logic, or inclusive both?
    // Start 5th, End 5th of next month.
    // Usually: start <= date < end
    return t.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) && 
           t.date.isBefore(dateRange.end);
  }).toList();
});

// Original provider kept for compatibility if needed, but we should use filtered one
final memberTransactionsProvider = Provider.family<List<TransactionModel>, String>((ref, memberId) {
     return ref.watch(filteredTransactionsProvider(memberId));
});

// Derived providers for totals
final memberBalanceProvider = Provider.family<Map<String, double>, String>((ref, memberId) {
  final transactions = ref.watch(filteredTransactionsProvider(memberId));
  double income = 0;
  double expense = 0;
  for (var t in transactions) {
    if (t.type == CategoryType.income) {
      income += t.amount;
    } else {
      expense += t.amount;
    }
  }
  return {
    'income': income,
    'expense': expense,
    'balance': income - expense,
  };
});
