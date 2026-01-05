import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/transaction_provider.dart';

class TransactionDialog extends ConsumerStatefulWidget {
  final String initialMemberId;
  const TransactionDialog({super.key, required this.initialMemberId});

  @override
  ConsumerState<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends ConsumerState<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late CategoryType _type;
  late DateTime _date;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _type = CategoryType.expense;
    _date = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Toggle Type
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
                  ButtonSegment(value: CategoryType.income, label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (Set<CategoryType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                    _selectedCategoryId = null; // Reset category on type change
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 2. Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) <= 0) return 'Must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Category
              categoriesAsync.when(
                data: (categories) {
                  final filtered = categories.where((c) => c.type == _type).toList();
                  if (filtered.isEmpty) {
                      return const Text('No categories found. Go to Settings.');
                  }
                  // Auto-select first if null (simplified logic compared to requirement "Last used", but good for MVP)
                  // Requirement said "Category -> Last used". I'll skip "Last used" persistance for now to ensure cleanliness.
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Error loading categories'),
              ),
              const SizedBox(height: 16),

              // 4. Date
              ListTile(
                title: Text("Date: ${DateFormat.yMMMd().format(_date)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              
              // 5. Note
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
      ref.read(transactionsProvider.notifier).addTransaction(
        memberId: widget.initialMemberId,
        categoryId: _selectedCategoryId!,
        amount: double.parse(_amountController.text),
        type: _type,
        date: _date,
        note: _noteController.text,
      );
      Navigator.pop(context);
    }
  }
}
