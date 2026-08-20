# Avance — Fase 2: Autenticación

**Fecha y hora:** 2026-08-20 12:53
**Estado:** Completada y probada (9 tests pasan; app corriendo en dispositivo físico SM-S908U1)

---

## Qué se hizo

Implementación completa del módulo de autenticación contra un **backend mockeado** (el backend Node aún no está desplegado). Login, registro, recuperación y cambio de contraseña funcionan de punta a punta dentro de la app.

- `api_service.dart`: cliente HTTP `dio` con interceptor que adjunta `Authorization: Bearer <JWT>` a cada request y otro que limpia el token cuando el servidor responde 401.
- Token (JWT) guardado siempre en `flutter_secure_storage`, nunca en SQLite ni `shared_preferences`.
- `auth_service.dart`: login, registro, recuperación y cambio de contraseña con respuestas simuladas. El flag `Constants.useMockBackend` (en `config/constants.dart`) controla el modo mock → real; la interfaz no cambia, por lo que conectar el backend real solo requiere cambiar ese flag.
- `auth_provider.dart`: manejo de estado con `provider`. Estados: `desconocido → noAutenticado → requiereCambio → autenticado`. Restaura la sesión al abrir la app si hay un token guardado.
- `AuthGate` en `main.dart`: enruta según el estado — sin sesión → Login; login con contraseña temporal → fuerza la pantalla de cambio de contraseña (doble confirmación); sesión activa → Home.
- `utils/validators.dart`: validación de correo, contraseña (mín. 6), confirmación, teléfono y nombre de usuario.
- Home temporal (la navegación completa se construye en la Fase 3).

### Credenciales de prueba (mock)

- Correo: `demo@planificador.com` / Contraseña: `123456`
- Contraseña temporal simulada: `temporal123` (obliga a cambiarla)

---

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/config/constants.dart` | Flag `useMockBackend` agregado |
| `lib/main.dart` | Providers + `AuthGate`; splash reemplazado por enrutamiento por estado de auth |
| `test/widget_test.dart` | Test de login inicial (antes probaba el splash) |

## Archivos creados

| Archivo | Descripción |
|---|---|
| `lib/services/api_service.dart` | Cliente dio + interceptor JWT + manejo del token (guardar/leer/limpiar) |
| `lib/services/auth_service.dart` | Lógica de auth (mock + camino real con TODO) |
| `lib/providers/auth_provider.dart` | Estado de autenticación (provider) |
| `lib/utils/validators.dart` | Validadores de formularios |
| `lib/screens/auth/login_screen.dart` | Pantalla de inicio de sesión |
| `lib/screens/auth/registro_screen.dart` | Pantalla de registro |
| `lib/screens/auth/recuperar_contrasena_screen.dart` | Pantalla de recuperación de contraseña |
| `lib/screens/auth/cambiar_contrasena_screen.dart` | Pantalla de cambio de contraseña (doble confirmación) |
| `lib/screens/home/home_screen.dart` | Home temporal con logout |
| `test/auth_flow_test.dart` | Tests del flujo completo de auth (6 casos) |

---

## Verificación

- `flutter analyze`: 0 issues
- `flutter test`: 9 tests pasan
- Build web: OK
- Build Android debug: OK
- App probada en dispositivo físico (SM-S908U1, Android 16)

## Siguiente fase

**Fase 3 — Navegación principal:** Home con menú lateral (drawer) y accesos a los módulos, botón de cerrar sesión funcional.
