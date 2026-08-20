# Plan de Desarrollo — Planificador de Actividades (Flutter)

**Proyecto:** Planificador de Actividades — Flutter
**Plataformas objetivo:** Android e iOS (primarias), Web (secundaria)
**Fuente de verdad:** `especificacion_app_flutter.md`

---

## 1. Decisiones de arquitectura acordadas

### 1.1 Estrategia de plataformas
- **Objetivo primario:** Android y iOS con el stack completo de la spec (`sqflite`, `geolocator`, `google_maps_flutter`).
- **Web (secundaria):** se compila desde el mismo código, pero desde el inicio se aíslan los puntos no soportados:
  - Acceso a BD a través de una **capa de repositorios** (`services/*` actúan como interfaz). En web se inyecta una implementación alternativa o se declara el módulo como no disponible.
  - Las pantallas con Maps/GPS se protegen con `kIsWeb` mostrando "no disponible en web" en lugar de crashear.
- Web se valida en cada checkpoint si es viable, **sin bloquear** el avance de Android/iOS.

### 1.2 Estrategia de mocks (hasta tener backend y API keys)
- **Backend de auth no está desplegado aún.** Se usa un mock:
  - Respuestas hardcodeadas en `auth_service.dart` marcadas con `// TODO: reemplazar por backend real`.
  - La interfaz del service no cambia → el resto de la app no nota la diferencia cuando se conecte el backend real.
- **API keys (Google Maps y clima) aún no disponibles.** Se consiguen cuando se necesiten:
  - `maps_service.dart` y `clima_service.dart` devuelven datos simulados, marcados con `// TODO: API key pendiente`.
  - La lógica de negocio (probabilidad, validaciones) se implementa real desde el inicio; solo el origen de datos es simulado.
- Servicios como singletons/interfaces → swap mock→real = solo cambiar la implementación.

### 1.3 Restricciones que respetar siempre (spec, sección 7)
- No implementar la sincronización cifrada (`/api/sync/*`) — son stub en el servidor.
- No implementar funcionalidades "plus" (Fase 9) antes del MVP completo.
- JWT solo en `flutter_secure_storage`, nunca en SQLite ni `shared_preferences`.
- Google Maps y clima siempre directo desde la app, nunca desde el backend.
- API keys en `.env`, nunca hardcodeadas ni subidas a un repo público.

---

## 2. Fases

**Regla general (spec, sección 6):** cada fase termina con algo que se pueda correr y probar en emulador/dispositivo real antes de pasar a la siguiente.

