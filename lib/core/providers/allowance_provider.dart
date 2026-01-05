import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/allowance.dart';
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
      await db.insert('allowances', newAllowance.toMap());
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
