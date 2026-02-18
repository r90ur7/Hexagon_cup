/// Base exception class for all exceptions in the data layer
class AppException implements Exception {
  const AppException({required this.message, this.code});
  final String message;
  final int? code;

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when server returns an error
class ServerException extends AppException {
  const ServerException({required super.message, super.code});

  @override
  String toString() =>
      'ServerException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when cache operation fails
class CacheException extends AppException {
  const CacheException({required super.message, super.code});

  @override
  String toString() =>
      'CacheException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when there's no network connection
class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});

  @override
  String toString() =>
      'NetworkException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});

  @override
  String toString() =>
      'ValidationException: $message${code != null ? ' (code: $code)' : ''}';
}
