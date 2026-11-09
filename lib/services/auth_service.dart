import 'package:dio/dio.dart';

import '../config/constants.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'mock_backend.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class LoginResult {
  final String token;
  final Usuario usuario;
  final bool requiereCambioContrasena;

  LoginResult({
    required this.token,
    required this.usuario,
    required this.requiereCambioContrasena,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiService _api = ApiService.instance;
  bool get _usarMock => Constants.useMockBackend;

  Future<LoginResult> login(String correo, String contrasena) async {
    if (_usarMock) return _mockLogin(correo, contrasena);

    try {
      final res = await _api.dio.post(
        Constants.authLogin,
        data: {'correo': correo, 'contrasena': contrasena},
      );
      final body = res.data as Map<String, dynamic>;
      return LoginResult(
        token: body['token'] as String,
        usuario: Usuario.fromMap(body['usuario'] as Map<String, dynamic>),
        requiereCambioContrasena: body['requiereCambioContrasena'] as bool,
      );
    } on DioException catch (e) {
      throw AuthException(ApiService.mensajeErrorDio(e));
    }
  }

  Future<void> register({
    required String nombreCompleto,
    required String nombreUsuario,
    required String correo,
    required String telefono,
    required String contrasena,
  }) async {
    if (_usarMock) {
      _mockRegister(
        nombreCompleto: nombreCompleto,
        nombreUsuario: nombreUsuario,
        correo: correo,
        telefono: telefono,
        contrasena: contrasena,
      );
      return;
    }

    try {
      await _api.dio.post(
        Constants.authRegister,
        data: {
          'nombreCompleto': nombreCompleto,
          'nombreUsuario': nombreUsuario,
          'correo': correo,
          'telefono': telefono,
          'contrasena': contrasena,
        },
      );
    } on DioException catch (e) {
      throw AuthException(ApiService.mensajeErrorDio(e));
    }
  }

  Future<void> forgotPassword(String correo) async {
    if (_usarMock) {
      if (correo.trim().isEmpty) {
        throw AuthException('El correo es obligatorio');
      }
      return;
    }

    try {
      await _api.dio.post(
        Constants.authForgotPassword,
        data: {'correo': correo},
      );
    } on DioException catch (e) {
      throw AuthException(ApiService.mensajeErrorDio(e));
    }
  }

  Future<void> changePassword(
    String nuevaContrasena,
    String confirmarContrasena,
  ) async {
    if (_usarMock) {
      if (nuevaContrasena.length < 8) {
        throw AuthException('La contraseña debe tener al menos 8 caracteres');
      }
      return;
    }

    try {
      await _api.dio.post(
        Constants.authChangePassword,
        data: {
          'nuevaContrasena': nuevaContrasena,
          'confirmarContrasena': confirmarContrasena,
        },
      );
    } on DioException catch (e) {
      throw AuthException(ApiService.mensajeErrorDio(e));
    }
  }

  LoginResult _mockLogin(String correo, String contrasena) {
    final backend = MockBackend.instance;
    final usuario = backend.buscarPorCorreo(correo);
    if (usuario == null) {
      throw AuthException('Credenciales incorrectas');
    }

    final requiere = contrasena == 'temporal123';
    if (contrasena != usuario['contrasena'] && !requiere) {
      throw AuthException('Credenciales incorrectas');
    }
    backend.setUsuarioActualId(usuario['id']!);

    return LoginResult(
      token: 'mock.jwt.${DateTime.now().millisecondsSinceEpoch}',
      usuario: Usuario(
        id: usuario['id']!,
        nombreUsuario: usuario['nombreUsuario']!,
        nombreCompleto: usuario['nombreCompleto']!,
        correo: usuario['correo']!,
        telefono: usuario['telefono']!,
        requiereCambioContrasena: requiere,
      ),
      requiereCambioContrasena: requiere,
    );
  }

  void _mockRegister({
    required String nombreCompleto,
    required String nombreUsuario,
    required String correo,
    required String telefono,
    required String contrasena,
  }) {
    final backend = MockBackend.instance;
    if (backend.buscarPorCorreo(correo) != null ||
        backend.buscarPorNombreUsuario(nombreUsuario) != null) {
      throw AuthException(
        'El correo o el nombre de usuario ya están registrados',
      );
    }
    backend.registrar(
      nombreCompleto: nombreCompleto,
      nombreUsuario: nombreUsuario,
      correo: correo,
      telefono: telefono,
      contrasena: contrasena,
    );
  }
}
