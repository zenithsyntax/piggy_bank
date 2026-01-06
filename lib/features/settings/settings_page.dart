import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/family_member_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/family_member.dart';
import '../../core/models/category.dart';
import 'widgets/member_settings_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Family Members'),
          membersAsync.when(
            data: (members) => Column(
              children: [
                ...members.map((member) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(member.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () => _showEditMemberDialog(context, member),
                          ),
                          if (member.name != 'Me')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(
                                context, 
                                'Delete ${member.name}?', 
                                () => ref.read(familyMembersProvider.notifier).deleteMember(member.id),
                              ),
                            ),
                        ],
                      ),
                    )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Family Member'),
                  onTap: () => _showAddMemberDialog(context, ref),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Categories'),
          categoriesAsync.when(
            data: (categories) => Column(
              children: [
                 ...categories.map((category) => ListTile(
                      leading: Icon(
                        category.type == CategoryType.expense ? Icons.money_off : Icons.attach_money,
                        color: category.type == CategoryType.expense ? Colors.redAccent : Colors.greenAccent,
                      ),
                      title: Text(category.name),
                      subtitle: Text(category.type.name.toUpperCase()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(
                           context, 
                           'Delete ${category.name}?',
                           () => ref.read(categoriesProvider.notifier).deleteCategory(category.id),
                        ),
                      ),
                    )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Category'),
                  onTap: () => _showAddCategoryDialog(context, ref),
                ),
              ],
            ),
             loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const MemberSettingsDialog(),
    );
  }

  void _showEditMemberDialog(BuildContext context, FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => MemberSettingsDialog(member: member),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    CategoryType type = CategoryType.expense;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SegmentedButton<CategoryType>(
                segments: const [
                   ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
                   ButtonSegment(value: CategoryType.income, label: Text('Income')),
                ],
                selected: {type},
                onSelectionChanged: (Set<CategoryType> newSelection) {
                  setState(() {
                    type = newSelection.first;
                  });
                },
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(categoriesProvider.notifier).addCategory(controller.text.trim(), type);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
