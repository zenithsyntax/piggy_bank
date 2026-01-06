import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/allowance_provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/category.dart';
import '../../../core/models/debt.dart';
import '../../../core/models/allowance.dart';
import '../../../core/utils/summary_card.dart';
import '../../allowances/allowance_details_page.dart';
import '../../debts/debt_details_page.dart';
import '../../transactions/transaction_dialog.dart';

class MemberDashboard extends ConsumerStatefulWidget {
  final String memberId;

  const MemberDashboard({super.key, required this.memberId});

  @override
  ConsumerState<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends ConsumerState<MemberDashboard> {
  String _transactionFilter = 'All'; // All, Income, Expense
  String _debtFilter = 'All'; // All, To Pay, To Receive

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(memberBalanceProvider(widget.memberId));
    final transactions = ref.watch(memberTransactionsProvider(widget.memberId));
    final debtSummary = ref.watch(memberDebtSummaryProvider(widget.memberId));
    final activeAllowances = ref.watch(activeAllowancesProvider(widget.memberId));
    final allDebts = ref.watch(memberDebtsProvider(widget.memberId));
    final theme = Theme.of(context);

    final currentBalance = balance['balance'] ?? 0.0;

    // Determine tabs
    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    // 1. Transactions Tab
    tabs.add(const Tab(text: 'Transactions'));
    tabViews.add(_buildActivityTab(context, ref, transactions, balance));

    // 2. Allowance Tab (if active)
    if (activeAllowances.isNotEmpty) {
      tabs.add(const Tab(text: 'Allowances'));
      tabViews.add(_buildAllowanceTab(context, ref, activeAllowances));
    }

    // 3. Debts Tab (if exists)
    if (allDebts.isNotEmpty || debtSummary['debit']! > 0 || debtSummary['credit']! > 0) {
      tabs.add(const Tab(text: 'Debts'));
      tabViews.add(_buildDebtTab(context, ref, debtSummary, allDebts));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          // Total Balance Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SummaryCard(
              title: 'Total Balance',
              amount: NumberFormat.simpleCurrency().format(currentBalance),
              subtitle: 'Available funds', 
              icon: Icons.account_balance_wallet,
              // Use explicit background color for the main card to make it stand out professionally
              backgroundColor: currentBalance >= 0 ? const Color(0xFF1E1E1E) : const Color(0xFF261214),
              color: currentBalance >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
            ),
          ),

