import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/actividades_pendientes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/app_drawer.dart';
import '../actividades/formulario_actividad_screen.dart';
import '../actividades/listado_actividades_screen.dart';
import '../actividades_pendientes/actividades_pendientes_screen.dart';
import '../ubicaciones/listado_ubicaciones_screen.dart';
import '../usuario/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recargar());
  }

  Future<void> _recargar() async {
    final usuario = context.read<AuthProvider>().usuario;
    if (usuario == null) return;
    await Future.wait([
      context.read<UbicacionesProvider>().cargar(usuario.id),
      context.read<ActividadesPendientesProvider>().cargar(usuario.id),
    ]);
  }

  void _cambiarIndice(int indice) {
    setState(() => _indice = indice);
    if (indice == 0 || indice == 2) _recargar();
  }

  void _seleccionarSeccion(String seccion) {
    Navigator.of(context).pop();
    switch (seccion) {
      case AppSecciones.inicio:
        _cambiarIndice(0);
      case AppSecciones.actividades:
        _cambiarIndice(1);
      case AppSecciones.pendientes:
        _cambiarIndice(2);
      case AppSecciones.ubicaciones:
        _cambiarIndice(3);
      case AppSecciones.perfil:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PerfilScreen()));
    }
  }

  Future<void> _abrirNuevaActividad() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FormularioActividadScreen()),
    );
    if (creada == true && mounted) {
      await _recargar();
      _cambiarIndice(1);
    }
  }

  void _cerrarSesion() {
    Navigator.of(context).pop();
    context.read<AuthProvider>().logout();
  }

  String get _seccionActual => switch (_indice) {
    1 => AppSecciones.actividades,
    2 => AppSecciones.pendientes,
    3 => AppSecciones.ubicaciones,
    _ => AppSecciones.inicio,
  };

  @override
  Widget build(BuildContext context) {
    final mostrarFab = _indice == 0 || _indice == 1;

    return Scaffold(
      drawer: AppDrawer(
        seccionActual: _seccionActual,
        onSeleccionar: _seleccionarSeccion,
        onCerrarSesion: _cerrarSesion,
      ),
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: PlanazoColors.primary,
              child: Icon(
                Icons.event_available,
                size: 16,
                color: PlanazoColors.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Planazo',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _indice,
        children: [
          _DashboardInicio(
            onCrear: _abrirNuevaActividad,
            onRefrescar: _recargar,
          ),
          const ListadoActividadesScreen(),
          const ActividadesPendientesScreen(),
          const ListadoUbicacionesScreen(),
        ],
      ),
      floatingActionButton: mostrarFab
          ? FloatingActionButton(
              key: const Key('fab_nueva_actividad'),
              tooltip: 'Nueva actividad',
              onPressed: _abrirNuevaActividad,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice == 3 ? 0 : _indice,
        onTap: _cambiarIndice,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, key: Key('nav_inicio')),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration_outlined, key: Key('nav_actividades')),
            label: 'Actividades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions, key: Key('nav_pendientes')),
            label: 'Pendientes',
          ),
        ],
      ),
    );
  }
}

class _DashboardInicio extends StatelessWidget {
  const _DashboardInicio({required this.onCrear, required this.onRefrescar});

  final VoidCallback onCrear;
  final Future<void> Function() onRefrescar;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ubicaciones = context.watch<UbicacionesProvider>().ubicaciones;
    final pendientes = context.watch<ActividadesPendientesProvider>().items;
    final nombre = auth.usuario?.nombreCompleto.split(' ').first ?? 'Planazero';

    return RefreshIndicator(
      onRefresh: onRefrescar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Hola, $nombre 👋',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué planazo armamos hoy?',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: PlanazoColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TarjetaResumen(
                  icono: Icons.calendar_month,
                  titulo: 'Próximas actividades',
                  conteo: pendientes.length,
                  color: PlanazoColors.primaryContainer,
                  colorIcono: PlanazoColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TarjetaResumen(
                  icono: Icons.location_on,
                  titulo: 'Ubicaciones guardadas',
                  conteo: ubicaciones.length,
                  color: PlanazoColors.secondaryContainer,
                  colorIcono: PlanazoColors.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (pendientes.isEmpty)
            _EstadoVacio(onCrear: onCrear)
          else ...[
            Text('Lo que viene', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final item in pendientes.take(3))
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    item.probabilidad.icono,
                    color: item.probabilidad.color,
                  ),
                  title: Text(item.actividad.descripcion),
                  subtitle: Text(
                    '${formatearFechaLegible(DateTime.parse(item.actividad.fecha))}'
                    ' · ${item.actividad.horaInicio} · ${item.ubicacion.nombre}',
                  ),
                  trailing: Text(
                    '${item.probabilidad.etiquetaCorta} '
                    '${item.probabilidad.porcentaje}%',
                    style: TextStyle(
                      color: item.probabilidad.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onCrear,
              child: const Text('Crear planazo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({
    required this.icono,
    required this.titulo,
    required this.conteo,
    required this.color,
    required this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final int conteo;
  final Color color;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: colorIcono),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: colorIcono),
          ),
          const SizedBox(height: 4),
          Text(
            '$conteo',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: colorIcono, fontWeight: FontWeight.w800),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: PlanazoColors.surfaceContainer,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusXl),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available,
            size: 48,
            color: PlanazoColors.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Todo muy tranquilo',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'No tienes actividades próximas. ¡Crea la primera!',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: PlanazoColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCrear,
            child: const Text('Crear planazo'),
          ),
        ],
      ),
    );
  }
}
