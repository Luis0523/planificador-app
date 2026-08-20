# Avance — Fase 4: Módulo de Usuario (Perfil)

**Fecha y hora:** 2026-08-20 13:28
**Estado:** Completada y probada (17 tests pasan; builds web y Android OK)

---

## Qué se hizo

Pantalla de perfil conectada a `GET/PUT /api/users/me` (con backend mockeado), con `nombreUsuario`, correo y contraseña en **solo lectura**, y edición de nombre completo y teléfono con persistencia.

- **`services/mock_backend.dart` (nuevo):** store compartido en memoria que simula el backend de auth/perfil. Ahora `auth_service` y `usuario_service` usan el mismo estado, por lo que editar el perfil persiste y el registro/login siguen funcionando. Marcado `TODO` para eliminar cuando esté el backend real.
- **`services/usuario_service.dart` (nuevo):** `obtenerPerfil()` (GET) y `actualizarPerfil()` (PUT). El PUT nunca envía `nombreUsuario` ni contraseña, como exige la spec. Modo mock ↔ real controlado por `Constants.useMockBackend`.
- **`providers/auth_provider.dart`:** métodos `cargarPerfil()` y `actualizarPerfil()`. Al restaurar una sesión guardada (`_init`), ahora también se carga el perfil para que el drawer y el perfil muestren datos reales.
- **`screens/usuario/perfil_screen.dart`:** reescrita con el diseño Planazo:
  - Encabezado con avatar, nombre y correo.
  - Sección "Datos de cuenta": nombre de usuario, correo y contraseña en **solo lectura** (con aviso de que la contraseña se gestiona por el flujo de recuperación).
  - Sección "Información editable": nombre completo y teléfono.
  - Botón "Guardar cambios" con validación (teléfono solo dígitos) y mensaje de éxito/error.

### Flujo verificado (checkpoint)
Los datos del usuario logueado se muestran correctamente → se editan nombre/teléfono → el cambio persiste al recargar la pantalla.

---

## Archivos creados

| Archivo | Descripción |
|---|---|
| `lib/services/mock_backend.dart` | Store en memoria compartido (auth + perfil) con `reset()` para tests |
| `lib/services/usuario_service.dart` | GET/PUT `/api/users/me` (mock + camino real) |
| `test/perfil_test.dart` | Tests del perfil (muestra datos, edición persistente, validación) |

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/services/auth_service.dart` | Refactorizado para usar `MockBackend` en lugar de su lista privada |
| `lib/providers/auth_provider.dart` | `cargarPerfil`, `actualizarPerfil` y carga de perfil al restaurar sesión |
| `lib/screens/usuario/perfil_screen.dart` | Reescrita: perfil completo con datos solo lectura + edición |
| `test/auth_flow_test.dart` | Reset de `MockBackend` en `setUp` (aislamiento) |
| `test/navigation_test.dart` | Assertion del perfil actualizado + reset de `MockBackend` |

## Verificación

- `flutter analyze`: 0 issues
- `flutter test`: 17 tests pasan
- Build web: OK
- Build Android debug: OK

## Siguiente fase

**Fase 5 — Módulo de Ubicaciones:** CRUD de ubicaciones con GPS (`geolocator`) y Google Maps (mockeado hasta obtener la API key), con confirmación del borrado en cascada.
