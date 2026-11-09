import 'package:dio/dio.dart';

import '../config/constants.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'mock_backend.dart';

class UsuarioService {
  UsuarioService._();
  static final UsuarioService instance = UsuarioService._();

  final ApiService _api = ApiService.instance;
  bool get _usarMock => Constants.useMockBackend;

  Future<Usuario> obtenerPerfil() async {
    if (_usarMock) return MockBackend.instance.perfilActual();

    try {
      final res = await _api.dio.get(Constants.usersMe);
      return Usuario.fromMap(_desenvolver(res.data));
    } on DioException catch (e) {
      throw AuthException(ApiService.mensajeErrorDio(e));
    }
  }

  Future<Usuario> actualizarPerfil({
    required String nombreCompleto,
    required String telefono,
  }) async {
    if (_usarMock) {
      return MockBackend.instance.actualizarPerfil(
        nombreCompleto: nombreCompleto,
        telefono: telefono,
      );
    }

    try {
      final res = await _api.dio.put(
        Constants.usersMe,
        data: {'nombreCompleto': nombreCompleto, 'telefono': telefono},
      );
      return Usuario.fromMap(_desenvolver(res.data));
    } on DioException catch (e) {
      throw AuthException(ApiService.mensajeErrorDio(e));
    }
  }

  Map<String, dynamic> _desenvolver(dynamic data) {
    final mapa = data as Map<String, dynamic>;
    if (mapa['usuario'] is Map) return mapa['usuario'] as Map<String, dynamic>;
    return mapa;
  }
}
