import 'package:equatable/equatable.dart';

/// User entity - Business logic object
/// Entities should be framework-independent and contain only business logic
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, email, createdAt];

  @override
  bool get stringify => true;
}
