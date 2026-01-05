import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category.dart';
import 'database_provider.dart';

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

// Derived provider for filtered transactions by member
final memberTransactionsProvider = Provider.family<List<TransactionModel>, String>((ref, memberId) {
  final transactions = ref.watch(transactionsProvider).asData?.value ?? [];
  return transactions.where((t) => t.memberId == memberId).toList();
});

// Derived providers for totals
final memberBalanceProvider = Provider.family<Map<String, double>, String>((ref, memberId) {
  final transactions = ref.watch(memberTransactionsProvider(memberId));
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
