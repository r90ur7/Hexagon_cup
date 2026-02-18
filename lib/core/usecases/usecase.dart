import 'package:admissao_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Base UseCase interface following Clean Architecture principles
///
/// Type: The type of data returned by the use case
/// Params: The parameters required by the use case
///
/// Returns Either<Failure, Type> for error handling
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Used when a UseCase doesn't need parameters
class NoParams {
  const NoParams();
}
