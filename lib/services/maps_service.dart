import 'package:dio/dio.dart';

import '../config/constants.dart';

/// Consulta la API de Google Maps para obtener la dirección de un punto.
/// Se llama directo desde el teléfono, nunca desde el backend.
class MapsService {
  MapsService._();
  static final MapsService instance = MapsService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Dirección aproximada de una coordenada (Geocoding inverso).
  /// Devuelve null si no hay API key o si Google no encuentra la dirección.
  Future<String?> geocodificarInverso(double latitud, double longitud) async {
    if (Constants.googleMapsApiKey.isEmpty) return null;

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

      final resultados = data['results'] as List;
      if (resultados.isEmpty) return null;

      return (resultados.first as Map<String, dynamic>)['formatted_address']
          as String?;
    } catch (_) {
      return null;
    }
  }
}
