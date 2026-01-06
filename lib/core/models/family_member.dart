import 'package:equatable/equatable.dart';

class FamilyMember extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final int resetDay;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.createdAt,
    this.resetDay = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'reset_day': resetDay,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      resetDay: map['reset_day'] ?? 1,
    );
  }

  FamilyMember copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? resetDay,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      resetDay: resetDay ?? this.resetDay,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, resetDay];
}
