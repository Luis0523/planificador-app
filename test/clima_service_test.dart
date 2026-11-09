import 'package:flutter_test/flutter_test.dart';

import 'package:planificador_actividades/services/clima_service.dart';

Map<String, dynamic> _respuesta({
  required String main,
  String descripcion = '',
  double temp = 20,
  double viento = 3,
  int dt = 0,
}) => {
  'weather': [
    {'main': main, 'description': descripcion},
  ],
  'main': {'temp': temp, 'humidity': 50},
  'wind': {'speed': viento},
  'dt': dt,
};

void main() {
  group('ClimaInfo.fromMap mapea al catálogo de condiciones', () {
    test('Rain -> Lluvioso', () {
      final c = ClimaInfo.fromMap(_respuesta(main: 'Rain'));
      expect(c.condicion, 'Lluvioso');
    });

    test('Drizzle -> Lluvioso', () {
      final c = ClimaInfo.fromMap(_respuesta(main: 'Drizzle'));
      expect(c.condicion, 'Lluvioso');
    });

    test('Thunderstorm -> Lluvioso', () {
      final c = ClimaInfo.fromMap(_respuesta(main: 'Thunderstorm'));
      expect(c.condicion, 'Lluvioso');
    });

    test('Snow -> Nevado', () {
      final c = ClimaInfo.fromMap(_respuesta(main: 'Snow'));
      expect(c.condicion, 'Nevado');
    });

    test('Clear -> Soleado', () {
      final c = ClimaInfo.fromMap(_respuesta(main: 'Clear'));
      expect(c.condicion, 'Soleado');
    });

    test('Clouds -> Nublado', () {
      final c = ClimaInfo.fromMap(_respuesta(main: 'Clouds'));
      expect(c.condicion, 'Nublado');
    });

    test('viento fuerte -> Ventoso (aunque sea Rain)', () {
      final c = ClimaInfo.fromMap(
        _respuesta(main: 'Rain', viento: 15, temp: 18),
      );
      expect(c.condicion, 'Ventoso');
    });

    test('condición desconocida con temperatura moderada -> Templado', () {
      final c = ClimaInfo.fromMap(_respuesta(main: 'Other', temp: 20));
      expect(c.condicion, 'Templado');
    });

    test('conserva temperatura, viento, humedad y fecha', () {
      final c = ClimaInfo.fromMap(
        _respuesta(main: 'Clear', temp: 25.5, viento: 4.2, dt: 1700000000),
      );
      expect(c.temperaturaC, 25.5);
      expect(c.vientoMs, 4.2);
      expect(c.humedad, 50);
      expect(c.fecha.isAfter(DateTime(2020)), isTrue);
    });
  });

  group('ClimaService sin API key', () {
    test('lanza un error claro en vez de inventar datos', () async {
      expect(
        () => ClimaService.instance.obtenerClima(
          latitud: 19.4326,
          longitud: -99.1332,
          fecha: DateTime.now(),
        ),
        throwsA(isA<ClimaException>()),
      );
    });
  });
}
