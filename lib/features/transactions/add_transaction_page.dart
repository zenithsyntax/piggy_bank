import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/transaction_provider.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final String initialMemberId;
  final TransactionModel? transactionToEdit;

  const AddTransactionPage({
    super.key,
    required this.initialMemberId,
    this.transactionToEdit,
  });

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late CategoryType _type;
  late DateTime _date;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _type = t.type;
      _date = t.date;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note;
      _selectedCategoryId = t.categoryId;
    } else {
      _type = CategoryType.expense;
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.transactionToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Transaction Type Segmented Button
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.money_off),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.attach_money),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<CategoryType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                    // Reset category logic
                    if (isEditing && _type == widget.transactionToEdit!.type) {
                      _selectedCategoryId =
                          widget.transactionToEdit!.categoryId;
                    } else {
                      _selectedCategoryId = null;
                    }
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) <= 0) return 'Must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Category Dropdown
              categoriesAsync.when(
                data: (categories) {
                  final filtered =
                      categories.where((c) => c.type == _type).toList();
                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No categories found. Go to Settings.'),
                    );
                  }

                  // Verify selection
                  if (_selectedCategoryId != null &&
                      !filtered.any((c) => c.id == _selectedCategoryId)) {
                    _selectedCategoryId = null;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: filtered
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading categories: $e'),
              ),
              const SizedBox(height: 16),

              // 4. Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_date),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Note Field
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // 6. Submit Button
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
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
      if (widget.transactionToEdit != null) {
        final old = widget.transactionToEdit!;
        final updated = old.copyWith(
          categoryId: _selectedCategoryId!,
          amount: double.parse(_amountController.text),
          type: _type,
          date: _date,
          note: _noteController.text,
        );
        ref.read(transactionsProvider.notifier).updateTransaction(updated);
      } else {
        ref.read(transactionsProvider.notifier).addTransaction(
              memberId: widget.initialMemberId,
              categoryId: _selectedCategoryId!,
              amount: double.parse(_amountController.text),
              type: _type,
              date: _date,
              note: _noteController.text,
            );
      }
      Navigator.pop(context);
    }
  }
}
