import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/family_member.dart';
import '../../../../core/providers/family_member_provider.dart';

class MemberSettingsDialog extends ConsumerStatefulWidget {
  final FamilyMember? member; // If null, adding new member. If not, editing.

  const MemberSettingsDialog({super.key, this.member});

  @override
  ConsumerState<MemberSettingsDialog> createState() => _MemberSettingsDialogState();
}

class _MemberSettingsDialogState extends ConsumerState<MemberSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _resetDay;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _resetDay = widget.member?.resetDay ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (widget.member == null) {
        // Add
        ref.read(familyMembersProvider.notifier).addMember(
              _nameController.text.trim(),
              resetDay: _resetDay,
            );
      } else {
        // Update
        final updatedMember = widget.member!.copyWith(
          name: _nameController.text.trim(),
          resetDay: _resetDay,
        );
        ref.read(familyMembersProvider.notifier).updateMember(updatedMember);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.member == null ? 'Add Member' : 'Edit Member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _resetDay,
              decoration: const InputDecoration(
                labelText: 'Monthly Reset Day',
                helperText: 'Day of the month when finances reset',
              ),
              items: List.generate(31, (index) => index + 1).map((day) {
                return DropdownMenuItem<int>(
                  value: day,
                  child: Text(day.toString()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _resetDay = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
