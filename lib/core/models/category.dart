import 'package:equatable/equatable.dart';

enum CategoryType { expense, income }

class TransactionCategory extends Equatable {
  final String id;
  final String name;
  final CategoryType type;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name, // 'expense' or 'income'
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'],
      name: map['name'],
      type: CategoryType.values.byName(map['type']),
    );
  }

  @override
  List<Object?> get props => [id, name, type];
}
