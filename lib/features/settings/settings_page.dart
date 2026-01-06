import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/family_members_page.dart';
import 'pages/categories_page.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

import '../../core/providers/currency_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyAsyncValue = ref.watch(currencyProvider);
    final currentCurrency = currencyAsyncValue.valueOrNull ?? '\$';

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            centerTitle: false,
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsSection(
              children: [
                SettingsTile(
                  icon: const Icon(Icons.people),
                  iconColor: Colors.blueAccent,
                  title: 'Family Members',
                  subtitle: 'Manage members and reset days',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FamilyMembersPage()),
                    );
                  },
                ),
                SettingsTile(
                  icon: const Icon(Icons.category),
                  iconColor: Colors.orangeAccent,
                  title: 'Categories',
                  subtitle: 'Manage income and expense categories',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CategoriesPage()),
                    );
                  },
                ),
                SettingsTile(
                  icon: const Icon(Icons.currency_exchange),
                  iconColor: Colors.greenAccent,
                  title: 'Currency',
                  subtitle: 'Current: $currentCurrency',
                  onTap: () => _showCurrencySelectionDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelectionDialog(BuildContext context, WidgetRef ref) {
    final currencies = [
      '\$', '€', '£', '¥', '₹', '₽', '₩', '₨', '৳', '₪', '﷼', '₦', '฿', 'R',
      'kr', 'zł', '₫', '₱', '₲', '₴', '₡', '₵', '₸', '₮', '₭', '₺', '₼', '₾',
      '₿', '¢', '¤', '₣', '₤', '₥', '₧', '₯', '₰', '₳', '₶', '₷', '₻', '৲',
      '৻', '֏', '؋', '꠸', '៛'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                return InkWell(
                  onTap: () {
                    ref.read(currencyProvider.notifier).setCurrency(currency);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currency,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
