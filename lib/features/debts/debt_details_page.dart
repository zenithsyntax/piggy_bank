import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/debt.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/utils/summary_card.dart';
import 'debt_repayment_dialog.dart';
import 'add_debt_page.dart';
import '../../core/providers/currency_provider.dart';

class DebtDetailsPage extends ConsumerWidget {
  final Debt debt;

  const DebtDetailsPage({super.key, required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider).valueOrNull ?? '\$';
    final debtsList = ref.watch(debtsProvider).asData?.value ?? [];
    // Get updated debt object
    final currentDebt = debtsList.firstWhere(
      (d) => d.id == debt.id,
      orElse: () => debt,
    );
    
    final repaymentsAsync = ref.watch(debtRepaymentsProvider(currentDebt.id));

    // Calculate progress
    // Total Amount = initial amount. Remaining = current.
    // Progress should show how much is returned.
    // Returned = Total - Remaining.
    // Progress = Returned / Total.
    final returnedAmount = currentDebt.amount - currentDebt.remainingAmount;
    final progress = currentDebt.amount > 0 ? (returnedAmount / currentDebt.amount) : 0.0;
    
    final isDebit = currentDebt.type == DebtType.debit; // I Gave
    final color = isDebit ? Colors.orangeAccent : Colors.purpleAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
                _showEditDialog(context, ref, currentDebt);
            },
          ),
        ],
      ),
      body: Column(
        children: [
            // Header Card
            Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          const Text("Remaining (Pending)", style: TextStyle(color: Colors.grey)),
                                          Text(NumberFormat.currency(symbol: currency).format(currentDebt.remainingAmount), 
                                               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                   color: color, fontWeight: FontWeight.bold
                                               )),
                                      ],
                                  ),
                                  Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                          const Text("Total Amount", style: TextStyle(color: Colors.grey)),
                                          Text(NumberFormat.currency(symbol: currency).format(currentDebt.amount), 
                                                style: Theme.of(context).textTheme.titleLarge),
                                      ]
                                  )
                              ]
                          ),
                          const SizedBox(height: 10),
                          // Progress Bar: Shows how much has been SETTLED/RETURNED.
                          ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[800],
                                  color: Colors.greenAccent, // Green = Good (Returned)
                                  minHeight: 12,
                              ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                              alignment: Alignment.centerRight,
                              child: Text("${(progress * 100).toStringAsFixed(1)}% Returned", style: const TextStyle(fontSize: 12, color: Colors.grey))
                          ),
                          
                          const SizedBox(height: 16),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text("Person: ${currentDebt.personName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(DateFormat.yMMMd().format(currentDebt.date)),
                              ]
                          ),
                           if (currentDebt.note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Align(alignment: Alignment.centerLeft, child: Text("Note: ${currentDebt.note}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
                           ]
                      ]
                  ),
              ),
            ),
            
             Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                    children: [
                        Text("Repayment History", style: Theme.of(context).textTheme.titleMedium),
                    ],
                ),
            ),
            
            Expanded(
                child: repaymentsAsync.when(
                    data: (repayments) {
                        if (repayments.isEmpty) return const Center(child: Text("No repayments yet."));
                        return ListView.builder(
                            itemCount: repayments.length,
                            itemBuilder: (context, index) {
                                final r = repayments[index];
                                return Dismissible(
                                    key: ValueKey(r.id),
                                    background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete)),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                        return await showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                                title: const Text("Delete Repayment?"),
                                                content: const Text("This will add the amount back to the remaining balance."),
                                                actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                                                ]
                                            )
                                        );
                                    },
                                    onDismissed: (_) {
                                        ref.read(debtsProvider.notifier).deleteRepayment(r.id, currentDebt.id, r.amount);
                                    },
                                    child: ListTile(
                                        leading: const CircleAvatar(child: Icon(Icons.check, size: 20)),
                                        title: Text(DateFormat.yMMMd().format(r.date)),
                                        subtitle: r.note.isNotEmpty ? Text(r.note) : null,
                                        trailing: Text(NumberFormat.currency(symbol: currency).format(r.amount), 
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                    ),
                                );
                            },
                        );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text("Error: $e")),
                ),
            ),
        ],
      ),
      floatingActionButton: currentDebt.status != DebtStatus.settled ? FloatingActionButton.extended(
          onPressed: () {
               showDialog(
                  context: context,
                  builder: (context) => DebtRepaymentDialog(
                      debtId: currentDebt.id,
                      remainingAmount: currentDebt.remainingAmount,
                      type: currentDebt.type,
                  ),
              );
          },
          label: Text(currentDebt.type == DebtType.debit ? "Receive Return" : "Make Repayment"),
          icon: const Icon(Icons.add),
      ) : null,
    );
  }
  
  void _showEditDialog(BuildContext context, WidgetRef ref, Debt debt) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddDebtPage(
              initialMemberId: debt.memberId,
              debtToEdit: debt,
            ),
          ),
      );
  }
}
