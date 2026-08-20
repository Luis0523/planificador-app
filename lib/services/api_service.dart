import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/constants.dart';

/// Cliente HTTP configurado para el backend propio.
/// Se encarga de adjuntar el JWT (Authorization: Bearer) a cada request
/// y de limpiar el token si el servidor responde 401.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: Constants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.addAll([
      _JwtInterceptor(),
      _UnauthorizedInterceptor(),
    ]);

  // ---- Token (JWT): siempre en flutter_secure_storage, nunca en SQLite ----

  static Future<void> guardarToken(String token) =>
      _storage.write(key: Constants.storageKeyJwt, value: token);

  static Future<String?> leerToken() =>
      _storage.read(key: Constants.storageKeyJwt);

  static Future<void> limpiarToken() =>
      _storage.delete(key: Constants.storageKeyJwt);
}

class _JwtInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await ApiService.leerToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _UnauthorizedInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await ApiService.limpiarToken();
    }
    handler.next(err);
  }
}
