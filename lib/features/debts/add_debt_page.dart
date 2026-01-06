import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/debt.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/providers/currency_provider.dart';

class AddDebtPage extends ConsumerStatefulWidget {
  final String initialMemberId;
  final Debt? debtToEdit;

  const AddDebtPage({
    super.key,
    required this.initialMemberId,
    this.debtToEdit,
  });

  @override
  ConsumerState<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends ConsumerState<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  late DebtType _type;
  late DateTime _date;
  final _amountController = TextEditingController();
  final _personNameController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.debtToEdit != null) {
      final d = widget.debtToEdit!;
      _type = d.type;
      _date = d.date;
      _amountController.text = d.amount.toString();
      _personNameController.text = d.personName;
      _noteController.text = d.note;
    } else {
      _type = DebtType.debit; // Default: I gave money
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider).valueOrNull ?? '\$';
    final isEditing = widget.debtToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Debt' : 'Add Debt/Credit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Type Segmented Button
              SegmentedButton<DebtType>(
                segments: const [
                  ButtonSegment(
                    value: DebtType.debit,
                    label: Text('I Gave (Debit)'),
                    icon: Icon(Icons.arrow_upward, color: Colors.redAccent),
                  ),
                  ButtonSegment(
                    value: DebtType.credit,
                    label: Text('I Took (Credit)'),
                    icon: Icon(Icons.arrow_downward, color: Colors.greenAccent),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<DebtType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Person Name
              TextFormField(
                controller: _personNameController,
                decoration: InputDecoration(
                  labelText: 'Person Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // 3. Amount
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  prefixText: currency,
                  prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              // 4. Date
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

              // 5. Note
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
                  label: const Text('Save Debt'),
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
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      if (widget.debtToEdit != null) {
        // Editing logic
        final oldDebt = widget.debtToEdit!;
        final repaid = oldDebt.amount - oldDebt.remainingAmount;
        var newRemaining = amount - repaid;
        if (newRemaining < 0) newRemaining = 0;

        final updatedDebt = oldDebt.copyWith(
          personName: _personNameController.text.trim(),
          amount: amount,
          remainingAmount: newRemaining,
          type: _type,
          date: _date,
          note: _noteController.text,
          status: newRemaining <= 0 ? DebtStatus.settled : DebtStatus.pending,
        );

        ref.read(debtsProvider.notifier).updateDebt(updatedDebt);
      } else {
        // Creating logic
        ref.read(debtsProvider.notifier).addDebt(
              memberId: widget.initialMemberId,
              personName: _personNameController.text.trim(),
              amount: amount,
              type: _type,
              date: _date,
              note: _noteController.text,
            );
      }
      Navigator.pop(context);
    }
  }
}