| Fase | Objetivo | Checkpoint (se corre y se prueba) | Notas de la adaptación |
|---|---|---|---|
| **0 — Setup** | Proyecto Flutter, estructura de carpetas, dependencias, `.env`, tema y logo | App corre con splash + logo, sin errores de compilación | `flutter create` habilitando android/ios/web. Dependencias: `provider`, `dio`, `flutter_secure_storage`, `sqflite`, `geolocator`, `google_maps_flutter`, `google_places_flutter`, `intl`, `flutter_dotenv`. `.env.example` con `API_BASE_URL`, `GOOGLE_MAPS_API_KEY`, `WEATHER_API_KEY` |
| **1 — BD local** | 5 tablas SQLite, catálogo `condiciones_climaticas` precargado, FK ON, borrado en cascada | Insertar una ubicación + actividad asociada, borrar la ubicación y ver que la actividad se borra en cascada | Solo Android/iOS (en web se declara no soportado desde aquí). `PRAGMA foreign_keys = ON` en cada conexión. Script/botón de prueba temporal que se elimina después |
| **2 — Autenticación** | 4 pantallas auth + `api_service` (dio + interceptor JWT) + token en secure storage + flujo `requiereCambioContrasena` | Registrar → login → recuperar → loguearse con temporal → forzar cambio de contraseña (doble confirmación) → llegar al Home | **Backend mockeado** (hardcodeado con TODO), sin cambiar la interfaz del service |
| **3 — Navegación** | Home + menú lateral + logout | Desde login se llega al Home, el menú navega a módulos placeholder, logout limpia token y vuelve a login **sin borrar SQLite** | |
| **4 — Usuario** | Perfil con GET/PUT `/api/users/me`, `nombreUsuario` y contraseña solo lectura | Datos del usuario se muestran y editan; el cambio persiste al recargar | Mock |
| **5 — Ubicaciones** | CRUD completo + GPS + selección en mapa + confirmación de borrado en cascada | Crear una por GPS, otra por selección manual en el mapa, editarlas, y borrar una viendo que sus actividades desaparecen | **Maps/GPS mockeados hasta obtener la key**. UI de solicitud/rechazo de permisos ya implementada. Aviso claro antes de borrar (borra en cascada) |
| **6 — Actividades** | CRUD ligado a ubicación + validación de cruce de horarios + selector múltiple de condiciones + tipo | Crear una actividad, intentar otra que se cruce en horario en la misma ubicación (debe rechazarse con mensaje claro), editar/eliminar | |
| **7 — Pendientes (30%)** | Clima real, `probabilidad_service`, filtros, marcar finalizada y reagendar con historial | Indicador de probabilidad cambia según clima consultado; filtros funcionan; finalizar/reagendar deja rastro en `historial_actividades` | **Clima mock hasta obtener la key**; la lógica de probabilidad se implementa real desde el inicio |
| **8 — Pulido** | Validación de formularios, loading/error de red visible en cada pantalla, manejo global de 401/logout | Recorrido completo (registro → login → crear ubicación → crear actividad → verla en pendientes → finalizarla) sin errores ni pantallas rotas | |
| **9 — Plus** | Backlog: notificaciones locales, actividades recurrentes, papelera, gráficas, favoritos, etc. | — | No arrancar hasta completar y probar fases 0–8. Referencia: `diseno_planificador_actividades.md` sección 5 |

---

## 3. Orden de trabajo

1. **Fase 0** — `flutter create` + `pubspec.yaml` con dependencias + estructura de carpetas (spec, sección 3) + `.env.example` + `config/theme.dart`.
2. **Fase 1** — BD local con script de prueba temporal (se elimina después).
3. **Fase 2** — Auth con backend mockeado.
4. Fases 3–8 en orden, validando el checkpoint de cada una antes de avanzar.

---

## 4. Estructura de carpetas (spec, sección 3)

```
lib/
├── main.dart
├── config/
│   ├── constants.dart
│   └── theme.dart
├── database/
│   ├── database_helper.dart
│   └── tables/
│       ├── ubicaciones_table.dart
│       ├── actividades_table.dart
│       ├── historial_table.dart
│       └── condiciones_table.dart
├── models/
│   ├── usuario.dart
│   ├── ubicacion.dart
│   ├── actividad.dart
│   ├── condicion_climatica.dart
│   └── historial_actividad.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── usuario_service.dart
│   ├── ubicacion_service.dart
│   ├── actividad_service.dart
│   ├── clima_service.dart
│   ├── maps_service.dart
│   └── probabilidad_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── ubicaciones_provider.dart
│   ├── actividades_provider.dart
│   └── actividades_pendientes_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── registro_screen.dart
│   │   ├── recuperar_contrasena_screen.dart
│   │   └── cambiar_contrasena_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── usuario/
│   │   └── perfil_screen.dart
│   ├── ubicaciones/
│   │   ├── listado_ubicaciones_screen.dart
│   │   └── formulario_ubicacion_screen.dart
│   ├── actividades/
│   │   ├── listado_actividades_screen.dart
│   │   └── formulario_actividad_screen.dart
│   └── actividades_pendientes/
│       └── actividades_pendientes_screen.dart
├── widgets/
│   ├── app_drawer.dart
│   ├── ubicacion_card.dart
│   ├── actividad_card.dart
│   └── clima_indicator.dart
└── utils/
    ├── validators.dart
    └── date_helpers.dart
```
