import 'package:dio/dio.dart';

import '../config/constants.dart';

/// Consultas a Google Maps API: Places (autocompletar) y Geocoding (inverso).
/// Se llama directo desde la app, nunca desde el backend.
/// Si `Constants.googleMapsApiKey` está vacía, responde con datos simulados
/// para no bloquear el desarrollo sin clave.
class MapsService {
  MapsService._();
  static final MapsService instance = MapsService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  bool get _usarMock => Constants.googleMapsApiKey.isEmpty;

  /// Sugerencias de direcciones (Google Places Autocomplete).
  Future<List<String>> autocompletar(String consulta) async {
    if (consulta.trim().length < 3) return [];
    if (_usarMock) {
      return [
        '$consulta (calle simulada)',
        '$consulta (zona centro simulada)',
      ];
    }
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': consulta.trim(),
          'key': Constants.googleMapsApiKey,
        },
      );
      final data = res.data as Map<String, dynamic>;
      if (data['status'] != 'OK') return [];
      final predicciones = data['predictions'] as List;
      return predicciones
          .map((p) => (p as Map<String, dynamic>)['description'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Dirección aproximada a partir de coordenadas (Google Geocoding inverso).
  Future<String?> geocodificarInverso(double latitud, double longitud) async {
    if (_usarMock) {
      return 'Dirección simulada (${latitud.toStringAsFixed(4)}, '
          '${longitud.toStringAsFixed(4)})';
    }
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$latitud,$longitud',
          'key': Constants.googleMapsApiKey,
        },
      );
      final data = res.data as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final results = data['results'] as List;
      if (results.isEmpty) return null;
      return (results.first as Map<String, dynamic>)['formatted_address']
          as String?;
    } catch (_) {
      return null;
    }
  }
}
