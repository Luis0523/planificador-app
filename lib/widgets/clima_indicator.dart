import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/clima_service.dart';

/// Muestra un pronóstico del clima con ícono/color según la condición.
class ClimaIndicator extends StatelessWidget {
  const ClimaIndicator({super.key, required this.clima});

  final ClimaInfo clima;

  static (IconData, Color) datosVisuales(String condicion) {
    switch (condicion) {
      case 'Soleado':
        return (Icons.wb_sunny, const Color(0xFFFFB300));
      case 'Lluvioso':
        return (Icons.water_drop, const Color(0xFF0288D1));
      case 'Nublado':
        return (Icons.cloud, const Color(0xFF90A4AE));
      case 'Ventoso':
        return (Icons.air, const Color(0xFF00897B));
      case 'Templado':
        return (Icons.wb_sunny_outlined, const Color(0xFF7CB342));
      case 'Nevado':
        return (Icons.ac_unit, const Color(0xFF4FC3F7));
      default:
        return (Icons.cloud_outlined, PlanazoColors.outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icono, color) = datosVisuales(clima.condicion);
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.18),
          child: Icon(icono, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${clima.condicion} · ${clima.temperaturaC.round()}°C',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                clima.descripcion,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PlanazoColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
