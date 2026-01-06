import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import '../../../core/providers/family_member_provider.dart';
import '../../../core/models/family_member.dart';
import 'widgets/member_dashboard.dart';
import '../transactions/transaction_dialog.dart';
import '../debts/debt_dialog.dart';
import '../allowances/allowance_dialog.dart';
import '../settings/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: const Center(
                child: Text('No family members found. Go to Settings to add one.')),
          );
        }

        // Ensure selected index is valid
        if (_selectedIndex >= members.length) {
          _selectedIndex = 0;
        }

        // Sync selected member provider
        Future.microtask(() {
          ref
              .read(selectedMemberProvider.notifier)
              .setSelected(members[_selectedIndex].id);
        });

        final currentMember = members[_selectedIndex];

        return Scaffold(
          appBar: _buildAppBar(context),
          body: MemberDashboard(
            key: ValueKey(currentMember.id), // Force rebuild on member change
            memberId: currentMember.id,
          ),
          bottomNavigationBar: members.length >= 2 
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: members.map((m) {
                  return NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: m.name,
                  );
                }).toList(),
              )
            : null,
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: ExpandableFab(
            type: ExpandableFabType.up,
            childrenAnimation: ExpandableFabAnimation.none,
            distance: 70,
            overlayStyle: ExpandableFabOverlayStyle(
              blur: 5,
            ),
            children: [
              FloatingActionButton(
                heroTag: null,
                tooltip: 'Transaction',
                child: const Icon(Icons.attach_money),
                onPressed: () {
                  _showTransactionDialog(context, currentMember);
                },
              ),
              FloatingActionButton(
                heroTag: null,
                tooltip: 'Debt/Credit',
                child: const Icon(Icons.handshake),
                onPressed: () {
                  _showDebtDialog(context, currentMember);
                },
              ),
              FloatingActionButton(
                heroTag: null,
                tooltip: 'Allowance',
                child: const Icon(Icons.card_giftcard),
                onPressed: () {
                  _showAllowanceDialog(context, currentMember);
                },
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.savings, size: 32), // App Logo (Icon)
      ),
      title: const Text('Piggy Bank'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  void _showTransactionDialog(BuildContext context, FamilyMember member) {
    showDialog(
        context: context,
        builder: (c) => TransactionDialog(initialMemberId: member.id));
  }

  void _showDebtDialog(BuildContext context, FamilyMember member) {
    showDialog(
        context: context,
        builder: (c) => DebtDialog(initialMemberId: member.id));
  }

  void _showAllowanceDialog(BuildContext context, FamilyMember member) {
    showDialog(
        context: context,
        builder: (c) => AllowanceDialog(initialMemberId: member.id));
  }
}
