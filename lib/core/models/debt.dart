import 'package:equatable/equatable.dart';

enum DebtType { debit, credit } // debit = I gave, credit = I took
enum DebtStatus { pending, settled }

class Debt extends Equatable {
  final String id;
  final String memberId;
  final String personName;
  final double amount;
  final double remainingAmount;
  final DebtType type;
  final DebtStatus status;
  final DateTime date;
  final String note;
  final DateTime? completedAt;

  const Debt({
    required this.id,
    required this.memberId,
    required this.personName,
    required this.amount,
    required this.remainingAmount,
    required this.type,
    required this.status,
    required this.date,
    this.note = '',
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'person_name': personName,
      'amount': amount,
      'remaining_amount': remainingAmount,
      'type': type.name,
      'status': status.name,
      'date': date.toIso8601String(),
      'note': note,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      memberId: map['member_id'],
      personName: map['person_name'],
      amount: map['amount'] as double,
      remainingAmount: (map['remaining_amount'] as double?) ?? (map['amount'] as double),
      type: DebtType.values.byName(map['type']),
      status: DebtStatus.values.byName(map['status']),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
    );
  }

    Debt copyWith({
    String? id,
    String? memberId,
    String? personName,
    double? amount,
    double? remainingAmount,
    DebtType? type,
    DebtStatus? status,
    DateTime? date,
    String? note,
    DateTime? completedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      date: date ?? this.date,
      note: note ?? this.note,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, memberId, personName, amount, remainingAmount, type, status, date, note, completedAt];
}

class DebtRepayment extends Equatable {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final String note;

  const DebtRepayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DebtRepayment.fromMap(Map<String, dynamic> map) {
    return DebtRepayment(
      id: map['id'],
      debtId: map['debt_id'],
      amount: map['amount'] as double,
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, debtId, amount, date, note];
}
