import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/ubicacion.dart';

/// Tarjeta de ubicación para el listado (estilo Planazo).
class UbicacionCard extends StatelessWidget {
  const UbicacionCard({
    super.key,
    required this.ubicacion,
    required this.onEditar,
    required this.onEliminar,
  });

  final Ubicacion ubicacion;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: PlanazoColors.secondaryContainer,
                child: Icon(
                  Icons.location_on,
                  color: PlanazoColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ubicacion.nombre,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ubicacion.direccion != null &&
                        ubicacion.direccion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        ubicacion.direccion!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: PlanazoColors.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${ubicacion.latitud.toStringAsFixed(4)}, '
                      '${ubicacion.longitud.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: PlanazoColors.outline,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                color: PlanazoColors.error,
                onPressed: onEliminar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
