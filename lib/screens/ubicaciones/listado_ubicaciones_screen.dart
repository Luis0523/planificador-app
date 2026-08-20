import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/ubicacion.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../widgets/ubicacion_card.dart';
import 'formulario_ubicacion_screen.dart';

/// Listado de ubicaciones (cuerpo de la pestaña "Ubicaciones").
class ListadoUbicacionesScreen extends StatelessWidget {
  const ListadoUbicacionesScreen({super.key});

  Future<void> _nuevaUbicacion(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FormularioUbicacionScreen()),
    );
  }

  Future<void> _editar(BuildContext context, Ubicacion ubicacion) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioUbicacionScreen(ubicacion: ubicacion),
      ),
    );
  }

  Future<void> _confirmarEliminacion(
    BuildContext context,
    Ubicacion ubicacion,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<UbicacionesProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar ubicación'),
        content: const Text(
          '¿Eliminar esta ubicación? También se eliminarán '
          'las actividades asociadas. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PlanazoColors.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final ok = await provider.eliminar(ubicacion.idUbicacion!);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Ubicación eliminada.' : (provider.error ?? 'Error'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UbicacionesProvider>();
    final ubicaciones = provider.ubicaciones;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mis ubicaciones',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton.filled(
                key: const Key('btn_nueva_ubicacion'),
                tooltip: 'Nueva ubicación',
                onPressed: () => _nuevaUbicacion(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.cargando && ubicaciones.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ubicaciones.isEmpty
                    ? _EstadoVacio(onCrear: () => _nuevaUbicacion(context))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: ubicaciones.length,
                        itemBuilder: (context, index) {
                          final ubicacion = ubicaciones[index];
                          return UbicacionCard(
                            ubicacion: ubicacion,
                            onEditar: () => _editar(context, ubicacion),
                            onEliminar: () =>
                                _confirmarEliminacion(context, ubicacion),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.onCrear});

  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: PlanazoColors.primaryContainer,
            child: Icon(
              Icons.location_on_outlined,
              size: 40,
              color: PlanazoColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes ubicaciones',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Guarda tus lugares para crear actividades condicionadas por el clima.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PlanazoColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCrear,
            child: const Text('Crear primera ubicación'),
          ),
        ],
      ),
    );
  }
}
