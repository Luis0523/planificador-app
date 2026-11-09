import 'package:flutter/material.dart';

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

class ProbabilidadService {
  ProbabilidadService._();
  static final ProbabilidadService instance = ProbabilidadService._();

  static const _condicionesAdversas = {'Lluvioso', 'Nevado', 'Ventoso'};

  ProbabilidadNivel calcular({
    required String tipoActividad,
    required List<String> condicionesDeseables,
    required String condicionReal,
  }) {
    if (condicionesDeseables.contains(condicionReal)) {
      return ProbabilidadNivel.alta;
    }
    final esAireLibre = tipoActividad == 'aire_libre';
    if (!esAireLibre) {
      return ProbabilidadNivel.media;
    }
    if (_condicionesAdversas.contains(condicionReal)) {
      return ProbabilidadNivel.baja;
    }
    return ProbabilidadNivel.media;
  }
}
