import 'package:dio/dio.dart';

import '../config/constants.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'mock_backend.dart';

/// Perfil de usuario: GET/PUT `/api/users/me`.
/// Mientras `Constants.useMockBackend` sea true, responde con datos simulados.
class UsuarioService {
  UsuarioService._();
  static final UsuarioService instance = UsuarioService._();

  final ApiService _api = ApiService.instance;
  bool get _usarMock => Constants.useMockBackend;

  Future<Usuario> obtenerPerfil() async {
    if (_usarMock) return MockBackend.instance.perfilActual();

    try {
      final res = await _api.dio.get(Constants.usersMe);
      return Usuario.fromMap(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_mensajeDio(e));
    }
  }

  /// Guarda los cambios de perfil. Nunca envía `nombreUsuario` ni contraseña.
  Future<Usuario> actualizarPerfil({
    required String nombreCompleto,
    required String telefono,
  }) async {
    if (_usarMock) {
      return MockBackend.instance
          .actualizarPerfil(nombreCompleto: nombreCompleto, telefono: telefono);
    }

    try {
      final res = await _api.dio.put(
        Constants.usersMe,
        data: {'nombreCompleto': nombreCompleto, 'telefono': telefono},
      );
      return Usuario.fromMap(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_mensajeDio(e));
    }
  }

  String _mensajeDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['mensaje'] != null) {
      return data['mensaje'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'El servidor no responde. Intenta de nuevo.';
    }
    return 'Error de conexión con el servidor.';
  }
}
