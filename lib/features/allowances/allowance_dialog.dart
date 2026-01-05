import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/family_member_provider.dart';
import '../../core/providers/allowance_provider.dart';

class AllowanceDialog extends ConsumerStatefulWidget {
  final String initialMemberId; // Who is giving the allowance (FROM)
  const AllowanceDialog({super.key, required this.initialMemberId});

  @override
  ConsumerState<AllowanceDialog> createState() => _AllowanceDialogState();
}

class _AllowanceDialogState extends ConsumerState<AllowanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;
  DateTime? _endDate;
  final _amountController = TextEditingController();
  String? _receiverId;
  bool _isSelf = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);

    return AlertDialog(
      title: const Text('Give Allowance'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               // 1. Receiver
               membersAsync.when(
                data: (members) => Column(
                    children: [
                       DropdownButtonFormField<String>(
                        value: _receiverId,
                        decoration: const InputDecoration(labelText: 'Receiver'),
                        items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                        onChanged: (val) => setState(() {
                            _receiverId = val;
                            _isSelf = val == widget.initialMemberId;
                        }),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      if (_isSelf) 
                         const Padding(
                           padding: EdgeInsets.only(top: 8.0),
                           child: Text("Setting aside allowance for self.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                         )
                    ]
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => const SizedBox(),
               ),
              const SizedBox(height: 16),

              // 2. Amount
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

              // 3. Start Date
              ListTile(
                title: Text("Start: ${DateFormat.yMMMd().format(_startDate)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),

              // 4. End Date
              ListTile(
                title: Text("End: ${_endDate != null ? DateFormat.yMMMd().format(_endDate!) : 'None'}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
        setState(() {
            if (isStart) {
                _startDate = picked;
                // If end is before start, clear end
                if (_endDate != null && _endDate!.isBefore(_startDate)) {
                    _endDate = null;
                }
            } else {
                _endDate = picked;
            }
        });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _receiverId != null) {
      ref.read(allowancesProvider.notifier).createAllowance(
        fromMemberId: widget.initialMemberId,
        toMemberId: _receiverId!,
        totalAmount: double.parse(_amountController.text),
        startDate: _startDate,
        endDate: _endDate,
      );
      Navigator.pop(context);
    }
  }
}
