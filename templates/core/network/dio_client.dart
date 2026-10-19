import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  final String baseUrl;

  DioClient({
    required this.baseUrl,
    required this.secureStorage,
    Dio? customDio,
  }) : dio = customDio ?? Dio() {
    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio.interceptors.add(_AuthInterceptor(
      dio: dio,
      secureStorage: secureStorage,
      baseUrl: baseUrl,
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }
}

/// QueuedInterceptor guarantees that concurrent 401 requests wait
/// for a single token refresh call rather than firing multiple refreshes.
class _AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  final String baseUrl;

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  _AuthInterceptor({
    required this.dio,
    required this.secureStorage,
    required this.baseUrl,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await secureStorage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await secureStorage.read(key: _refreshTokenKey);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Use an isolated Dio instance to avoid interceptor recursion
          final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
          final response = await refreshDio.post(
            '/auth/refresh-token',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final newAccessToken = response.data['data']?['access_token'] ?? response.data['access_token'];
            final newRefreshToken = response.data['data']?['refresh_token'] ?? response.data['refresh_token'];

            await secureStorage.write(key: _tokenKey, value: newAccessToken as String);
            if (newRefreshToken != null) {
              await secureStorage.write(key: _refreshTokenKey, value: newRefreshToken as String);
            }

            // Retry original request with newly acquired token
            final originalRequest = err.requestOptions;
            originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(originalRequest);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed: wipe expired credentials
          await secureStorage.delete(key: _tokenKey);
          await secureStorage.delete(key: _refreshTokenKey);
        }
      }
    }

    return handler.next(err);
  }
}