          // Tab Bar with modernized look
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: tabs,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
          ),
          
          const Divider(height: 1, color: Colors.white10),

          // Tab Content
          Expanded(
            child: TabBarView(
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, WidgetRef ref, List<TransactionModel> transactions, Map<String, double> balance) {
    // Filter transactions
    final filteredTransactions = transactions.where((t) {
      if (_transactionFilter == 'Income') return t.type == CategoryType.income;
      if (_transactionFilter == 'Expense') return t.type == CategoryType.expense;
      return true;
    }).toList();

    return Column(
      children: [
        // Income/Expense Summary & Filter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      context,
                      'Income',
                      balance['income']!,
                      const Color(0xFF00C853), // Material Green A700
                      Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatCard(
                      context,
                      'Expense',
                      balance['expense']!,
                      const Color(0xFFFF5252), // Material Red A200
                      Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _transactionFilter == 'All', () => setState(() => _transactionFilter = 'All')),
                    const SizedBox(width: 8),
                    _buildFilterChip('Income', _transactionFilter == 'Income', () => setState(() => _transactionFilter = 'Income')),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expense', _transactionFilter == 'Expense', () => setState(() => _transactionFilter = 'Expense')),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filteredTransactions.isEmpty
              ? _buildEmptyState("No ${_transactionFilter.toLowerCase()} transactions found")
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = filteredTransactions[index];
                    // Add bottom padding for FAB
                    if (index == filteredTransactions.length - 1) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: _buildTransactionTile(context, ref, t),
                      );
                    }
                    return _buildTransactionTile(context, ref, t);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAllowanceTab(BuildContext context, WidgetRef ref, List<Allowance> allowances) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allowances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
         if (index == allowances.length - 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildAllowanceTile(context, allowances[index]),
            );
         }
        return _buildAllowanceTile(context, allowances[index]);
      },
    );
  }

  Widget _buildDebtTab(BuildContext context, WidgetRef ref, Map<String, double> debtSummary, List<Debt> allDebts) {
    final pendingDebts = allDebts.where((d) => d.status == DebtStatus.pending).toList();

    // Filter Debts
    final filteredDebts = pendingDebts.where((d) {
       if (_debtFilter == 'To Pay') return d.type == DebtType.debit; // You owe
       if (_debtFilter == 'To Receive') return d.type == DebtType.credit; // They owe you
       return true;
    }).toList();

    return Column(
      children: [
         Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
             children: [
               _buildDebtSummaryCard(context, debtSummary),
               const SizedBox(height: 16),
                SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _debtFilter == 'All', () => setState(() => _debtFilter = 'All')),
                    const SizedBox(width: 8),
                    _buildFilterChip('To Pay', _debtFilter == 'To Pay', () => setState(() => _debtFilter = 'To Pay')),
                    const SizedBox(width: 8),
                    _buildFilterChip('To Receive', _debtFilter == 'To Receive', () => setState(() => _debtFilter = 'To Receive')),
                  ],
                ),
              ),
             ],
           ),
         ),
         
        Expanded(
          child: filteredDebts.isEmpty
            ? _buildEmptyState("No active debts found")
            : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredDebts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                 if (index == filteredDebts.length - 1) {
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 80),
                     child: _buildDebtTile(context, ref, filteredDebts[index]),
                   );
                 }
                 return _buildDebtTile(context, ref, filteredDebts[index]);
              },
            ),
        ),
      ],
    );
  }

  // --- Widgets Components ---

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(BuildContext context, String title, double amount, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Slightly lighter black
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)), // 0.05 * 255
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25), // 0.1 * 255
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    NumberFormat.compactSimpleCurrency().format(amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
        color: const Color(0xFF1E1E1E), // Solid professional dark gray
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50), 
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildSummaryItem(context, 'You Owe', debt['debit']!, const Color(0xFFFFAB91))),
            const VerticalDivider(color: Colors.white10, width: 32),
            Expanded(child: _buildSummaryItem(context, 'Owes You', debt['credit']!, const Color(0xFFCE93D8))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, double amount, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text(
          NumberFormat.compactSimpleCurrency().format(amount),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDebtTile(BuildContext context, WidgetRef ref, Debt debt) {
    final isDebit = debt.type == DebtType.debit;
    final theme = Theme.of(context);

    // Debit (You Owe) -> Orange, Credit (They Owe) -> Purple
    final baseColor = isDebit ? Colors.orangeAccent : Colors.purpleAccent;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DebtDetailsPage(debt: debt))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(8)), // 0.03 * 255
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: baseColor.withAlpha(25), // 0.1 * 255
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDebit ? Icons.arrow_outward : Icons.arrow_back, // Outward for paying, Back for receiving
                color: baseColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debt.personName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                   Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text("Due ${DateFormat.MMMd().format(debt.date)}", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.compactSimpleCurrency().format(debt.remainingAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: baseColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(
                     color: Colors.white10,
                     borderRadius: BorderRadius.circular(4),
                   ),
                   child: Text(isDebit ? "TO PAY" : "RECEIVE", style: const TextStyle(fontSize: 9, color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllowanceTile(BuildContext context, Allowance allowance) {
    final theme = Theme.of(context);
    final progress = allowance.totalAmount > 0 ? allowance.remainingAmount / allowance.totalAmount : 0.0;
    
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllowanceDetailsPage(allowance: allowance))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withAlpha(25)), // 0.1 * 255
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha(25), // 0.1 * 255
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent, size: 24),
                ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("Allowance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       const SizedBox(height: 4),
                       // Frequency not available in model
                       Text("Total: ${NumberFormat.simpleCurrency().format(allowance.totalAmount)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                     ],
                   ),
                 ),
                 Text(
                   NumberFormat.compactSimpleCurrency().format(allowance.remainingAmount),
                   style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                 ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[800],
                  color: Colors.blueAccent,
                  minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Left", style: theme.textTheme.bodySmall),
                Text("${(progress * 100).toInt()}%", style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, WidgetRef ref, TransactionModel transaction) {
    final isExpense = transaction.type == CategoryType.expense;
    final theme = Theme.of(context);
    final color = isExpense ? Colors.redAccent : Colors.greenAccent;
    
    // Lookup category name
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoryName = categoriesAsync.maybeWhen(
      data: (categories) => categories.firstWhere((c) => c.id == transaction.categoryId, orElse: () => TransactionCategory(id: '', name: 'Uncategorized', type: CategoryType.expense)).name,
      orElse: () => 'Loading...',
    );

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
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text("Delete Transaction?"),
            content: const Text("This action cannot be undone."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Delete")),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(transactionsProvider.notifier).deleteTransaction(transaction.id);
      },
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TransactionDialog(
              initialMemberId: transaction.memberId,
              transactionToEdit: transaction,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25), // 0.1 * 255
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (transaction.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          transaction.note,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isExpense ? '-' : '+'}${NumberFormat.simpleCurrency(decimalDigits: 0).format(transaction.amount)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(transaction.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
