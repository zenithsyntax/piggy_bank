import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/family_member_provider.dart';
import '../../core/providers/allowance_provider.dart';

class GiveAllowancePage extends ConsumerStatefulWidget {
  final String initialMemberId; // Who is giving the allowance (FROM)
  const GiveAllowancePage({super.key, required this.initialMemberId});

  @override
  ConsumerState<GiveAllowancePage> createState() => _GiveAllowancePageState();
}

class _GiveAllowancePageState extends ConsumerState<GiveAllowancePage> {
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
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Allowance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Receiver Dropdown
              membersAsync.when(
                data: (members) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _receiverId,
                      decoration: InputDecoration(
                        labelText: 'Receiver',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: members
                          .map((m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.name),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() {
                        _receiverId = val;
                        _isSelf = val == widget.initialMemberId;
                      }),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    if (_isSelf)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 12),
                        child: Text(
                          "Setting aside allowance for self.",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      )
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading members: $e'),
              ),
              const SizedBox(height: 16),

              // 2. Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  prefixIcon: const Icon(Icons.attach_money),
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

              // 3. Start Date Picker
              InkWell(
                onTap: () => _pickDate(true),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_startDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. End Date Picker
              InkWell(
                onTap: () => _pickDate(false),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date (Optional)',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat.yMMMd().format(_endDate!)
                        : 'None',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 5. Submit Button
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Create Allowance'),
                ),
              ),
            ],
          ),
        ),
      ),
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
