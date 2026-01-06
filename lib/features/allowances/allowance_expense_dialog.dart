import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/allowance_provider.dart';
import '../../core/providers/currency_provider.dart';

class AllowanceExpenseDialog extends ConsumerStatefulWidget {
  final String allowanceId;
  final double remainingAmount;
  
  const AllowanceExpenseDialog({super.key, required this.allowanceId, required this.remainingAmount});

  @override
  ConsumerState<AllowanceExpenseDialog> createState() => _AllowanceExpenseDialogState();
}

class _AllowanceExpenseDialogState extends ConsumerState<AllowanceExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider).valueOrNull ?? '\$';
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return AlertDialog(
      title: const Text('Add Allowance Expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text('Remaining Allowance: ${NumberFormat.currency(symbol: currency).format(widget.remainingAmount)}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
               const SizedBox(height: 16),
               
              // 1. Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: currency,
                  prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  final amount = double.parse(value);
                  if (amount <= 0) return 'Must be positive';
                  if (amount > widget.remainingAmount) return 'Exceeds remaining allowance';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Category
              categoriesAsync.when(
                data: (categories) {
                  final filtered = categories.where((c) => c.type == CategoryType.expense).toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => const SizedBox(), 
              ),
              const SizedBox(height: 16),

              // 3. Date
              ListTile(
                title: Text("Date: ${DateFormat.yMMMd().format(_date)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              
              // 4. Note
               const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (Optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      ref.read(allowanceExpensesProvider.notifier).addExpense(
        allowanceId: widget.allowanceId,
        categoryId: _selectedCategoryId!,
        amount: double.parse(_amountController.text),
        date: _date,
        note: _noteController.text,
      );
      Navigator.pop(context);
    }
  }
}
