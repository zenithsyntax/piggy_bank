import 'package:equatable/equatable.dart';

class FamilyMember extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
