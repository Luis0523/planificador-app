import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../widgets/app_drawer.dart';
import '../actividades/listado_actividades_screen.dart';
import '../ubicaciones/listado_ubicaciones_screen.dart';
import '../usuario/perfil_screen.dart';

/// Home de Planazo (Fase 3): header + dashboard + navegación (drawer y bottom nav).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _indiceInicio = 0;
  static const int _indiceUbicaciones = 1;
  static const int _indicePendientes = 2;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _indice = _indiceInicio;

  @override
  void initState() {
    super.initState();
    // Carga los datos locales (ubicaciones) después del primer frame
    // para que el dashboard y la pestaña de ubicaciones tengan datos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final usuario = context.read<AuthProvider>().usuario;
      if (usuario != null) {
        context.read<UbicacionesProvider>().cargar(usuario.id);
      }
    });
  }

  String get _seccionActual => switch (_indice) {
        _indiceUbicaciones => AppSecciones.ubicaciones,
        _indicePendientes => AppSecciones.pendientes,
        _ => AppSecciones.inicio,
      };

  void _cambiarIndice(int indice) {
    setState(() => _indice = indice);
  }

  void _seleccionarSeccion(String seccion) {
    Navigator.of(context).pop(); // cierra el drawer
    switch (seccion) {
      case AppSecciones.inicio:
        _cambiarIndice(_indiceInicio);
      case AppSecciones.ubicaciones:
        _cambiarIndice(_indiceUbicaciones);
      case AppSecciones.pendientes:
        _cambiarIndice(_indicePendientes);
      case AppSecciones.actividades:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ListadoActividadesScreen()),
        );
      case AppSecciones.perfil:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PerfilScreen()),
        );
    }
  }

  void _cerrarSesion() {
    Navigator.of(context).pop(); // cierra el drawer
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final titulos = const ['Inicio', 'Ubicaciones', 'Pendientes'];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        seccionActual: _seccionActual,
        onSeleccionar: _seleccionarSeccion,
        onCerrarSesion: _cerrarSesion,
      ),
      body: Column(
        children: [
          _PlanazoHeader(
            titulo: titulos[_indice],
            onAbrirMenu: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: switch (_indice) {
              _indiceUbicaciones => const ListadoUbicacionesScreen(),
              _indicePendientes => const _ModuloPlaceholder(
                  icono: Icons.pending_actions_outlined,
                  titulo: 'Actividades pendientes',
                  mensaje: 'Aquí verás tus actividades próximas con el clima '
                      'real y su probabilidad de realización. (Fase 7)',
                ),
              _ => const _DashboardInicio(),
            },
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        indice: _indice,
        onChanged: _cambiarIndice,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _PlanazoHeader extends StatelessWidget {
  const _PlanazoHeader({required this.titulo, required this.onAbrirMenu});

  final String titulo;
  final VoidCallback onAbrirMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanazoColors.surface,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Menú',
                  onPressed: onAbrirMenu,
                  icon: const Icon(Icons.menu),
                  color: PlanazoColors.onSurface,
                ),
                const SizedBox(width: 4),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: PlanazoColors.primaryContainer,
                  child: Icon(
                    Icons.event_available,
                    size: 18,
                    color: PlanazoColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Planazo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: PlanazoColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: PlanazoColors.primary,
                  child: Icon(Icons.person, size: 18, color: PlanazoColors.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard (tab Inicio)
// ---------------------------------------------------------------------------

class _DashboardInicio extends StatelessWidget {
  const _DashboardInicio();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ubicaciones = context.watch<UbicacionesProvider>().ubicaciones;
    final nombre =
        auth.usuario?.nombreCompleto.split(' ').first ?? 'Planazero';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $nombre 👋',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué planazo armamos hoy?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PlanazoColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: _BentoCard(
                  color: PlanazoColors.primaryContainer,
                  icono: Icons.calendar_month,
                  iconoColor: PlanazoColors.onPrimaryContainer,
                  titulo: 'Próximas actividades',
                  conteo: 0, // TODO(Fase 6): desde la BD
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BentoCard(
                  color: PlanazoColors.secondaryContainer,
                  icono: Icons.location_on,
                  iconoColor: PlanazoColors.onSecondaryContainer,
                  titulo: 'Ubicaciones guardadas',
                  conteo: ubicaciones.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _EstadoVacio(),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.color,
    required this.icono,
    required this.iconoColor,
    required this.titulo,
    required this.conteo,
  });

  final Color color;
  final IconData icono;
  final Color iconoColor;
  final String titulo;
  final int conteo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: PlanazoColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconoColor.withValues(alpha: 0.10),
            child: Icon(icono, color: iconoColor, size: 20),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: iconoColor,
                      ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: PlanazoColors.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$conteo',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: PlanazoColors.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: PlanazoColors.surfaceContainer,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusXl),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: PlanazoColors.surfaceContainerHigh,
            child: const Icon(
              Icons.cruelty_free,
              size: 32,
              color: PlanazoColors.outline,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Todo muy tranquilo',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'No tienes planes para este finde. ¡Es momento de inventar algo!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PlanazoColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crear planazo estará disponible en la Fase 6.'),
                ),
              );
            },
            child: const Text('Crear planazo'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder de módulos sin construir todavía
// ---------------------------------------------------------------------------

class _ModuloPlaceholder extends StatelessWidget {
  const _ModuloPlaceholder({
    required this.icono,
    required this.titulo,
    required this.mensaje,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: PlanazoColors.primaryContainer,
              child: Icon(icono, size: 40, color: PlanazoColors.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
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

// ---------------------------------------------------------------------------
// Navegación inferior
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.indice, required this.onChanged});

  final int indice;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanazoColors.surface,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              _ItemNav(
                key: const Key('nav_inicio'),
                icono: Icons.home,
                etiqueta: 'Home',
                activo: indice == 0,
                onTap: () => onChanged(0),
              ),
              _ItemNav(
                key: const Key('nav_ubicaciones'),
                icono: Icons.location_on,
                etiqueta: 'Locations',
                activo: indice == 1,
                onTap: () => onChanged(1),
              ),
              _ItemNav(
                key: const Key('nav_pendientes'),
                icono: Icons.pending_actions,
                etiqueta: 'Pending',
                activo: indice == 2,
                onTap: () => onChanged(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo ? PlanazoColors.secondary : PlanazoColors.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: activo
                ? PlanazoColors.primaryContainer.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
