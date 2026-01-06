import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/models/category.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Categories'),
            centerTitle: false,
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) => SettingsSection(
                children: [
                  ...categories.map((category) => SettingsTile(
                        icon: Icon(category.type == CategoryType.expense
                            ? Icons.money_off
                            : Icons.attach_money),
                        iconColor: category.type == CategoryType.expense
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        title: category.name,
                        subtitle: category.type.name.toUpperCase(),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, 
                            color: Colors.white.withOpacity(0.3),
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(
                            context,
                            'Delete ${category.name}?',
                            () => ref.read(categoriesProvider.notifier).deleteCategory(category.id),
                          ),
                        ),
                      )),
                  SettingsTile(
                    icon: const Icon(Icons.add),
                    iconColor: Colors.orangeAccent,
                    title: 'Add Category',
                    onTap: () => _showAddCategoryDialog(context, ref),
                  ),
                ],
              ),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )),
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    CategoryType type = CategoryType.expense;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Category', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SegmentedButton<CategoryType>(
                style: ButtonStyle(
                  side: MaterialStateProperty.all(BorderSide(color: Colors.white.withOpacity(0.1))),
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.blueAccent.withOpacity(0.2);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.blueAccent;
                    }
                    return Colors.white70;
                  }),
                ),
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense, 
                    label: Text('Expense'),
                    icon: Icon(Icons.money_off, size: 16),
                  ),
                  ButtonSegment(
                    value: CategoryType.income, 
                    label: Text('Income'),
                    icon: Icon(Icons.attach_money, size: 16),
                  ),
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
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
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

  void _confirmDelete(BuildContext context, String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
