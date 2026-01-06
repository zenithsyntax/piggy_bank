import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/family_member_provider.dart';
import '../../../core/models/family_member.dart';
import '../widgets/member_settings_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class FamilyMembersPage extends ConsumerWidget {
  const FamilyMembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Family Members'),
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
            child: membersAsync.when(
              data: (members) => SettingsSection(
                children: [
                  ...members.map((member) => SettingsTile(
                        icon: const Icon(Icons.person),
                        iconColor: Colors.blueAccent,
                        title: member.name,
                        subtitle: 'Resets on day ${member.resetDay}',
                        onTap: () => _showEditMemberDialog(context, member),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (member.name != 'Me')
                              IconButton(
                                icon: Icon(Icons.delete, 
                                  color: Colors.white.withOpacity(0.3), 
                                  size: 20
                                ),
                                onPressed: () => _confirmDelete(
                                  context, 
                                  'Delete ${member.name}?', 
                                  () => ref.read(familyMembersProvider.notifier).deleteMember(member.id),
                                ),
                              ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                      )),
                  SettingsTile(
                    icon: const Icon(Icons.add),
                    iconColor: Colors.greenAccent,
                    title: 'Add Family Member',
                    onTap: () => _showAddMemberDialog(context, ref),
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
