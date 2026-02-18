import 'package:admissao_app/core/error/exceptions.dart';
import 'package:admissao_app/features/user/data/models/user_model.dart';
import 'package:dio/dio.dart';

/// Remote data source interface
/// Abstraction for network operations
abstract class UserRemoteDataSource {
  Future<UserModel> getUser(String userId);
  Future<List<UserModel>> getUsers();
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
}

/// Implementation of UserRemoteDataSource using Dio
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({required this.dio});
  final Dio dio;

  @override
  Future<UserModel> getUser(String userId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/users/$userId');

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data!);
      } else {
        throw ServerException(
          message: 'Failed to fetch user',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await dio.get<List<dynamic>>('/users');

      if (response.statusCode == 200 && response.data != null) {
        return response.data!
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch users',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/users',
        data: user.toJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        return UserModel.fromJson(response.data!);
      } else {
        throw ServerException(
          message: 'Failed to create user',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/users/${user.id}',
        data: user.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data!);
      } else {
        throw ServerException(
          message: 'Failed to update user',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      final response = await dio.delete<void>('/users/$userId');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to delete user',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Helper method to handle Dio errors
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Connection timeout');
      case DioExceptionType.badResponse:
        return ServerException(
          message:
              error.response?.data?['message'] as String? ??
              'Server error occurred',
          code: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection');
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request cancelled');
      default:
        return ServerException(
          message: error.message ?? 'Unknown error occurred',
        );
    }
  }
}
