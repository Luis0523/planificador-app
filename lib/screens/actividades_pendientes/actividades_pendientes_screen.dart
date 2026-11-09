import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/actividades_pendientes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../services/probabilidad_service.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/actividad_pendiente_card.dart';

/// Pantalla de Actividades Pendientes (Fase 7).
/// Muestra las actividades proximas con clima real, indicador de probabilidad,
/// filtros y acciones de Finalizar / Reagendar.
class ActividadesPendientesScreen extends StatefulWidget {
  const ActividadesPendientesScreen({super.key});

  @override
  State<ActividadesPendientesScreen> createState() =>
      _ActividadesPendientesScreenState();
}

class _ActividadesPendientesScreenState
    extends State<ActividadesPendientesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _refrescar() async {
    final usuario = context.read<AuthProvider>().usuario;
    if (usuario != null) {
      await context.read<ActividadesPendientesProvider>().cargar(usuario.id);
    }
  }

  Future<void> _finalizar(
    BuildContext context,
    ActividadConClima item,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar actividad'),
        content: Text(
          '¿Marcar "${item.actividad.descripcion}" como finalizada?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final provider = context.read<ActividadesPendientesProvider>();
    final ok = await provider.marcarFinalizada(item);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '¡${item.actividad.descripcion} finalizada!'
              : provider.error ?? 'No se pudo finalizar la actividad.',
        ),
        backgroundColor: ok ? const Color(0xFF2E7D32) : PlanazoColors.error,
      ),
    );
  }

  Future<void> _reagendar(
    BuildContext context,
    ActividadConClima item,
  ) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(item.actividad.fecha) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Nueva fecha',
    );
    if (fecha == null || !context.mounted) return;

    final inicio = await showTimePicker(
      context: context,
      initialTime: _horaDe(item.actividad.horaInicio),
      helpText: 'Hora de inicio',
    );
    if (inicio == null || !context.mounted) return;

    final fin = await showTimePicker(
      context: context,
      initialTime: _horaDe(item.actividad.horaFin),
      helpText: 'Hora de fin',
    );
    if (fin == null || !context.mounted) return;

    if (fin.hour * 60 + fin.minute <= inicio.hour * 60 + inicio.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la de inicio.'),
        ),
      );
      return;
    }

    final provider = context.read<ActividadesPendientesProvider>();
    final ok = await provider.reagendar(
      item,
      nuevaFecha: formatearFecha(fecha),
      nuevaHoraInicio: formatearHora(hora: inicio.hour, minuto: inicio.minute),
      nuevaHoraFin: formatearHora(hora: fin.hour, minuto: fin.minute),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Actividad reagendada.'
              : provider.error ?? 'No se pudo reagendar la actividad.',
        ),
        backgroundColor: ok ? PlanazoColors.secondary : PlanazoColors.error,
      ),
    );
  }

  TimeOfDay _horaDe(String hora) {
    final partes = hora.split(':');
    return TimeOfDay(
      hour: int.tryParse(partes.first) ?? 8,
      minute: int.tryParse(partes.last) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<ActividadesPendientesProvider>();

    return RefreshIndicator(
      onRefresh: _refrescar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // --- Filtros ---
          SliverToBoxAdapter(
            child: _BarraFiltros(provider: provider),
          ),

          // --- Contenido ---
          if (provider.cargando)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.error != null)
            SliverFillRemaining(
              child: _EstadoError(
                mensaje: provider.error!,
                onReintentar: _refrescar,
              ),
            )
          else if (provider.items.isEmpty)
            const SliverFillRemaining(
              child: _EstadoVacio(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = provider.items[index];
                    return ActividadPendienteCard(
                      item: item,
                      onFinalizar: () => _finalizar(context, item),
                      onReagendar: () => _reagendar(context, item),
                    );
                  },
                  childCount: provider.items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barra de filtros
// ---------------------------------------------------------------------------

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({required this.provider});
  final ActividadesPendientesProvider provider;

  @override
  Widget build(BuildContext context) {
    final ubicaciones =
        context.watch<UbicacionesProvider>().ubicaciones;
    final hayFiltros = provider.filtroIdUbicacion != null ||
        provider.filtroProbabilidad != null ||
        provider.soloProximos;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Toggle "Proximos 7 dias"
                FilterChip(
                  key: const Key('filtro_proximos'),
                  label: const Text('Proximos 7 dias'),
                  selected: provider.soloProximos,
                  onSelected: (v) =>
                      provider.cambiarSoloProximos(v),
                  selectedColor: PlanazoColors.primaryContainer,
                  checkmarkColor: PlanazoColors.onPrimaryContainer,
                ),
                const SizedBox(width: 8),

                // Filtro por probabilidad
                for (final nivel in ProbabilidadNivel.values) ...[
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(nivel.icono, size: 14, color: nivel.color),
                        const SizedBox(width: 4),
                        Text(nivel.etiquetaCorta),
                      ],
                    ),
                    selected: provider.filtroProbabilidad == nivel,
                    onSelected: (v) => provider.cambiarFiltroProbabilidad(
                      v ? nivel : null,
                    ),
                    selectedColor: nivel.colorFondo,
                  ),
                  const SizedBox(width: 8),
                ],

                // Filtro por ubicacion
                if (ubicaciones.isNotEmpty)
                  DropdownButton<int?>(
                    value: provider.filtroIdUbicacion,
                    hint: const Text('Ubicacion'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      for (final u in ubicaciones)
                        DropdownMenuItem<int?>(
                          value: u.idUbicacion,
                          child: Text(u.nombre),
                        ),
                    ],
                    onChanged: provider.cambiarFiltroUbicacion,
                  ),
              ],
            ),
          ),

          // Boton "Limpiar filtros"
          if (hayFiltros)
            TextButton.icon(
              onPressed: provider.limpiarFiltros,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
              label: const Text('Limpiar filtros'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados vacios y de error
// ---------------------------------------------------------------------------

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: PlanazoColors.primaryContainer,
              child: Icon(
                Icons.event_available,
                size: 40,
                color: PlanazoColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin actividades pendientes',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay actividades pendientes con los filtros actuales.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PlanazoColors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: PlanazoColors.errorContainer,
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: PlanazoColors.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PlanazoColors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
