import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member.dart';
import 'database_provider.dart';

final familyMembersProvider =
    AsyncNotifierProvider<FamilyMembersNotifier, List<FamilyMember>>(() {
      return FamilyMembersNotifier();
    });

final selectedMemberProvider =
    NotifierProvider<SelectedMemberNotifier, String?>(() {
      return SelectedMemberNotifier();
    });

class SelectedMemberNotifier extends Notifier<String?> {
  @override
  String? build() {
    final members = ref.watch(familyMembersProvider).asData?.value;
    if (members != null && members.isNotEmpty) {
      return members.first.id;
    }
    return null;
  }

  void setSelected(String? memberId) {
    state = memberId;
  }
}

class FamilyMembersNotifier extends AsyncNotifier<List<FamilyMember>> {
  @override
  Future<List<FamilyMember>> build() async {
    return loadMembers();
  }

  Future<List<FamilyMember>> loadMembers() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('family_members', orderBy: 'created_at ASC');
      var members = maps.map((e) => FamilyMember.fromMap(e)).toList();
      
      if (members.isEmpty) {
          // Auto-create default member
          final defaultMember = FamilyMember(
            id: const Uuid().v4(),
            name: 'Me',
            createdAt: DateTime.now(),
            resetDay: 1,
          );
          await db.insert('family_members', defaultMember.toMap());
          members = [defaultMember];
      }

      state = AsyncValue.data(members);
      return members;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addMember(String name, {int resetDay = 1}) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final newMember = FamilyMember(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now(),
        resetDay: resetDay,
      );
      await db.insert('family_members', newMember.toMap());
      // Reload to ensure sync
      await loadMembers();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteMember(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
      await loadMembers();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateMember(FamilyMember member) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.update(
        'family_members',
        member.toMap(),
        where: 'id = ?',
        whereArgs: [member.id],
      );
      await loadMembers();
    } catch (e) {
      // Handle error
    }
  }
}
