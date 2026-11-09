import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/actividad.dart';
import '../models/condicion_climatica.dart';
import '../models/ubicacion.dart';
import '../utils/date_helpers.dart';
import 'mini_mapa.dart';

class ActividadCard extends StatelessWidget {
  const ActividadCard({
    super.key,
    required this.actividad,
    required this.condiciones,
    required this.onEditar,
    required this.onEliminar,
    this.ubicacion,
  });

  final Actividad actividad;
  final List<CondicionClimatica> condiciones;
  final Ubicacion? ubicacion;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final esAireLibre = actividad.tipoActividad == 'aire_libre';
    final fecha = DateTime.parse(actividad.fecha);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: esAireLibre
                        ? PlanazoColors.primaryContainer
                        : PlanazoColors.surfaceContainerHigh,
                    child: Icon(
                      esAireLibre ? Icons.directions_run : Icons.meeting_room,
                      color: esAireLibre
                          ? PlanazoColors.onPrimaryContainer
                          : PlanazoColors.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actividad.descripcion,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatearFechaLegible(fecha)} · '
                          '${actividad.horaInicio}–${actividad.horaFin}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: PlanazoColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Etiqueta(
                              texto: esAireLibre ? 'Aire libre' : 'Interior',
                              color: esAireLibre
                                  ? PlanazoColors.tertiaryContainer
                                  : PlanazoColors.surfaceContainerHigh,
                              colorTexto: esAireLibre
                                  ? PlanazoColors.onTertiaryContainer
                                  : PlanazoColors.onSurfaceVariant,
                            ),
                            for (final condicion in condiciones)
                              _Etiqueta(
                                texto: condicion.nombre,
                                color: PlanazoColors.secondaryContainer,
                                colorTexto: PlanazoColors.onSecondaryContainer,
                              ),
                          ],
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
              if (ubicacion != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    MiniMapa(
                      latitud: ubicacion!.latitud,
                      longitud: ubicacion!.longitud,
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PlanazoColors.onPrimary.withValues(
                            alpha: 0.85,
                          ),
                          borderRadius: BorderRadius.circular(
                            PlanazoColors.radiusSm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: PlanazoColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ubicacion!.nombre,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.color,
    required this.colorTexto,
  });

  final String texto;
  final Color color;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusSm),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colorTexto, fontWeight: FontWeight.w600),
      ),
    );
  }
}
