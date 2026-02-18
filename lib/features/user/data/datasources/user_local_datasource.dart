import 'dart:convert';

import 'package:admissao_app/core/error/exceptions.dart';
import 'package:admissao_app/features/user/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local data source interface
/// Abstraction for local storage operations
abstract class UserLocalDataSource {
  Future<UserModel?> getCachedUser(String userId);
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

/// Implementation of UserLocalDataSource using SharedPreferences
class UserLocalDataSourceImpl implements UserLocalDataSource {
  UserLocalDataSourceImpl({required this.sharedPreferences});
  final SharedPreferences sharedPreferences;

  static const String cachePrefix = 'CACHED_USER_';

  @override
  Future<UserModel?> getCachedUser(String userId) async {
    try {
      final jsonString = sharedPreferences.getString('$cachePrefix$userId');

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserModel.fromJson(json);
      }

      return null;
    } catch (e) {
      throw CacheException(message: 'Failed to get cached user: $e');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonString = jsonEncode(user.toJson());
      await sharedPreferences.setString('$cachePrefix${user.id}', jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to cache user: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final keys = sharedPreferences.getKeys();
      final userKeys = keys.where((key) => key.startsWith(cachePrefix));

      for (final key in userKeys) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: $e');
    }
  }
}
