import 'package:equatable/equatable.dart';

enum DebtType { debit, credit } // debit = I gave, credit = I took
enum DebtStatus { pending, settled }

class Debt extends Equatable {
  final String id;
  final String memberId;
  final String personName;
  final double amount;
  final DebtType type;
  final DebtStatus status;
  final DateTime date;
  final String note;

  const Debt({
    required this.id,
    required this.memberId,
    required this.personName,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'person_name': personName,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      memberId: map['member_id'],
      personName: map['person_name'],
      amount: map['amount'] as double,
      type: DebtType.values.byName(map['type']),
      status: DebtStatus.values.byName(map['status']),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }

    Debt copyWith({
    String? id,
    String? memberId,
    String? personName,
    double? amount,
    DebtType? type,
    DebtStatus? status,
    DateTime? date,
    String? note,
  }) {
    return Debt(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, memberId, personName, amount, type, status, date, note];
}
