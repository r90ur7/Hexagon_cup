import 'package:admissao_app/core/error/exceptions.dart';
import 'package:admissao_app/core/error/failures.dart';
import 'package:admissao_app/core/network/network_info.dart';
import 'package:admissao_app/features/user/data/datasources/user_local_datasource.dart';
import 'package:admissao_app/features/user/data/datasources/user_remote_datasource.dart';
import 'package:admissao_app/features/user/data/models/user_model.dart';
import 'package:admissao_app/features/user/domain/entities/user.dart';
import 'package:admissao_app/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

/// Implementation of UserRepository
/// Coordinates between remote and local data sources
/// Implements the Repository Pattern
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, User>> getUser(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.getUser(userId);
        await localDataSource.cacheUser(remoteUser);
        return Right(remoteUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      }
    } else {
      try {
        final localUser = await localDataSource.getCachedUser(userId);
        if (localUser != null) {
          return Right(localUser);
        } else {
          return const Left(CacheFailure(message: 'No cached data available'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, code: e.code));
      }
    }
  }

  @override
  Future<Either<Failure, List<User>>> getUsers() async {
    if (await networkInfo.isConnected) {
      try {
        final users = await remoteDataSource.getUsers();
        return Right(users);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> createUser(User user) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = UserModel.fromEntity(user);
        final createdUser = await remoteDataSource.createUser(userModel);
        await localDataSource.cacheUser(createdUser);
        return Right(createdUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = UserModel.fromEntity(user);
        final updatedUser = await remoteDataSource.updateUser(userModel);
        await localDataSource.cacheUser(updatedUser);
        return Right(updatedUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteUser(userId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
