import 'package:dio/dio.dart';

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});

  factory ServerException.fromDio(DioException error) {
    String message = 'Network communication failed';
    int? code = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please check your network connection.';
        break;
      case DioExceptionType.badResponse:
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic>) {
          message = responseData['message'] as String? ??
              responseData['error'] as String? ??
              'Server returned error: ${error.response?.statusCode}';
        } else if (responseData is String && responseData.isNotEmpty) {
          message = responseData;
        } else {
          message = 'Server error (${error.response?.statusCode})';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Failed to connect to the server. Please verify your internet connection.';
        break;
      case DioExceptionType.badCertificate:
        message = 'Untrusted server certificate encountered.';
        break;
      case DioExceptionType.unknown:
      default:
        message = error.message ?? 'An unexpected network error occurred.';
        break;
    }

    return ServerException(message: message, statusCode: code);
  }

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  AuthException({required this.message, this.statusCode});

  @override
  String toString() => 'AuthException: $message (code: $statusCode)';
}
