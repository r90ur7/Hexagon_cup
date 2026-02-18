import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Following the Failure pattern from Clean Architecture
abstract class Failure extends Equatable {
  const Failure({required this.message, this.code});
  final String message;
  final int? code;

  @override
  List<Object?> get props => [message, code];
}

/// Failure when there's a server error
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Failure when there's a cache error
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Failure when there's a network error
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Failure when there's a validation error
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Failure when authentication fails
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.code});
}

/// Failure when authorization fails
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({required super.message, super.code});
}
