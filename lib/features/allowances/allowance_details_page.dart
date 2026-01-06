import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/allowance.dart';
import '../../core/providers/allowance_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/utils/summary_card.dart';
import 'allowance_expense_dialog.dart';

class AllowanceDetailsPage extends ConsumerWidget {
  final Allowance allowance;

  const AllowanceDetailsPage({super.key, required this.allowance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowancesList = ref.watch(allowancesProvider).asData?.value ?? [];
    final currentAllowance = allowancesList.firstWhere(
      (a) => a.id == allowance.id,
      orElse: () => allowance,
    );

    final expenses = ref.watch(expensesByAllowanceIdProvider(currentAllowance.id));
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];

    String getCategoryName(String catId) {
      final cat = categories.where((c) => c.id == catId);
      return cat.isNotEmpty ? cat.first.name : 'Unknown';
    }

    final theme = Theme.of(context);
    final progress = currentAllowance.totalAmount > 0
        ? (currentAllowance.remainingAmount / currentAllowance.totalAmount)
        : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Allowance Details'),
            centerTitle: false,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Info/Edit logic could go here
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SummaryCard(
                title: 'Remaining Balance',
                amount: NumberFormat.simpleCurrency().format(currentAllowance.remainingAmount),
                subtitle: 'of ${NumberFormat.simpleCurrency().format(currentAllowance.totalAmount)} total allowance',
                progress: progress,
                icon: Icons.account_balance_wallet,
                backgroundColor: const Color(0xFF1E1E1E),
                color: theme.colorScheme.primary, // Uses the new indigo
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                   Text(
                    "Expenses History",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${expenses.length} Transactions",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (expenses.isEmpty)
             SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.white10),
                    const SizedBox(height: 16),
                    Text("No expenses yet", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white38)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = expenses[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor == Colors.black ? const Color(0xFF1E1E1E) : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_downward_rounded, color: theme.colorScheme.error, size: 20),
                        ),
                        title: Text(
                          getCategoryName(expense.categoryId),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          DateFormat.yMMMd().format(expense.date),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              NumberFormat.simpleCurrency().format(expense.amount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            if (expense.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  expense.note,
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: expenses.length,
              ),
            ),
             const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AllowanceExpenseDialog(
              allowanceId: currentAllowance.id,
              remainingAmount: currentAllowance.remainingAmount,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("New Expense"),
      ),
    );
  }
}

