import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/constants.dart';

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
  )..interceptors.addAll([_JwtInterceptor(), _UnauthorizedInterceptor()]);

  static Future<void> guardarToken(String token) =>
      _storage.write(key: Constants.storageKeyJwt, value: token);

  static Future<String?> leerToken() =>
      _storage.read(key: Constants.storageKeyJwt);

  static Future<void> limpiarToken() =>
      _storage.delete(key: Constants.storageKeyJwt);

  static Future<void> guardarRequiereCambio(bool requiere) => requiere
      ? _storage.write(key: Constants.storageKeyCambioContrasena, value: 'true')
      : _storage.delete(key: Constants.storageKeyCambioContrasena);

  static Future<bool> leerRequiereCambio() async =>
      await _storage.read(key: Constants.storageKeyCambioContrasena) == 'true';

  static Future<void> limpiarSesion() async {
    await _storage.delete(key: Constants.storageKeyJwt);
    await _storage.delete(key: Constants.storageKeyCambioContrasena);
  }

  static String mensajeErrorDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detalles = data['detalles'];
      if (detalles is List && detalles.isNotEmpty) {
        final primero = detalles.first;
        if (primero is Map && primero['mensaje'] != null) {
          return primero['mensaje'] as String;
        }
      }
      if (data['error'] != null) return data['error'] as String;
      if (data['mensaje'] != null) return data['mensaje'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'El servidor no responde. Intenta de nuevo.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor.';
    }
    return 'Error de conexión con el servidor.';
  }
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
      await ApiService.limpiarSesion();
    }
    handler.next(err);
  }
}
