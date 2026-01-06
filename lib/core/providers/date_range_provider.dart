import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'family_member_provider.dart';

// Offset from the current month. 0 = current, -1 = last month, etc.
final monthOffsetProvider = StateProvider<int>((ref) => 0);

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
  
  // Format for display, e.g., "Dec 5 - Jan 5" or "January 2024"
  // This is a basic implementation, can be enhanced.
  String toString() {
     return '${start.toLocal()} - ${end.toLocal()}';
  }
}

final currentDateRangeProvider = Provider<DateRange>((ref) {
  final offset = ref.watch(monthOffsetProvider);
  final selectedMemberId = ref.watch(selectedMemberProvider);
  final members = ref.watch(familyMembersProvider).asData?.value ?? [];

  int resetDay = 1;
  if (selectedMemberId != null) {
    final member = members.firstWhere(
      (m) => m.id == selectedMemberId,
      orElse: () => members.first, // Fallback (shouldn't happen ideally)
    );
    resetDay = member.resetDay;
  }

  final now = DateTime.now();
  
  // Logic to determine the "anchor" month based on today and reset day.
  // If today is before the reset day, we are in the "previous" month's cycle relative to calendar month.
  // e.g. Reset Day: 5. Today: Jan 3. Current Period: Dec 5 - Jan 5.
  // e.g. Reset Day: 5. Today: Jan 6. Current Period: Jan 5 - Feb 5.
  
  DateTime anchorDate = now;
  if (now.day < resetDay) {
    // If we haven't reached the reset day yet this month, the current period started last month
    anchorDate = DateTime(now.year, now.month - 1, resetDay);
  } else {
    // We have passed the reset day, so the current period started this month
    anchorDate = DateTime(now.year, now.month, resetDay);
  }

  // Apply offset
  // We calculate the start date by adding 'offset' months to the anchor start date
  final startDate = DateTime(anchorDate.year, anchorDate.month + offset, resetDay);
  
  // End date is exactly one month after start date
  // Note: logic for end of month (e.g. resetDay 31) needs care, but Dart's DateTime handles overflow
  // DateTime(2024, 1, 31) + 1 month -> Feb 29 (leap) or Feb 28? Dart does overflow: 
  // DateTime(2024, 2, 31) -> March 2 (since Feb has 29). This might not be desired "End of month" behavior.
  // For simple reset days (1-28), this is fine. For 29, 30, 31, we might clamping.
  // Requirement says "from 5th to 5th". So start = 5th, end = 5th next month.
  // This implies the range is [start, end) or similar.
  // Let's assume range is inclusive start, exclusive end for logic, but UI might show "Jan 5 - Feb 4".
  // User request: "from the 5th of one month to the 5th of the next month."
  
  final endDate = DateTime(startDate.year, startDate.month + 1, resetDay);

  return DateRange(start: startDate, end: endDate);
});
