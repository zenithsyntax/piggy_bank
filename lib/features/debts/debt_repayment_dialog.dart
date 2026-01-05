import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/debt.dart';
import '../../core/providers/debt_provider.dart';

class DebtRepaymentDialog extends ConsumerStatefulWidget {
  final String debtId;
  final double remainingAmount;
  final DebtType type;

  const DebtRepaymentDialog({
    super.key,
    required this.debtId,
    required this.remainingAmount,
    required this.type,
  });

  @override
  ConsumerState<DebtRepaymentDialog> createState() => _DebtRepaymentDialogState();
}

class _DebtRepaymentDialogState extends ConsumerState<DebtRepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  late double _maxAmount;

  @override
  void initState() {
    super.initState();
    _maxAmount = widget.remainingAmount;
    _amountController.text = _maxAmount.toStringAsFixed(2); // Default to full amount
  }

  @override
  Widget build(BuildContext context) {
    final isDebit = widget.type == DebtType.debit;
    final title = isDebit ? 'Receive Return' : 'Make Repayment';
    final label = isDebit ? 'Amount Received' : 'Amount Paid';

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Remaining Balance: ${NumberFormat.simpleCurrency().format(_maxAmount)}", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: label),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final amount = double.tryParse(value);
                if (amount == null) return 'Invalid number';
                if (amount <= 0) return 'Must be positive';
                if (amount > _maxAmount) return 'Cannot exceed remaining amount';
                return null;
              },
            ),
             const SizedBox(height: 16),
            ListTile(
              title: Text("Date: ${DateFormat.yMMMd().format(_date)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
             const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
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
      ref.read(debtsProvider.notifier).addRepayment(
        debtId: widget.debtId,
        amount: double.parse(_amountController.text),
        date: _date,
        note: _noteController.text,
      );
      Navigator.pop(context);
    }
  }
}
