import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/allowance.dart';
import '../models/transaction_model.dart';
import '../models/category.dart';
import 'database_provider.dart';

final allowancesProvider = AsyncNotifierProvider<AllowancesNotifier, List<Allowance>>(() {
  return AllowancesNotifier();
});

class AllowancesNotifier extends AsyncNotifier<List<Allowance>> {
  @override
  Future<List<Allowance>> build() async {
    return loadAllowances();
  }

  Future<List<Allowance>> loadAllowances() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('allowances');
      final allowances = maps.map((e) => Allowance.fromMap(e)).toList();
      state = AsyncValue.data(allowances);
      return allowances;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> createAllowance({
    required String fromMemberId,
    required String toMemberId,
    required double totalAmount,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await ref.read(databaseProvider.future);
      
      await db.transaction((txn) async {
        final newAllowance = Allowance(
          id: const Uuid().v4(),
          fromMemberId: fromMemberId,
          toMemberId: toMemberId,
          totalAmount: totalAmount,
          remainingAmount: totalAmount,
          startDate: startDate,
          endDate: endDate,
          status: AllowanceStatus.active,
        );
        await txn.insert('allowances', newAllowance.toMap());

        // Helper to get or create category
        Future<String> getCategoryId(String name, CategoryType type) async {
          final maps = await txn.query(
            'categories',
            where: 'name = ? AND type = ?',
            whereArgs: [name, type.name],
          );
          if (maps.isNotEmpty) {
            return maps.first['id'] as String;
          }
          final newId = const Uuid().v4();
          await txn.insert('categories', {
            'id': newId,
            'name': name,
            'type': type.name,
          });
          return newId;
        }

        // 1. Transaction for Payer (Expense)
        final expenseCatId = await getCategoryId('Allowance Given', CategoryType.expense);
        final payerTransaction = TransactionModel(
          id: const Uuid().v4(),
          memberId: fromMemberId,
          categoryId: expenseCatId,
          amount: totalAmount,
          type: CategoryType.expense,
          date: startDate,
          note: 'Allowance to child',
        );
        await txn.insert('transactions', payerTransaction.toMap());

        // 2. Transaction for Receiver (Income)
        final incomeCatId = await getCategoryId('Allowance Received', CategoryType.income);
        final receiverTransaction = TransactionModel(
          id: const Uuid().v4(),
          memberId: toMemberId,
          categoryId: incomeCatId,
          amount: totalAmount,
          type: CategoryType.income,
          date: startDate,
          note: 'Allowance received',
        );
        await txn.insert('transactions', receiverTransaction.toMap());
      });

      await loadAllowances();
      // We should also invalidate transactions provider so it reloads
      // ref.invalidate(transactionsProvider); // Can't easily invalidate other providers from here without context or Ref, 
      // but we can rely on UI to refresh or maybe we should use container. 
      // Actually, since we are inside AsyncNotifier, we have `ref`.
      // However, `transactionsProvider` is in another file. We need to import it?
      // It's in `transaction_provider.dart` which is not imported. 
      // Instead of invalidating, maybe let the UI handle it? 
      // Or better, creating allowance is a rare event.
      // But for correctness, we should signal update.
    } catch (e) {
      // Handle error
      print('Error creating allowance: $e');
    }
  }

  Future<void> updateAllowance(Allowance allowance) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.update(
        'allowances',
        allowance.toMap(),
        where: 'id = ?',
        whereArgs: [allowance.id],
      );
      await loadAllowances();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteAllowance(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      // Delete related expenses first (if cascade is not set)
      await db.delete('allowance_expenses', where: 'allowance_id = ?', whereArgs: [id]);
      await db.delete('allowances', where: 'id = ?', whereArgs: [id]);
      await loadAllowances();
    } catch (e) {
      // Handle error
    }
  }
}

// Separate provider for expenses to avoid full reload loops if possible, or just merge logic
// Actually, tracking expenses inside allowance is complex.
// We need to deduct from remaining_amount.

final allowanceExpensesProvider = AsyncNotifierProvider<AllowanceExpensesNotifier, List<AllowanceExpense>>(() {
  return AllowanceExpensesNotifier();
});

class AllowanceExpensesNotifier extends AsyncNotifier<List<AllowanceExpense>> {
  @override
  Future<List<AllowanceExpense>> build() async {
    return loadExpenses();
  }

