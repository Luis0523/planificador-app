import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../providers/actividades_pendientes_provider.dart';
import '../services/probabilidad_service.dart';
import '../utils/date_helpers.dart';
import 'clima_indicator.dart';

/// Tarjeta de una actividad pendiente: datos, clima, probabilidad y acciones.
class ActividadPendienteCard extends StatelessWidget {
  const ActividadPendienteCard({
    super.key,
    required this.item,
    required this.onFinalizar,
    required this.onReagendar,
  });

  final ActividadConClima item;
  final VoidCallback onFinalizar;
  final VoidCallback onReagendar;

  @override
  Widget build(BuildContext context) {
    final actividad = item.actividad;
    final fecha = DateTime.tryParse(actividad.fecha);
    final esAireLibre = actividad.tipoActividad == 'aire_libre';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
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
                const SizedBox(width: 12),
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
                      if (fecha != null)
                        Text(
                          '${formatearFechaLegible(fecha)} · '
                          '${actividad.horaInicio}–${actividad.horaFin}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: PlanazoColors.onSurfaceVariant,
                                  ),
                        ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: PlanazoColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.ubicacion.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: PlanazoColors.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _BadgeProbabilidad(nivel: item.probabilidad),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _filaClima(context),
            if (item.condicionesDeseables.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Text(
                    'Ideal con:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PlanazoColors.onSurfaceVariant,
                        ),
                  ),
                  for (final condicion in item.condicionesDeseables)
                    Chip(
                      label: Text(condicion.nombre),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReagendar,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Reagendar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onFinalizar,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Finalizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaClima(BuildContext context) {
    if (item.clima != null) {
      return ClimaIndicator(clima: item.clima!);
    }
    return Row(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 20,
          color: PlanazoColors.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.errorClima ?? 'Cargando clima...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PlanazoColors.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _BadgeProbabilidad extends StatelessWidget {
  const _BadgeProbabilidad({required this.nivel});

  final ProbabilidadNivel nivel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: nivel.colorFondo,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(nivel.icono, size: 14, color: nivel.color),
          const SizedBox(width: 4),
          Text(
            '${nivel.etiquetaCorta} ${nivel.porcentaje}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: nivel.color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
