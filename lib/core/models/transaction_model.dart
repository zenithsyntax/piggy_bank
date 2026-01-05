import 'package:equatable/equatable.dart';
import 'category.dart';

class TransactionModel extends Equatable {
  final String id;
  final String memberId;
  final String categoryId;
  final double amount;
  final CategoryType type;
  final DateTime date;
  final String note;

  const TransactionModel({
    required this.id,
    required this.memberId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      memberId: map['member_id'],
      categoryId: map['category_id'],
      amount: map['amount'] as double,
      type: CategoryType.values.byName(map['type']),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, memberId, categoryId, amount, type, date, note];
}
