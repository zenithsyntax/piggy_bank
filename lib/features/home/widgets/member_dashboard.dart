import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/allowance_provider.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/category.dart';
import '../../../core/models/debt.dart';
import '../../allowances/allowance_expense_dialog.dart';
import '../../allowances/allowance_details_page.dart';
import '../../debts/debt_details_page.dart';
import '../../transactions/add_transaction_page.dart';
import '../../../core/providers/currency_provider.dart';

class MemberDashboard extends ConsumerWidget {
  final String memberId;

  const MemberDashboard({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider).valueOrNull ?? '\$';
    final balance = ref.watch(memberBalanceProvider(memberId));
    final transactions = ref.watch(memberTransactionsProvider(memberId));
    final debtSummary = ref.watch(memberDebtSummaryProvider(memberId));
    final activeAllowances = ref.watch(activeAllowancesProvider(memberId));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildBalanceCard(context, balance, currency),
        const SizedBox(height: 16),
        if (debtSummary['debit']! > 0 || debtSummary['credit']! > 0) ...[
          _buildDebtSummaryCard(context, debtSummary, currency),
          const SizedBox(height: 16),
        ],

        // Active Debts Section
        Builder(builder: (context) {
          // We need to filter for pending debts here since we don't have a specific provider for it yet,
          // or we can just filter the list we already have if we had access to the full list.
          // But memberDebtsProvider returns ALL debts.
          final allDebts = ref.watch(memberDebtsProvider(memberId));
          final pendingDebts =
              allDebts.where((d) => d.status == DebtStatus.pending).toList();

          if (pendingDebts.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Debts (Pending)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...pendingDebts.map((d) => _buildDebtTile(context, ref, d, currency)),
                const SizedBox(height: 16),
              ],
            );
          }
          return const SizedBox.shrink();
        }),

        if (activeAllowances.isNotEmpty) ...[
          Text('Active Allowances',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...activeAllowances.map((a) => Card(
                child: ListTile(
                  leading: const Icon(Icons.wallet_giftcard,
                      color: Colors.purpleAccent),
                  title: Text('Allowance Details'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Total: ${NumberFormat.currency(symbol: currency).format(a.totalAmount)}'),
                      Text(
                          'Remaining: ${NumberFormat.currency(symbol: currency).format(a.remainingAmount)}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllowanceDetailsPage(allowance: a),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart,
                        color: Colors.blueAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AllowanceExpenseDialog(
                          allowanceId: a.id,
                          remainingAmount: a.remainingAmount,
                        ),
                      );
                    },
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],

        Text('Recent Transactions',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...transactions
            .take(10)
            .map((t) => _buildTransactionTile(context, ref, t, currency)),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, Map<String, double> balance, String currency) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Current Balance',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              NumberFormat.currency(symbol: currency).format(balance['balance']),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (balance['balance'] ?? 0) >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                    context, 'Income', balance['income']!, Colors.greenAccent, currency),
                _buildSummaryItem(
                    context, 'Expenses', balance['expense']!, Colors.redAccent, currency),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryCard(
      BuildContext context, Map<String, double> debt, String currency) {
    return Card(
      color: Colors.blueGrey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
                context, 'I Gave (Debit)', debt['debit']!, Colors.orangeAccent, currency),
            _buildSummaryItem(context, 'I Took (Credit)', debt['credit']!,
                Colors.purpleAccent, currency),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String label, double amount, Color color, String currency) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          NumberFormat.currency(symbol: currency).format(amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildDebtTile(BuildContext context, WidgetRef ref, Debt debt, String currency) {
    final isDebit = debt.type == DebtType.debit;
    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete)),
      confirmDismiss: (direction) async {
        return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: const Text("Delete Debt?"),
                    content: const Text("This action cannot be undone."),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel")),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Delete")),
                    ]));
      },
      onDismissed: (_) {
        ref.read(debtsProvider.notifier).deleteDebt(debt.id);
      },
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isDebit
                ? Colors.orangeAccent.withOpacity(0.2)
                : Colors.purpleAccent.withOpacity(0.2),
            child: Icon(isDebit ? Icons.arrow_outward : Icons.arrow_downward,
                color: isDebit ? Colors.orangeAccent : Colors.purpleAccent),
          ),
          title: Text(debt.personName),
          subtitle: Text(
              "Rem: ${NumberFormat.currency(symbol: currency).format(debt.remainingAmount)} / Total: ${NumberFormat.currency(symbol: currency).format(debt.amount)}"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => DebtDetailsPage(debt: debt)));
          },
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
      BuildContext context, WidgetRef ref, TransactionModel transaction, String currency) {
    final isExpense = transaction.type == CategoryType.expense;
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete)),
      confirmDismiss: (direction) async {
        return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: const Text("Delete Transaction?"),
                    content: const Text("This action cannot be undone."),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel")),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Delete")),
                    ]));
      },
      onDismissed: (_) {
        ref
            .read(transactionsProvider.notifier)
            .deleteTransaction(transaction.id);
      },
      child: Card(
        child: ListTile(
          leading: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.redAccent : Colors.greenAccent,
          ),
          title: Text(NumberFormat.currency(symbol: currency).format(transaction.amount)),
          subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
          trailing: transaction.note.isNotEmpty
              ? const Icon(Icons.note, size: 16)
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionPage(
                  initialMemberId: transaction.memberId,
                  transactionToEdit: transaction,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
