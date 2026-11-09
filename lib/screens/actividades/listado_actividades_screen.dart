import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/ubicacion.dart';
import '../../providers/actividades_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../widgets/actividad_card.dart';
import 'formulario_actividad_screen.dart';

class ListadoActividadesScreen extends StatefulWidget {
  const ListadoActividadesScreen({super.key});

  @override
  State<ListadoActividadesScreen> createState() =>
      _ListadoActividadesScreenState();
}

class _ListadoActividadesScreenState extends State<ListadoActividadesScreen> {
  int? _idUbicacion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ActividadesProvider>().cargarCondiciones();
      _autoseleccionar();
    });
  }

  void _autoseleccionar() {
    if (!mounted || _idUbicacion != null) return;
    final ubicaciones = context.read<UbicacionesProvider>().ubicaciones;
    if (ubicaciones.isNotEmpty) {
      _cambiarUbicacion(ubicaciones.first.idUbicacion);
    }
  }

  void _programarAutoseleccion() {
    if (_idUbicacion != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoseleccionar());
  }

  void _cambiarUbicacion(int? id) {
    setState(() => _idUbicacion = id);
    if (id != null) {
      context.read<ActividadesProvider>().cargar(id);
    }
  }

  Ubicacion? _ubicacionActual(List<Ubicacion> ubicaciones) {
    final id = _idUbicacion;
    if (id == null) return null;
    for (final u in ubicaciones) {
      if (u.idUbicacion == id) return u;
    }
    return null;
  }

  Future<void> _abrirFormulario({dynamic actividad}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioActividadScreen(actividad: actividad),
      ),
    );
  }

  Future<void> _confirmarEliminacion(dynamic actividad) async {
    final provider = context.read<ActividadesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: const Text(
          '¿Eliminar esta actividad? Esta acción no se puede deshacer.',
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
      final ok = await provider.eliminar(actividad.idActividad);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Actividad eliminada.' : (provider.error ?? 'Error'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actividades = context.watch<ActividadesProvider>();
    final ubicaciones = context.watch<UbicacionesProvider>().ubicaciones;
    _programarAutoseleccion();

    return ubicaciones.isEmpty
        ? const _SinUbicaciones()
        : Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mis actividades',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton.filled(
                      key: const Key('btn_nueva_actividad'),
                      tooltip: 'Nueva actividad',
                      onPressed: _abrirFormulario,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: const Key('listado_ubicacion'),
                  initialValue: _idUbicacion,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: [
                    for (final u in ubicaciones)
                      DropdownMenuItem(
                        value: u.idUbicacion,
                        child: Text(u.nombre),
                      ),
                  ],
                  onChanged: _cambiarUbicacion,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _idUbicacion == null
                      ? const SizedBox()
                      : actividades.cargando && actividades.actividades.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : actividades.actividades.isEmpty
                      ? _EstadoVacio(onCrear: () => _abrirFormulario())
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: actividades.actividades.length,
                          itemBuilder: (context, index) {
                            final a = actividades.actividades[index];
                            return ActividadCard(
                              actividad: a,
                              condiciones: actividades.condicionesDeActividad(
                                a.idActividad!,
                              ),
                              ubicacion: _ubicacionActual(ubicaciones),
                              onEditar: () => _abrirFormulario(actividad: a),
                              onEliminar: () => _confirmarEliminacion(a),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
  }
}

class _SinUbicaciones extends StatelessWidget {
  const _SinUbicaciones();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: PlanazoColors.primaryContainer,
              child: Icon(
                Icons.place_outlined,
                size: 40,
                color: PlanazoColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Primero crea una ubicación',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Las actividades se asocian a una ubicación. Crea una en '
              'el módulo de Ubicaciones.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: PlanazoColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              Icons.celebration_outlined,
              size: 40,
              color: PlanazoColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes actividades',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera actividad para esta ubicación.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: PlanazoColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCrear,
            child: const Text('Crear actividad'),
          ),
        ],
      ),
    );
  }
}
