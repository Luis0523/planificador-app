import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';

/// Secciones navegables del menú lateral.
class AppSecciones {
  AppSecciones._();

  static const String inicio = 'inicio';
  static const String ubicaciones = 'ubicaciones';
  static const String actividades = 'actividades';
  static const String pendientes = 'pendientes';
  static const String perfil = 'perfil';
}

/// Menú lateral con los módulos de la aplicación y el cierre de sesión.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.seccionActual,
    required this.onSeleccionar,
    required this.onCerrarSesion,
  });

  final String seccionActual;
  final ValueChanged<String> onSeleccionar;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Encabezado(
              nombre: usuario?.nombreCompleto ?? 'Planazero',
              correo: usuario?.correo ?? '',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(
                    context,
                    key: const Key('drawer_inicio'),
                    icono: Icons.home,
                    texto: 'Inicio',
                    seccion: AppSecciones.inicio,
                  ),
                  _item(
                    context,
                    key: const Key('drawer_actividades'),
                    icono: Icons.celebration_outlined,
                    texto: 'Mis actividades',
                    seccion: AppSecciones.actividades,
                  ),
                  _item(
                    context,
                    key: const Key('drawer_pendientes'),
                    icono: Icons.pending_actions_outlined,
                    texto: 'Actividades pendientes',
                    seccion: AppSecciones.pendientes,
                  ),
                  _item(
                    context,
                    key: const Key('drawer_ubicaciones'),
                    icono: Icons.location_on_outlined,
                    texto: 'Mis ubicaciones',
                    seccion: AppSecciones.ubicaciones,
                  ),
                  _item(
                    context,
                    key: const Key('drawer_perfil'),
                    icono: Icons.person_outline,
                    texto: 'Mi perfil',
                    seccion: AppSecciones.perfil,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('drawer_cerrar_sesion'),
              leading: const Icon(Icons.logout, color: PlanazoColors.error),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: PlanazoColors.error),
              ),
              onTap: onCerrarSesion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required Key key,
    required IconData icono,
    required String texto,
    required String seccion,
  }) {
    final activo = seccionActual == seccion;
    return ListTile(
      key: key,
      leading: Icon(icono),
      title: Text(texto),
      selected: activo,
      selectedColor: PlanazoColors.primary,
      selectedTileColor: PlanazoColors.primaryContainer.withValues(alpha: 0.25),
      onTap: () => onSeleccionar(seccion),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.nombre, required this.correo});

  final String nombre;
  final String correo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: PlanazoColors.primary,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: PlanazoColors.primaryContainer,
            child: Icon(
              Icons.person,
              size: 30,
              color: PlanazoColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: PlanazoColors.onPrimary,
                ),
          ),
          Text(
            correo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PlanazoColors.primaryFixedDim,
                ),
          ),
        ],
      ),
    );
  }
}
