import 'package:admissao_app/core/error/failures.dart';
import 'package:admissao_app/core/usecases/usecase.dart';
import 'package:admissao_app/features/user/domain/entities/user.dart';
import 'package:admissao_app/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

/// Use Case for getting a user
/// Each use case should do ONE thing only (Single Responsibility Principle)
class GetUser implements UseCase<User, GetUserParams> {
  GetUser(this.repository);
  final UserRepository repository;

  @override
  Future<Either<Failure, User>> call(GetUserParams params) async {
    return repository.getUser(params.userId);
  }
}

/// Parameters for GetUser use case
class GetUserParams extends Equatable {
  const GetUserParams({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}
