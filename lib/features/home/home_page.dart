import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import '../../../core/providers/family_member_provider.dart';
import '../../../core/models/family_member.dart';
import 'widgets/member_dashboard.dart';
import '../settings/settings_page.dart';
import '../transactions/add_transaction_page.dart';
import '../debts/add_debt_page.dart';
import '../allowances/give_allowance_page.dart';
import '../../core/providers/date_range_provider.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Piggy Bank')),
            body: const Center(child: Text('No family members found. Go to Settings to add one.')),
          );
        }

        // Initialize or update tab controller
        if (_tabController == null || _tabController!.length != members.length) {
            _tabController?.dispose();
            _tabController = TabController(length: members.length, vsync: this);
            _tabController!.addListener(_handleTabSelection);
             // Sync selected member provider
             Future.microtask(() {
                 if(members.isNotEmpty) {
                    ref.read(selectedMemberProvider.notifier).state = members[_tabController!.index].id;
                 }
             });
        }
        
          final dateRange = ref.watch(currentDateRangeProvider);
          final monthOffset = ref.watch(monthOffsetProvider);

          return Scaffold(
          appBar: AppBar(
            title: const Text('Piggy Bank'),
            actions: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => ref.read(monthOffsetProvider.notifier).state--,
                ),
                Text(
                    '${DateFormat('MMM d').format(dateRange.start)} - ${DateFormat('MMM d').format(dateRange.end)}',
                    style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => ref.read(monthOffsetProvider.notifier).state++,
                ),
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
            bottom: members.length > 1 
                ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: members.map((m) => Tab(text: m.name)).toList(),
                  )
                : null,
          ),
          body: members.length > 1 
              ? TabBarView(
                  controller: _tabController,
                  children: members.map((m) => MemberDashboard(memberId: m.id)).toList(),
                )
              : MemberDashboard(memberId: members.first.id),
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
                   _showTransactionDialog(context, members[_tabController!.index]);
                },
              ),
              FloatingActionButton(
                heroTag: null,
                tooltip: 'Debt/Credit',
                child: const Icon(Icons.handshake),
                onPressed: () {
                    _showDebtDialog(context, members[_tabController!.index]);
                },
              ),
              FloatingActionButton(
                heroTag: null,
                tooltip: 'Allowance',
                child: const Icon(Icons.card_giftcard),
                onPressed: () {
                    _showAllowanceDialog(context, members[_tabController!.index]);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
  
  void _handleTabSelection() {
      if (_tabController!.indexIsChanging) {
          final members = ref.read(familyMembersProvider).asData?.value;
          if (members != null && members.isNotEmpty) {
               ref.read(selectedMemberProvider.notifier).state = members[_tabController!.index].id;
          }
      }
  }

  void _showTransactionDialog(BuildContext context, FamilyMember member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(initialMemberId: member.id),
      ),
    );
  }
  
  void _showDebtDialog(BuildContext context, FamilyMember member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtPage(initialMemberId: member.id),
      ),
    );
  }
  
   void _showAllowanceDialog(BuildContext context, FamilyMember member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiveAllowancePage(initialMemberId: member.id),
      ),
    );
  }
}
