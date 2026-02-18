import 'package:admissao_app/core/error/failures.dart';
import 'package:admissao_app/features/user/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

/// User Repository interface (Repository Pattern)
/// This defines the contract that the data layer must implement
/// Following Dependency Inversion Principle - Domain doesn't depend on Data layer
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String userId);
  Future<Either<Failure, List<User>>> getUsers();
  Future<Either<Failure, User>> createUser(User user);
  Future<Either<Failure, User>> updateUser(User user);
  Future<Either<Failure, void>> deleteUser(String userId);
}