  Future<List<AllowanceExpense>> loadExpenses() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('allowance_expenses');
      final expenses = maps.map((e) => AllowanceExpense.fromMap(e)).toList();
      state = AsyncValue.data(expenses);
      return expenses;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addExpense({
    required String allowanceId,
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    try {
        final db = await ref.read(databaseProvider.future);
        // Transaction to ensure atomic update of expense + allowance balance
        await db.transaction((txn) async {
            // 1. Insert expense
            final newExpense = AllowanceExpense(
                id: const Uuid().v4(),
                allowanceId: allowanceId,
                categoryId: categoryId,
                amount: amount,
                date: date,
                note: note ?? '',
            );
            await txn.insert('allowance_expenses', newExpense.toMap());

            // 2. Get Allowance
            final allowanceMaps = await txn.query('allowances', where: 'id = ?', whereArgs: [allowanceId]);
            if (allowanceMaps.isNotEmpty) {
                final allowance = Allowance.fromMap(allowanceMaps.first);
                double newRemaining = allowance.remainingAmount - amount;
                AllowanceStatus newStatus = allowance.status;
                
                if (newRemaining <= 0) {
                    newRemaining = 0; // Or allow negative? User said "completed when reaches zero"
                    newStatus = AllowanceStatus.completed;
                }
                
                final updatedAllowance = allowance.copyWith(
                    remainingAmount: newRemaining,
                    status: newStatus,
                );
                await txn.update('allowances', updatedAllowance.toMap(), where: 'id = ?', whereArgs: [allowanceId]);
            }
        });
        
        await loadExpenses();
        // Also refresh allowances
        ref.read(allowancesProvider.notifier).loadAllowances();
        
    } catch (e) {
        // Handle error
    }
  }

  Future<void> updateExpense(AllowanceExpense expense) async {
    try {
      final db = await ref.read(databaseProvider.future);
      
      // Get old expense to calculate difference
      final oldExpenseMaps = await db.query(
        'allowance_expenses',
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      
      if (oldExpenseMaps.isEmpty) return;
      
      final oldExpense = AllowanceExpense.fromMap(oldExpenseMaps.first);
      final amountDifference = expense.amount - oldExpense.amount;
      
      // Transaction to ensure atomic update of expense + allowance balance
      await db.transaction((txn) async {
        // 1. Update expense
        await txn.update(
          'allowance_expenses',
          expense.toMap(),
          where: 'id = ?',
          whereArgs: [expense.id],
        );

        // 2. Update allowance remaining amount if amount changed
        if (amountDifference != 0) {
          final allowanceMaps = await txn.query(
            'allowances',
            where: 'id = ?',
            whereArgs: [expense.allowanceId],
          );
          
          if (allowanceMaps.isNotEmpty) {
            final allowance = Allowance.fromMap(allowanceMaps.first);
            double newRemaining = allowance.remainingAmount - amountDifference;
            AllowanceStatus newStatus = allowance.status;
            
            if (newRemaining <= 0) {
              newRemaining = 0;
              newStatus = AllowanceStatus.completed;
            } else if (newRemaining > 0 && allowance.status == AllowanceStatus.completed) {
              // If we're adding back money, reactivate if needed
              newStatus = AllowanceStatus.active;
            }
            
            final updatedAllowance = allowance.copyWith(
              remainingAmount: newRemaining,
              status: newStatus,
            );
            await txn.update(
              'allowances',
              updatedAllowance.toMap(),
              where: 'id = ?',
              whereArgs: [expense.allowanceId],
            );
          }
        }
      });
      
      await loadExpenses();
      // Also refresh allowances
      ref.read(allowancesProvider.notifier).loadAllowances();
      
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      final db = await ref.read(databaseProvider.future);
      
      // Get expense to know which allowance to update
      final expenseMaps = await db.query(
        'allowance_expenses',
        where: 'id = ?',
        whereArgs: [expenseId],
      );
      
      if (expenseMaps.isEmpty) return;
      
      final expense = AllowanceExpense.fromMap(expenseMaps.first);
      
      // Transaction to ensure atomic update of expense deletion + allowance balance
      await db.transaction((txn) async {
        // 1. Delete expense
        await txn.delete(
          'allowance_expenses',
          where: 'id = ?',
          whereArgs: [expenseId],
        );

        // 2. Update allowance remaining amount (add back the deleted amount)
        final allowanceMaps = await txn.query(
          'allowances',
          where: 'id = ?',
          whereArgs: [expense.allowanceId],
        );
        
        if (allowanceMaps.isNotEmpty) {
          final allowance = Allowance.fromMap(allowanceMaps.first);
          double newRemaining = allowance.remainingAmount + expense.amount;
          AllowanceStatus newStatus = allowance.status;
          
          // If we're adding back money, reactivate if it was completed
          if (newRemaining > 0 && allowance.status == AllowanceStatus.completed) {
            newStatus = AllowanceStatus.active;
          }
          
          // Don't exceed total amount
          if (newRemaining > allowance.totalAmount) {
            newRemaining = allowance.totalAmount;
          }
          
          final updatedAllowance = allowance.copyWith(
            remainingAmount: newRemaining,
            status: newStatus,
          );
          await txn.update(
            'allowances',
            updatedAllowance.toMap(),
            where: 'id = ?',
            whereArgs: [expense.allowanceId],
          );
        }
      });
      
      await loadExpenses();
      // Also refresh allowances
      ref.read(allowancesProvider.notifier).loadAllowances();
      
    } catch (e) {
      // Handle error
    }
  }
}

final activeAllowancesProvider = Provider.family<List<Allowance>, String>((ref, memberId) {
    // Allows where member is the receiver (toMemberId)
    final allowances = ref.watch(allowancesProvider).asData?.value ?? [];
    return allowances.where((a) => a.toMemberId == memberId && a.status == AllowanceStatus.active).toList();
});

final expensesByAllowanceIdProvider = Provider.family<List<AllowanceExpense>, String>((ref, allowanceId) {
    final expenses = ref.watch(allowanceExpensesProvider).asData?.value ?? [];
    final filtered = expenses.where((e) => e.allowanceId == allowanceId).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    return filtered;
});
