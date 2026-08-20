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

/// Servicio de autenticación: login, registro, recuperación y cambio de contraseña.
///
/// Mientras el backend Node no esté desplegado (`Constants.useMockBackend == true`)
/// responde con datos simulados. La interfaz no cambia: al conectar el backend
/// real basta con poner `useMockBackend = false`.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiService _api = ApiService.instance;
  bool get _usarMock => Constants.useMockBackend;

  // ---- Login ----

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
      throw AuthException(_mensajeDio(e));
    }
  }

  // ---- Registro ----

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
      await _api.dio.post(Constants.authRegister, data: {
        'nombreCompleto': nombreCompleto,
        'nombreUsuario': nombreUsuario,
        'correo': correo,
        'telefono': telefono,
        'contrasena': contrasena,
      });
    } on DioException catch (e) {
      throw AuthException(_mensajeDio(e));
    }
  }

  // ---- Recuperación de contraseña ----

  Future<void> forgotPassword(String correo) async {
    if (_usarMock) {
      if (correo.trim().isEmpty) {
        throw AuthException('El correo es obligatorio');
      }
      return; // TODO: mock: siempre "enviado"
    }

    try {
      await _api.dio.post(Constants.authForgotPassword, data: {'correo': correo});
    } on DioException catch (e) {
      throw AuthException(_mensajeDio(e));
    }
  }

  // ---- Cambio de contraseña (requiere JWT del login con temporal) ----

  Future<void> changePassword(String nuevaContrasena) async {
    if (_usarMock) {
      if (nuevaContrasena.length < 6) {
        throw AuthException('La contraseña debe tener al menos 6 caracteres');
      }
      return; // TODO: mock: siempre exitoso
    }

    try {
      await _api.dio.post(
        Constants.authChangePassword,
        data: {'nuevaContrasena': nuevaContrasena},
      );
    } on DioException catch (e) {
      throw AuthException(_mensajeDio(e));
    }
  }

  // ---- Mock (TODO: reemplazar por backend real) ----

  LoginResult _mockLogin(String correo, String contrasena) {
    final backend = MockBackend.instance;
    final usuario = backend.buscarPorCorreo(correo);
    if (usuario == null) {
      throw AuthException('Credenciales incorrectas');
    }

    // Contraseña temporal simulada: obliga a cambiar la contraseña.
    final requiere = contrasena == 'temporal123';
    if (contrasena != usuario['contrasena'] && !requiere) {
      throw AuthException('Credenciales incorrectas');
    }
    backend.setUsuarioActualId(usuario['id']!);

    return LoginResult(
      token: 'mock.jwt.${DateTime.now().millisecondsSinceEpoch}',
      usuario: Usuario(
        id: int.parse(usuario['id']!),
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
      throw AuthException('El correo o el nombre de usuario ya están registrados');
    }
    backend.registrar(
      nombreCompleto: nombreCompleto,
      nombreUsuario: nombreUsuario,
      correo: correo,
      telefono: telefono,
      contrasena: contrasena,
    );
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
