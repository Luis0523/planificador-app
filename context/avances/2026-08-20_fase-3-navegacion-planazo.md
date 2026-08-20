# Avance — Fase 3: Navegación principal + Planazo Design System

**Fecha y hora:** 2026-08-20 13:04
**Estado:** Completada y probada (14 tests pasan; builds web y Android OK)

---

## Qué se hizo

Se adoptó la marca **Planazo** (según los mocks de `context/mock`) y se implementó la navegación principal: home con dashboard, menú lateral y barra inferior. Aplicación del **Planazo Design System** (`context/mock/planazo_design_system/DESIGN.md`) en toda la app.

### Planazo Design System
- **Paleta morada/lavanda**: primario `#6E528B`, secundario `#714E98`, terciario amarillo pálido, neutros cálidos, error `#BA1A1A` — todo en `config/theme.dart` (`PlanazoColors`).
- **Tipografía Plus Jakarta Sans** descargada como fuente variable y registrada en `pubspec.yaml` (pesos 400–800; sin depender de red en el dispositivo).
- **Formas**: botones/inputs redondeados 16px, tarjetas 24px, sombra suave "soft-layer".
- Temas de componentes: botones (secundario morado), inputs (lavanda al 10%), tarjetas con borde lavanda, AppBar plana sobre fondo claro, SnackBar flotante.

### Navegación
- **`widgets/app_drawer.dart`**: menú lateral estilo mock — perfil del usuario (nombre/correo del provider), secciones (Inicio, Mis ubicaciones, Mis actividades, Actividades pendientes con badge, Mi perfil) y botón de cerrar sesión.
- **`screens/home/home_screen.dart`**: shell con header de marca (logo + Planazo + sección actual + avatar), contenido por pestaña y **bottom nav** (Home / Locations / Pending).
  - Dashboard de inicio: saludo "Hola, {nombre} 👋", bento de stats (Próximas actividades, Ubicaciones guardadas) y estado vacío "Todo muy tranquilo" con botón "Crear planazo".
  - Pestañas Ubicaciones y Pendientes con placeholders (se construyen en Fases 5 y 7).
  - "Mis actividades" y "Mi perfil" navegan a pantallas placeholder (Fases 6 y 4).
- **Cerrar sesión** desde el drawer: limpia token y vuelve al login (sin borrar SQLite).

### Branding en auth
- Título de la app → **Planazo**; pantallas de login, registro, recuperación y cambio de contraseña con el nombre de marca y los estilos del design system.

---

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | Fuente Plus Jakarta Sans registrada en `assets/fonts/` |
| `lib/config/theme.dart` | Reescrito: `PlanazoColors` + `AppTheme` con el Planazo Design System |
| `lib/main.dart` | Título de la app → Planazo |
| `lib/screens/auth/login_screen.dart` | Marca Planazo + paleta nueva |
| `lib/screens/auth/registro_screen.dart` | Marca Planazo + paleta nueva |
| `lib/screens/auth/recuperar_contrasena_screen.dart` | Marca Planazo + paleta nueva |
| `lib/screens/auth/cambiar_contrasena_screen.dart` | Marca Planazo + paleta nueva |
| `test/auth_flow_test.dart` | Assertions del nuevo home + logout por drawer |
| `test/navigation_test.dart` | Creado: tests de navegación (drawer, bottom nav, dashboard) |

## Archivos creados

| Archivo | Descripción |
|---|---|
| `assets/fonts/PlusJakartaSans.ttf` | Fuente variable descargada (400–800) |
| `lib/widgets/app_drawer.dart` | Menú lateral de Planazo |
| `lib/screens/home/home_screen.dart` | Reescrito: header + dashboard + bottom nav + drawer |
| `lib/screens/usuario/perfil_screen.dart` | Placeholder de perfil (Fase 4) |
| `lib/screens/actividades/listado_actividades_screen.dart` | Placeholder de actividades (Fase 6) |

## Verificación

- `flutter analyze`: 0 issues
- `flutter test`: 14 tests pasan (auth + navegación)
- Build web: OK
- Build Android debug: OK

## Siguiente fase

**Fase 4 — Módulo de Usuario:** pantalla de perfil conectada a `GET/PUT /api/users/me` (con mock), con `nombreUsuario` y contraseña en solo lectura.
