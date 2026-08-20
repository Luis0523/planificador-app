import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  Constants._();

  // URLs base
  static String get apiBaseUrl {
    final url = _env('API_BASE_URL');
    return url.isEmpty ? 'http://localhost:3000' : url;
  }

  /// TODO: reemplazar por backend real cuando el servidor Node esté desplegado.
  /// Mientras tanto, auth_service.dart responde con datos simulados.
  static const bool useMockBackend = true;

  // API keys
  static String get googleMapsApiKey => _env('GOOGLE_MAPS_API_KEY');
  static String get weatherApiKey => _env('WEATHER_API_KEY');

  /// Lee una variable de entorno sin lanzar si dotenv no se inicializó
  /// (p. ej. en tests, donde no se llama a `dotenv.load`).
  static String _env(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  // Backend: rutas de auth y perfil
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authChangePassword = '/api/auth/change-password';
  static const String usersMe = '/api/users/me';

  // SQLite: nombre y version de la base
  static const String dbName = 'planificador.db';
  static const int dbVersion = 1;

  // SQLite: nombres de tablas
  static const String tableUbicaciones = 'ubicaciones';
  static const String tableActividades = 'actividades';
  static const String tableHistorial = 'historial_actividades';
  static const String tableCondiciones = 'condiciones_climaticas';
  static const String tableActividadCondicion = 'actividad_condicion';

  // Estados de actividad
  static const String estadoPendiente = 'pendiente';
  static const String estadoFinalizada = 'finalizada';
  static const String estadoReagendada = 'reagendada';

  // Tipos de actividad
  static const String tipoAireLibre = 'aire_libre';
  static const String tipoInterior = 'interior';

  // Clave para guardar el JWT en flutter_secure_storage
  static const String storageKeyJwt = 'jwt_token';
}
