import 'package:dio/dio.dart';

import '../config/constants.dart';

class ClimaException implements Exception {
  final String message;
  ClimaException(this.message);

  @override
  String toString() => message;
}

/// Clima de una coordenada y fecha, ya traducido al catálogo local:
/// Soleado, Lluvioso, Nublado, Ventoso, Templado o Nevado.
class ClimaInfo {
  final String condicion;
  final String descripcion;
  final double temperaturaC;
  final double vientoMs;
  final double humedad;
  final DateTime fecha;

  const ClimaInfo({
    required this.condicion,
    required this.descripcion,
    required this.temperaturaC,
    required this.vientoMs,
    required this.humedad,
    required this.fecha,
  });

  /// Convierte una entrada de OpenWeatherMap a [ClimaInfo].
  factory ClimaInfo.fromMap(Map<String, dynamic> data) {
    final clima = (data['weather'] as List).first as Map<String, dynamic>;
    final principal = data['main'] as Map;

    return ClimaInfo(
      condicion: _traducirCondicion(
        clima: clima['main'] as String? ?? '',
        temperatura: (principal['temp'] as num).toDouble(),
        viento: ((data['wind'] as Map)['speed'] as num).toDouble(),
      ),
      descripcion: clima['description'] as String? ?? '',
      temperaturaC: (principal['temp'] as num).toDouble(),
      vientoMs: ((data['wind'] as Map)['speed'] as num).toDouble(),
      humedad: (principal['humidity'] as num).toDouble(),
      fecha: DateTime.fromMillisecondsSinceEpoch(
        ((data['dt'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }

  /// Traduce las condiciones de OpenWeatherMap al catálogo de la app.
  static String _traducirCondicion({
    required String clima,
    required double temperatura,
    required double viento,
  }) {
    if (viento >= 10.8) return 'Ventoso'; // ~39 km/h
    switch (clima) {
      case 'Thunderstorm':
      case 'Drizzle':
      case 'Rain':
        return 'Lluvioso';
      case 'Snow':
      case 'Sleet':
        return 'Nevado';
      case 'Clear':
        return 'Soleado';
      case 'Clouds':
      case 'Mist':
      case 'Fog':
      case 'Haze':
      case 'Smoke':
      case 'Dust':
      case 'Sand':
      case 'Ash':
      case 'Squall':
      case 'Tornado':
        return 'Nublado';
      default:
        return (temperatura >= 12 && temperatura <= 26)
            ? 'Templado'
            : 'Nublado';
    }
  }
}

/// Consulta el pronóstico de OpenWeatherMap directamente desde el teléfono.
/// Se usa el mismo endpoint para hoy y para días futuros (pronóstico a 5 días).
class ClimaService {
  ClimaService._();
  static final ClimaService instance = ClimaService._();

  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Clima más cercano a la fecha/hora indicada.
  Future<ClimaInfo> obtenerClima({
    required double latitud,
    required double longitud,
    required DateTime fecha,
  }) async {
    final puntos = await _consultarPronostico(latitud, longitud);
    if (puntos.isEmpty) {
      throw ClimaException('El pronóstico no tiene datos para esa fecha.');
    }
    return _masCercano(puntos, fecha);
  }

  /// Puntos del pronóstico del día indicado (cada 3 horas), para la gráfica.
  Future<List<ClimaInfo>> obtenerPronosticoDia({
    required double latitud,
    required double longitud,
    required DateTime fecha,
  }) async {
    final puntos = await _consultarPronostico(latitud, longitud);
    return puntos
        .where((p) => _esMismoDia(p.fecha, fecha))
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  Future<List<ClimaInfo>> _consultarPronostico(
    double latitud,
    double longitud,
  ) async {
    if (Constants.weatherApiKey.isEmpty) {
      throw ClimaException('Falta configurar WEATHER_API_KEY en el archivo .env');
    }

    try {
      final res = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'lat': latitud,
          'lon': longitud,
          'appid': Constants.weatherApiKey,
          'units': 'metric',
          'lang': 'es',
        },
      );
      final data = res.data as Map<String, dynamic>;
      final lista = data['list'] as List? ?? [];
      return lista
          .cast<Map<String, dynamic>>()
          .map(ClimaInfo.fromMap)
          .toList();
    } on DioException catch (e) {
      throw ClimaException(_mensajeError(e));
    }
  }

  ClimaInfo _masCercano(List<ClimaInfo> puntos, DateTime fecha) {
    var mejor = puntos.first;
    var menorDiferencia = mejor.fecha.difference(fecha).abs();
    for (final punto in puntos.skip(1)) {
      final diferencia = punto.fecha.difference(fecha).abs();
      if (diferencia < menorDiferencia) {
        menorDiferencia = diferencia;
        mejor = punto;
      }
    }
    return mejor;
  }

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _mensajeError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'] as String;
    }
    return 'No se pudo consultar el clima. Revisa tu conexión.';
  }
}
