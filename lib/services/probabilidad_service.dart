import 'package:flutter/material.dart';

/// Nivel de probabilidad de realizar una actividad segun el clima.
enum ProbabilidadNivel {
  alta,
  media,
  baja;

  String get etiqueta => switch (this) {
        alta => 'Alta probabilidad',
        media => 'Probabilidad media',
        baja => 'Baja probabilidad',
      };

  String get etiquetaCorta => switch (this) {
        alta => 'Alta',
        media => 'Media',
        baja => 'Baja',
      };

  /// Valor sencillo para mostrar como porcentaje en la interfaz.
  int get porcentaje => switch (this) {
        alta => 85,
        media => 50,
        baja => 20,
      };

  Color get color => switch (this) {
        alta => const Color(0xFF2E7D32),
        media => const Color(0xFFF57F17),
        baja => const Color(0xFFC62828),
      };

  Color get colorFondo => switch (this) {
        alta => const Color(0xFFE8F5E9),
        media => const Color(0xFFFFF8E1),
        baja => const Color(0xFFFFEBEE),
      };

  IconData get icono => switch (this) {
        alta => Icons.check_circle_outline,
        media => Icons.info_outline,
        baja => Icons.warning_amber_outlined,
      };
}

/// Logica pura de calculo de probabilidad de realizacion de una actividad.
/// Sin red, sin Flutter widgets.
///
/// Reglas:
/// 1. La condicion real coincide con alguna deseable -> Alta.
/// 2. interior + no adversa -> Media (el interior tolera casi todo).
/// 3. aire_libre + condicion adversa (Lluvioso/Nevado/Ventoso) sin desear -> Baja.
/// 4. aire_libre + condicion neutra no deseada -> Media.
class ProbabilidadService {
  ProbabilidadService._();
  static final ProbabilidadService instance = ProbabilidadService._();

  static const _condicionesAdversas = {'Lluvioso', 'Nevado', 'Ventoso'};

  /// Calcula la probabilidad de realizacion.
  ///
  /// [tipoActividad] — 'aire_libre' | 'interior'
  /// [condicionesDeseables] — nombres del catalogo local (ej. ['Soleado', 'Templado'])
  /// [condicionReal] — nombre de la condicion del pronostico (del ClimaService)
  ProbabilidadNivel calcular({
    required String tipoActividad,
    required List<String> condicionesDeseables,
    required String condicionReal,
  }) {
    // Regla 1
    if (condicionesDeseables.contains(condicionReal)) {
      return ProbabilidadNivel.alta;
    }
    final esAireLibre = tipoActividad == 'aire_libre';
    // Regla 2
    if (!esAireLibre) {
      return ProbabilidadNivel.media;
    }
    // Regla 3
    if (_condicionesAdversas.contains(condicionReal)) {
      return ProbabilidadNivel.baja;
    }
    // Regla 4
    return ProbabilidadNivel.media;
  }
}
