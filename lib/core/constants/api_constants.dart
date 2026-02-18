/// API related constants
class ApiConstants {
  // Prevent instantiation
  ApiConstants._();

  // Base URLs
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
}
