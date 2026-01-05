import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/allowance.dart';
import '../../core/providers/allowance_provider.dart';
import '../../core/providers/category_provider.dart';
import 'allowance_expense_dialog.dart';

class AllowanceDetailsPage extends ConsumerWidget {
  final Allowance allowance;

  const AllowanceDetailsPage({super.key, required this.allowance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch allowance again to get updates (e.g. balance change)
    final allowancesList = ref.watch(allowancesProvider).asData?.value ?? [];
    // Fallback to passed allowance if not found (shouldn't happen unless deleted)
    final currentAllowance = allowancesList.firstWhere(
      (a) => a.id == allowance.id, 
      orElse: () => allowance
    );
    
    final expenses = ref.watch(expensesByAllowanceIdProvider(currentAllowance.id));
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    
    String getCategoryName(String catId) {
        final cat = categories.where((c) => c.id == catId);
        return cat.isNotEmpty ? cat.first.name : 'Unknown';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Allowance Details')),
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
                                   const Text("Remaining", style: TextStyle(color: Colors.grey)),
                                   Text(NumberFormat.simpleCurrency().format(currentAllowance.remainingAmount), 
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: Colors.greenAccent, fontWeight: FontWeight.bold
                                        )),
                               ],
                           ),
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.end,
                               children: [
                                   const Text("Total", style: TextStyle(color: Colors.grey)),
                                   Text(NumberFormat.simpleCurrency().format(currentAllowance.totalAmount), 
                                         style: Theme.of(context).textTheme.titleLarge),
                               ],
                           ),
                       ]
                   ),
                   const SizedBox(height: 10),
                   LinearProgressIndicator(
                       value: currentAllowance.totalAmount > 0 ? (currentAllowance.remainingAmount / currentAllowance.totalAmount) : 0,
                       backgroundColor: Colors.grey[800],
                       color: Colors.greenAccent,
                       minHeight: 10,
                       borderRadius: BorderRadius.circular(5),
                   ),
                   const SizedBox(height: 16),
                   Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                           Text("Start: ${DateFormat.yMMMd().format(currentAllowance.startDate)}"),
                           if (currentAllowance.endDate != null)
                             Text("End: ${DateFormat.yMMMd().format(currentAllowance.endDate!)}"),
                       ]
                   )
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
                children: [
                    Text("Expenses History", style: Theme.of(context).textTheme.titleMedium),
                ],
            ),
          ),
          
          // Expense List
          Expanded(
              child: expenses.isEmpty 
              ? const Center(child: Text("No expenses yet."))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.money_off, size: 20)),
                          title: Text(getCategoryName(expense.categoryId)),
                          subtitle: Text(DateFormat.yMMMd().format(expense.date) + (expense.note.isNotEmpty ? "\n${expense.note}" : "")),
                          trailing: Text(NumberFormat.simpleCurrency().format(expense.amount), 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      );
                  },
              )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
               showDialog(
                  context: context,
                  builder: (context) => AllowanceExpenseDialog(
                      allowanceId: currentAllowance.id,
                      remainingAmount: currentAllowance.remainingAmount,
                  ),
              );
          },
      ),
    );
  }
}
