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

/// Menú lateral de Planazo (mock: context/mock/home_con_men_lateral).
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.seccionActual,
    required this.onSeleccionar,
    required this.onCerrarSesion,
  });

  /// Sección resaltada (una de [AppSecciones]).
  final String seccionActual;
  final ValueChanged<String> onSeleccionar;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombre = auth.usuario?.nombreCompleto ?? 'Planazero';
    final correo = auth.usuario?.correo ?? '';

    return Drawer(
      backgroundColor: PlanazoColors.onSecondaryContainer,
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(PlanazoColors.radiusXl),
          bottomRight: Radius.circular(PlanazoColors.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _EncabezadoPerfil(nombre: nombre, correo: correo),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _ItemMenu(
                      key: const Key('drawer_inicio'),
                      icono: Icons.home,
                      etiqueta: 'Inicio',
                      activo: seccionActual == AppSecciones.inicio,
                      onTap: () => onSeleccionar(AppSecciones.inicio),
                    ),
                    _ItemMenu(
                      key: const Key('drawer_ubicaciones'),
                      icono: Icons.location_on_outlined,
                      etiqueta: 'Mis ubicaciones',
                      activo: seccionActual == AppSecciones.ubicaciones,
                      onTap: () => onSeleccionar(AppSecciones.ubicaciones),
                    ),
                    _ItemMenu(
                      key: const Key('drawer_actividades'),
                      icono: Icons.celebration_outlined,
                      etiqueta: 'Mis actividades',
                      activo: seccionActual == AppSecciones.actividades,
                      onTap: () => onSeleccionar(AppSecciones.actividades),
                    ),
                    _ItemMenu(
                      key: const Key('drawer_pendientes'),
                      icono: Icons.pending_actions_outlined,
                      etiqueta: 'Actividades pendientes',
                      activo: seccionActual == AppSecciones.pendientes,
                      badge: '2',
                      onTap: () => onSeleccionar(AppSecciones.pendientes),
                    ),
                    const Divider(
                      color: PlanazoColors.primary,
                      thickness: 1,
                      height: 24,
                    ),
                    _ItemMenu(
                      key: const Key('drawer_perfil'),
                      icono: Icons.person_outline,
                      etiqueta: 'Mi perfil',
                      activo: seccionActual == AppSecciones.perfil,
                      onTap: () => onSeleccionar(AppSecciones.perfil),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: _BotonCerrarSesion(onTap: onCerrarSesion),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoPerfil extends StatelessWidget {
  const _EncabezadoPerfil({required this.nombre, required this.correo});

  final String nombre;
  final String correo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PlanazoColors.primary, Colors.transparent],
          stops: [0, 0.6],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: PlanazoColors.primaryFixedDim, width: 2),
            ),
            child: const CircleAvatar(
              backgroundColor: PlanazoColors.secondaryContainer,
              child: Icon(
                Icons.person,
                color: PlanazoColors.onSecondaryContainer,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nombre,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: PlanazoColors.onPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            correo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PlanazoColors.primaryFixedDim,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.activo = false,
    this.badge,
  });

  final IconData icono;
  final String etiqueta;
  final bool activo;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo ? PlanazoColors.onPrimary : PlanazoColors.primaryFixedDim;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: activo
                ? PlanazoColors.primary.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
          ),
          child: Row(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null)
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: PlanazoColors.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PlanazoColors.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonCerrarSesion extends StatelessWidget {
  const _BotonCerrarSesion({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlanazoColors.onPrimary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
      child: InkWell(
        key: const Key('drawer_cerrar_sesion'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout,
                color: PlanazoColors.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Cerrar sesión',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: PlanazoColors.onPrimary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
