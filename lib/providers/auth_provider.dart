import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum AuthStatus { desconocido, noAutenticado, requiereCambio, autenticado }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  final AuthService _authService = AuthService.instance;

  AuthStatus _status = AuthStatus.desconocido;
  Usuario? _usuario;
  bool _cargando = false;
  String? _error;

  AuthStatus get status => _status;
  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get autenticado => _status == AuthStatus.autenticado;

  /// Al abrir la app: si hay un JWT guardado, la sesión sigue activa.
  Future<void> _init() async {
    final token = await ApiService.leerToken();
    _status =
        (token != null && token.isNotEmpty) ? AuthStatus.autenticado : AuthStatus.noAutenticado;
    notifyListeners();
  }

  Future<bool> login(String correo, String contrasena) => _ejecutar(
        () async {
          final res = await _authService.login(correo, contrasena);
          await ApiService.guardarToken(res.token);
          _usuario = res.usuario;
          _status = res.requiereCambioContrasena
              ? AuthStatus.requiereCambio
              : AuthStatus.autenticado;
        },
      );

  Future<bool> registrar({
    required String nombreCompleto,
    required String nombreUsuario,
    required String correo,
    required String telefono,
    required String contrasena,
  }) =>
      _ejecutar(
        () => _authService.register(
          nombreCompleto: nombreCompleto,
          nombreUsuario: nombreUsuario,
          correo: correo,
          telefono: telefono,
          contrasena: contrasena,
        ),
      );

  Future<bool> recuperarContrasena(String correo) => _ejecutar(
        () => _authService.forgotPassword(correo),
      );

  Future<bool> cambiarContrasena(String nueva, String confirmacion) async {
    if (nueva != confirmacion) {
      _error = 'Las contraseñas no coinciden';
      notifyListeners();
      return false;
    }
    return _ejecutar(
      () async {
        await _authService.changePassword(nueva);
        _status = AuthStatus.autenticado;
      },
    );
  }

  Future<void> logout() async {
    await ApiService.limpiarToken();
    _usuario = null;
    _error = null;
    _status = AuthStatus.noAutenticado;
    notifyListeners();
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Algo salió mal. Intenta de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
