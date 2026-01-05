import 'package:equatable/equatable.dart';

enum AllowanceStatus { active, completed }

class Allowance extends Equatable {
  final String id;
  final String fromMemberId;
  final String toMemberId;
  final double totalAmount;
  final double remainingAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final AllowanceStatus status;

  const Allowance({
    required this.id,
    required this.fromMemberId,
    required this.toMemberId,
    required this.totalAmount,
    required this.remainingAmount,
    required this.startDate,
    this.endDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_member_id': fromMemberId,
      'to_member_id': toMemberId,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status.name,
    };
  }

  factory Allowance.fromMap(Map<String, dynamic> map) {
    return Allowance(
      id: map['id'],
      fromMemberId: map['from_member_id'],
      toMemberId: map['to_member_id'],
      totalAmount: map['total_amount'] as double,
      remainingAmount: map['remaining_amount'] as double,
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      status: AllowanceStatus.values.byName(map['status']),
    );
  }

  Allowance copyWith({
    String? id,
    String? fromMemberId,
    String? toMemberId,
    double? totalAmount,
    double? remainingAmount,
    DateTime? startDate,
    DateTime? endDate,
    AllowanceStatus? status,
  }) {
    return Allowance(
      id: id ?? this.id,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, fromMemberId, toMemberId, totalAmount, remainingAmount, startDate, endDate, status];
}

class AllowanceExpense extends Equatable {
  final String id;
  final String allowanceId;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String note;

  const AllowanceExpense({
    required this.id,
    required this.allowanceId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'allowance_id': allowanceId,
      'category_id': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory AllowanceExpense.fromMap(Map<String, dynamic> map) {
    return AllowanceExpense(
      id: map['id'],
      allowanceId: map['allowance_id'],
      categoryId: map['category_id'],
      amount: map['amount'] as double,
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, allowanceId, categoryId, amount, date, note];
}
