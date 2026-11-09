import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  Constants._();

  static String get apiBaseUrl {
    final url = _env('API_BASE_URL');
    return url.isEmpty ? 'http://localhost:3000' : url;
  }

  static bool get useMockBackend {
    final flag = _env('USE_MOCK_BACKEND').toLowerCase();
    return flag.isEmpty ? true : flag == 'true';
  }

  static String get googleMapsApiKey => _env('GOOGLE_MAPS_API_KEY');
  static String get weatherApiKey => _env('WEATHER_API_KEY');

  static String _env(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authChangePassword = '/api/auth/change-password';
  static const String usersMe = '/api/users/me';

  static const String dbName = 'planificador.db';
  static const int dbVersion = 2;

  static const String tableUbicaciones = 'ubicaciones';
  static const String tableActividades = 'actividades';
  static const String tableHistorial = 'historial_actividades';
  static const String tableCondiciones = 'condiciones_climaticas';
  static const String tableActividadCondicion = 'actividad_condicion';

  static const String estadoPendiente = 'pendiente';
  static const String estadoFinalizada = 'finalizada';
  static const String estadoReagendada = 'reagendada';

  static const String tipoAireLibre = 'aire_libre';
  static const String tipoInterior = 'interior';

  static const String storageKeyJwt = 'jwt_token';
  static const String storageKeyCambioContrasena = 'requiere_cambio_contrasena';
}
