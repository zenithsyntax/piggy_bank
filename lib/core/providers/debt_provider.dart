import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../models/transaction_model.dart';
import '../models/category.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

final debtsProvider = AsyncNotifierProvider<DebtsNotifier, List<Debt>>(() {
  return DebtsNotifier();
});

class DebtsNotifier extends AsyncNotifier<List<Debt>> {
  @override
  Future<List<Debt>> build() async {
    return loadDebts();
  }

  Future<List<Debt>> loadDebts() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('debts', orderBy: 'date DESC');
      final debts = maps.map((e) => Debt.fromMap(e)).toList();
      state = AsyncValue.data(debts);
      return debts;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addDebt({
    required String memberId,
    required String personName,
    required double amount,
    required DebtType type,
    required DateTime date,
    String note = '',
  }) async {
    try {
      final db = await ref.read(databaseProvider.future);
      
      await db.transaction((txn) async {
        final newDebt = Debt(
          id: const Uuid().v4(),
          memberId: memberId,
          personName: personName,
          amount: amount,
          remainingAmount: amount, // Initially same
          type: type,
          status: DebtStatus.pending,
          date: date,
          note: note,
        );
        await txn.insert('debts', newDebt.toMap());

         // Helper to get or create category
        Future<String> getCategoryId(String name, CategoryType catType) async {
          final maps = await txn.query(
            'categories',
            where: 'name = ? AND type = ?',
            whereArgs: [name, catType.name],
          );
          if (maps.isNotEmpty) {
            return maps.first['id'] as String;
          }
          final newId = const Uuid().v4();
          await txn.insert('categories', {
            'id': newId,
            'name': name,
            'type': catType.name,
          });
          return newId;
        }

        // Create Linked Transaction
        // DebtType.debit = I gave (Lent) -> Expense
        // DebtType.credit = I took (Borrowed) -> Income
        final transactionType = type == DebtType.debit ? CategoryType.expense : CategoryType.income;
        final categoryName = type == DebtType.debit ? 'Debt / Loan Given' : 'Debt / Loan Taken';
        
        final catId = await getCategoryId(categoryName, transactionType);
        
        final newTransaction = TransactionModel(
          id: const Uuid().v4(),
          memberId: memberId,
          categoryId: catId,
          amount: amount,
          type: transactionType,
          date: date,
          note: 'Debt: $personName - $note',
        );
        await txn.insert('transactions', newTransaction.toMap());
      });

      await loadDebts();
      // Invalidate transactions provider to update balance
      ref.invalidate(transactionsProvider);
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> updateDebt(Debt debt) async {
      try {
          final db = await ref.read(databaseProvider.future);
          await db.update('debts', debt.toMap(), where: 'id = ?', whereArgs: [debt.id]);
          await loadDebts();
          // Invalidate transactions provider to update balance
          ref.invalidate(transactionsProvider);
      } catch (e) {
          // Handle Error
      }
  }

  Future<void> deleteDebt(String id) async {
       try {
          final db = await ref.read(databaseProvider.future);
          
          // Get debt info before deleting to find associated transaction
          final debtMaps = await db.query('debts', where: 'id = ?', whereArgs: [id]);
          if (debtMaps.isEmpty) return;
          
          final debt = Debt.fromMap(debtMaps.first);
          
          // Delete associated transaction (created when debt was added)
          // Transaction note format: "Debt: $personName - $note"
          await db.delete(
            'transactions',
            where: 'note LIKE ? AND member_id = ?',
            whereArgs: ['Debt: ${debt.personName}%', debt.memberId],
          );
          
          // Also delete any repayment transactions
          // Repayment transaction note format: "Repayment: $personName"
          await db.delete(
            'transactions',
            where: 'note LIKE ? AND member_id = ?',
            whereArgs: ['Repayment: ${debt.personName}%', debt.memberId],
          );
          
          // Delete debt repayments
          await db.delete('debt_repayments', where: 'debt_id = ?', whereArgs: [id]);
          
          // Delete the debt
          await db.delete('debts', where: 'id = ?', whereArgs: [id]);
          
          await loadDebts();
          // Invalidate transactions provider to update balance
          ref.invalidate(transactionsProvider);
      } catch (e) {
          // Handle Error
      }
  }

  Future<void> markAsSettled(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      // First get existing to keep fields
      final maps = await db.query('debts', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
          final debt = Debt.fromMap(maps.first);
          final updated = debt.copyWith(status: DebtStatus.settled, remainingAmount: 0);
          await db.update('debts', updated.toMap(), where: 'id = ?', whereArgs: [id]);
          await loadDebts();
      }
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> addRepayment({
      required String debtId,
      required double amount,
      required DateTime date,
      String note = '',
  }) async {
      final db = await ref.read(databaseProvider.future);
      final debts = state.asData?.value ?? [];
      final debtIndex = debts.indexWhere((d) => d.id == debtId);
      if (debtIndex == -1) return;
      final debt = debts[debtIndex];

      final newRepayment = DebtRepayment(
          id: const Uuid().v4(),
          debtId: debtId,
          amount: amount,
          date: date,
          note: note
      );
      
      await db.transaction((txn) async {
          // 1. Insert Repayment
          await txn.insert('debt_repayments', newRepayment.toMap());
          
           // Helper to get or create category
            Future<String> getCategoryId(String name, CategoryType catType) async {
            final maps = await txn.query(
                'categories',
                where: 'name = ? AND type = ?',
                whereArgs: [name, catType.name],
            );
            if (maps.isNotEmpty) {
                return maps.first['id'] as String;
            }
            final newId = const Uuid().v4();
            await txn.insert('categories', {
                'id': newId,
                'name': name,
                'type': catType.name,
            });
            return newId;
            }

            // Create Linked Transaction for Repayment
            // If Debt was Debit (I gave), Repayment is Income (I get back)
            // If Debt was Credit (I took), Repayment is Expense (I pay back)
            
            final isIncome = debt.type == DebtType.debit;
            final transactionType = isIncome ? CategoryType.income : CategoryType.expense;
            final categoryName = isIncome ? 'Debt Repayment Received' : 'Debt Repayment Paid';

            final catId = await getCategoryId(categoryName, transactionType);

            final newTransaction = TransactionModel(
            id: const Uuid().v4(),
            memberId: debt.memberId,
            categoryId: catId,
            amount: amount,
            type: transactionType,
            date: date,
            note: 'Repayment: ${debt.personName}',
            );
            await txn.insert('transactions', newTransaction.toMap());
          
          // 2. Update Debt Remaining Amount
          final newRemaining = debt.remainingAmount - amount;
          final newStatus = newRemaining <= 0 ? DebtStatus.settled : DebtStatus.pending;
          
          final updatedDebt = debt.copyWith(
              remainingAmount: newRemaining < 0 ? 0 : newRemaining,
              status: newStatus
          );
          await txn.update('debts', updatedDebt.toMap(), where: 'id = ?', whereArgs: [debtId]);
      });
      
      // Reload debts to update UI
      ref.invalidate(debtRepaymentsProvider(debtId));
      await loadDebts();
      // Invalidate transactions provider to update balance
      ref.invalidate(transactionsProvider);
  }
  
  Future<void> deleteRepayment(String repaymentId, String debtId, double amount) async {
       final db = await ref.read(databaseProvider.future);
       final debts = state.asData?.value ?? [];
       final debtIndex = debts.indexWhere((d) => d.id == debtId);
       if (debtIndex == -1) return;
       final debt = debts[debtIndex];
       
       // Get repayment info before deleting
       final repaymentMaps = await db.query('debt_repayments', where: 'id = ?', whereArgs: [repaymentId]);
       if (repaymentMaps.isEmpty) return;
       final repayment = DebtRepayment.fromMap(repaymentMaps.first);
       
       await db.transaction((txn) async {
           // Delete the repayment transaction
           // Transaction note format: "Repayment: $personName"
           await txn.delete(
             'transactions',
             where: 'note = ? AND member_id = ? AND amount = ? AND date = ?',
             whereArgs: [
               'Repayment: ${debt.personName}',
               debt.memberId,
               repayment.amount,
               repayment.date.toIso8601String(),
             ],
           );
           
           // Delete the repayment
           await txn.delete('debt_repayments', where: 'id = ?', whereArgs: [repaymentId]);
           
           // Restore amount to debt
           final newRemaining = debt.remainingAmount + amount;
           final newStatus = DebtStatus.pending; // Revert to pending if it was settled
           
            final updatedDebt = debt.copyWith(
              remainingAmount: newRemaining > debt.amount ? debt.amount : newRemaining, // Cap at total amount? Or allow over? usually cap at total.
              status: newStatus
          );
          await txn.update('debts', updatedDebt.toMap(), where: 'id = ?', whereArgs: [debtId]);
       });
       
       ref.invalidate(debtRepaymentsProvider(debtId));
       await loadDebts();
       // Invalidate transactions provider to update balance
       ref.invalidate(transactionsProvider);
  }
}

final memberDebtsProvider = Provider.family<List<Debt>, String>((ref, memberId) {
    final debts = ref.watch(debtsProvider).asData?.value ?? [];
    return debts.where((d) => d.memberId == memberId).toList();
});

final memberDebtSummaryProvider = Provider.family<Map<String, double>, String>((ref, memberId) {
    final debts = ref.watch(memberDebtsProvider(memberId));
    double debit = 0; // I gave
    double credit = 0; // I took
    
    for (var d in debts) {
        // Only count pending? Usually yes for "current debt" - count Remaining Amount
        if (d.status == DebtStatus.pending) {
            if (d.type == DebtType.debit) {
                debit += d.remainingAmount;
            } else {
                credit += d.remainingAmount;
            }
        }
    }
    return {
        'debit': debit,
        'credit': credit,
    };
});

final debtRepaymentsProvider = FutureProvider.family<List<DebtRepayment>, String>((ref, debtId) async {
    final db = await ref.watch(databaseProvider.future);
    final maps = await db.query('debt_repayments', where: 'debt_id = ?', whereArgs: [debtId], orderBy: 'date DESC');
    return maps.map((e) => DebtRepayment.fromMap(e)).toList();
});
