import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/allowance_provider.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/category.dart';
import '../../../core/models/debt.dart';
import '../../../core/models/allowance.dart';
import '../../../core/utils/gradient_summary_card.dart';
import '../../allowances/allowance_details_page.dart';
import '../../debts/debt_details_page.dart';
import '../../transactions/transaction_dialog.dart';

class MemberDashboard extends ConsumerWidget {
  final String memberId;

  const MemberDashboard({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(memberBalanceProvider(memberId));
    final transactions = ref.watch(memberTransactionsProvider(memberId));
    final debtSummary = ref.watch(memberDebtSummaryProvider(memberId));
    final activeAllowances = ref.watch(activeAllowancesProvider(memberId));
    final theme = Theme.of(context);

    final currentBalance = balance['balance'] ?? 0.0;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      children: [
        // Balance Card
        GradientSummaryCard(
          title: 'Current Balance',
          amount: NumberFormat.simpleCurrency().format(currentBalance),
          subtitle: 'Daily Spending Limit: ${NumberFormat.simpleCurrency().format(500)}', // Placeholder logic
          icon: Icons.account_balance,
          color: currentBalance >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
        
        const SizedBox(height: 24),
        
        // Income/Expense Summary
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                context, 
                'Income', 
                balance['income']!, 
                Colors.greenAccent,
                Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                context, 
                'Expense', 
                balance['expense']!, 
                Colors.redAccent,
                Icons.arrow_downward,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (debtSummary['debit']! > 0 || debtSummary['credit']! > 0) ...[
            _buildDebtSummaryCard(context, debtSummary),
            const SizedBox(height: 24),
        ],
        
        // Active Debts
         Builder(
            builder: (context) {
                 final allDebts = ref.watch(memberDebtsProvider(memberId));
                 final pendingDebts = allDebts.where((d) => d.status == DebtStatus.pending).toList();
                 
                 if (pendingDebts.isNotEmpty) {
                     return Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                             Text('Active Debts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 12),
                             ...pendingDebts.map((d) => _buildDebtTile(context, ref, d)),
                             const SizedBox(height: 24),
                         ],
                     );
                 }
                 return const SizedBox.shrink();
            }
        ),

        if (activeAllowances.isNotEmpty) ...[
            Text('Active Allowances', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...activeAllowances.map((a) => _buildAllowanceTile(context, a)),
            const SizedBox(height: 24),
        ],

        Text('Recent Transactions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text("No recent activity", style: theme.textTheme.bodyMedium),
            ),
          )
        else
          ...transactions.take(10).map((t) => _buildTransactionTile(context, ref, t)),
          
        const SizedBox(height: 80), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildMiniStatCard(BuildContext context, String title, double amount, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.compactSimpleCurrency().format(amount),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSummaryCard(BuildContext context, Map<String, double> debt) {
      return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF263238), const Color(0xFF37474F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                  _buildSummaryItem(context, 'You Owe', debt['debit']!, const Color(0xFFFFAB91)), // Light Orange
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildSummaryItem(context, 'Owes You', debt['credit']!, const Color(0xFFCE93D8)), // Light Purple
              ],
          ),
      );
  }

  Widget _buildSummaryItem(BuildContext context, String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          NumberFormat.compactSimpleCurrency().format(amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
  
  Widget _buildDebtTile(BuildContext context, WidgetRef ref, Debt debt) {
      final isDebit = debt.type == DebtType.debit;
      final theme = Theme.of(context);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DebtDetailsPage(debt: debt))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: isDebit ? Colors.orangeAccent.withOpacity(0.1) : Colors.purpleAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDebit ? Icons.outbound : Icons.input, 
                      color: isDebit ? Colors.orangeAccent : Colors.purpleAccent,
                      size: 20
                    ),
                ),
                title: Text(debt.personName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text("Due: ${DateFormat.MMMd().format(debt.date)}", style: theme.textTheme.bodySmall),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.compactSimpleCurrency().format(debt.remainingAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDebit ? Colors.orangeAccent : Colors.purpleAccent,
                      ),
                    ),
                    Text("remaining", style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                  ],
                ),
            ),
          ),
        ),
      );
  }

  Widget _buildAllowanceTile(BuildContext context, Allowance allowance) {
     final theme = Theme.of(context);
     return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllowanceDetailsPage(allowance: allowance))),
           borderRadius: BorderRadius.circular(16),
           child: Container(
              decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wallet, color: Colors.blueAccent, size: 20),
                ),
                title: const Text("Allowance"),
                subtitle: LinearProgressIndicator(
                    value: allowance.totalAmount > 0 ? allowance.remainingAmount / allowance.totalAmount : 0,
                    backgroundColor: Colors.grey[800],
                    color: Colors.blueAccent,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                ),
                trailing: Text(
                     NumberFormat.compactSimpleCurrency().format(allowance.remainingAmount),
                     style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ),
           ),
        ),
     );
  }

  Widget _buildTransactionTile(BuildContext context, WidgetRef ref, TransactionModel transaction) {
    final isExpense = transaction.type == CategoryType.expense;
    final theme = Theme.of(context);
    
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, 
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
          return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                  title: const Text("Delete Transaction?"),
                  content: const Text("This action cannot be undone."),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                  ]
              )
          );
      },
      onDismissed: (_) {
           ref.read(transactionsProvider.notifier).deleteTransaction(transaction.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: isExpense ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                ),
                child: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
                    size: 20,
                ),
            ),
            title: Text(
                NumberFormat.simpleCurrency().format(transaction.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
                ),
            ),
            subtitle: Text(DateFormat.yMMMd().format(transaction.date), style: theme.textTheme.bodySmall),
            trailing: transaction.note.isNotEmpty 
                ? Icon(Icons.note_outlined, size: 16, color: Colors.grey[600]) 
                : null,
            onTap: () {
                showDialog(
                   context: context,
                   builder: (context) => TransactionDialog(
                      initialMemberId: transaction.memberId,
                      transactionToEdit: transaction,
                   ),
                );
            },
          ),
        ),
      ),
    );
  }
}
