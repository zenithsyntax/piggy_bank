import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/family_members_page.dart';
import 'pages/categories_page.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      MaterialPageRoute(builder: (context) => const FamilyMembersPage()),
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
                      MaterialPageRoute(builder: (context) => const CategoriesPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
