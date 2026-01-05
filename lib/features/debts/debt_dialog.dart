import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/debt.dart';
import '../../core/providers/debt_provider.dart';

class DebtDialog extends ConsumerStatefulWidget {
  final String initialMemberId;
  final Debt? debtToEdit;
  
  const DebtDialog({super.key, required this.initialMemberId, this.debtToEdit});

  @override
  ConsumerState<DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends ConsumerState<DebtDialog> {
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
        _amountController.text = d.amount.toString(); // Note: Editing total amount might be tricky if remaing amount exists.
        // If we edit amount, we might want to adjust remaining amount too? 
        // For simplicity, if editing, we update total amount. 
        // The remaining amount should also scale or be reset? 
        // Simpler approach: Update total amount. Remaining amount = New Total - (Old Total - Old Remaining).
        // i.e. Keep the "repaid" amount constant.
        _personNameController.text = d.personName;
        _noteController.text = d.note;
    } else {
        _type = DebtType.debit; // Default: I gave money
        _date = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.debtToEdit != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Debt' : 'Add Debt/Credit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Toggle Type
              SegmentedButton<DebtType>(
                segments: const [
                  ButtonSegment(value: DebtType.debit, label: Text('I Gave (Debit)')),
                  ButtonSegment(value: DebtType.credit, label: Text('I Took (Credit)')),
                ],
                selected: {_type},
                onSelectionChanged: (Set<DebtType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 2. Person Name
               TextFormField(
                controller: _personNameController,
                decoration: const InputDecoration(labelText: 'Person Name'),
                textCapitalization: TextCapitalization.words,
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // 3. Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Total Amount'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  if (double.parse(value) <= 0) return 'Must be positive';
                  return null;
                },
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
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      
      if (widget.debtToEdit != null) {
          // Editing
          final oldDebt = widget.debtToEdit!;
          // Calculate new remaining amount. 
          // Repaid = OldTotal - OldRemaining.
          // NewRemaining = NewTotal - Repaid.
          final repaid = oldDebt.amount - oldDebt.remainingAmount;
          var newRemaining = amount - repaid;
          if (newRemaining < 0) newRemaining = 0; // Handled? Or prevent lowering total below repaid?
          
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
          // Creating
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
