import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import 'database_provider.dart';

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
      final newDebt = Debt(
        id: const Uuid().v4(),
        memberId: memberId,
        personName: personName,
        amount: amount,
        type: type,
        status: DebtStatus.pending,
        date: date,
        note: note,
      );
      await db.insert('debts', newDebt.toMap());
      await loadDebts();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAsSettled(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      // First get existing to keep fields
      final maps = await db.query('debts', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
          final debt = Debt.fromMap(maps.first);
          final updated = debt.copyWith(status: DebtStatus.settled);
          await db.update('debts', updated.toMap(), where: 'id = ?', whereArgs: [id]);
          await loadDebts();
      }
    } catch (e) {
      // Handle error
    }
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
        // Only count pending? Usually yes for "current debt"
        if (d.status == DebtStatus.pending) {
            if (d.type == DebtType.debit) {
                debit += d.amount;
            } else {
                credit += d.amount;
            }
        }
    }
    return {
        'debit': debit,
        'credit': credit,
    };
});
