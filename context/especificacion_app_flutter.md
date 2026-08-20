# Especificación de la App Móvil (Flutter) — Planificador de Actividades

**Este documento es la fuente de verdad para construir la app móvil.** Está escrito para que otra IA (o desarrollador) lo tome y trabaje sin necesitar contexto adicional. La regla más importante de este documento está en la sección 6: **no se construye todo de una vez — se avanza por fases, probando cada una antes de seguir a la siguiente.** Si en algún punto no es posible probar una fase (por ejemplo, porque el backend real todavía no está desplegado), usar datos simulados (mocks) para no bloquear el avance, y dejarlo anotado.

---

## 1. Contexto del proyecto

App móvil Flutter, proyecto universitario de Programación de Dispositivos Móviles: un "Planificador de Actividades" donde el usuario registra ubicaciones físicas y crea actividades condicionadas por el clima de esa ubicación y fecha.

La app se conecta a **dos cosas externas**, además de su propio almacenamiento local:
1. Un **backend propio** (Node.js + Express + PostgreSQL en Neon) — solo para login, registro, recuperación de contraseña y datos de perfil.
2. **APIs externas de terceros** (GPS del dispositivo, Google Maps, clima) — consumidas **directo desde la app**, sin pasar por el backend.

Todo lo demás (ubicaciones, actividades, historial, condiciones climáticas) vive **local en SQLite**, dentro del dispositivo.

---

## 2. Stack técnico

| Elemento | Tecnología | Nota |
|---|---|---|
| Framework | Flutter | |
| Almacenamiento local | `sqflite` | base de datos SQLite embebida |
| Cliente HTTP | `dio` (preferido sobre `http` por interceptores, útil para adjuntar el JWT automáticamente) | |
| Almacenamiento seguro | `flutter_secure_storage` | para el JWT del backend, nunca en SQLite ni en `shared_preferences` |
| Manejo de estado | `provider` | recomendado por simplicidad y porque es lo más común en cursos — si el implementador prefiere Riverpod o Bloc, debe justificarlo, no cambiarlo por defecto |
| Ubicación GPS | `geolocator` | |
| Selección de ubicación / mapas | `google_maps_flutter` + `google_places_flutter` (o `google_maps_webservice` para geocoding) | requiere API key de Google Maps |
| Clima | Cliente HTTP directo a un servicio de clima (ver sección 5.3) | |
| Fechas/horas | `intl` | formateo y validación de fechas/horarios |
| Variables de entorno / claves | `flutter_dotenv` | para no hardcodear API keys ni la URL del backend |

---

## 3. Estructura de carpetas esperada

```
lib/
├── main.dart
├── config/
│   ├── constants.dart          # URLs base, nombres de tablas, etc.
│   └── theme.dart               # paleta de colores y estilos (logo/paleta, requisito del enunciado)
├── database/
│   ├── database_helper.dart     # inicialización de sqflite, creación de tablas
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
│   ├── api_service.dart         # cliente dio configurado con interceptor de JWT
│   ├── auth_service.dart        # login, registro, recuperación, cambio de contraseña
│   ├── usuario_service.dart     # GET/PUT /api/users/me
│   ├── ubicacion_service.dart   # CRUD local (sqflite) de ubicaciones
│   ├── actividad_service.dart   # CRUD local de actividades + validación de cruces
│   ├── clima_service.dart       # consulta a la API de clima
│   ├── maps_service.dart        # consulta a Google Maps API
│   └── probabilidad_service.dart # lógica de negocio: probabilidad de realización
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
│   │   └── home_screen.dart          # menú lateral + navegación
│   ├── usuario/
│   │   └── perfil_screen.dart
│   ├── ubicaciones/
│   │   ├── listado_ubicaciones_screen.dart
│   │   ├── formulario_ubicacion_screen.dart   # sirve para crear y editar
│   ├── actividades/
│   │   ├── listado_actividades_screen.dart
│   │   ├── formulario_actividad_screen.dart   # sirve para crear y editar
│   └── actividades_pendientes/
│       └── actividades_pendientes_screen.dart
├── widgets/
│   ├── app_drawer.dart            # menú lateral reutilizable
│   ├── ubicacion_card.dart
│   ├── actividad_card.dart
│   └── clima_indicator.dart       # ícono + probabilidad de realización
└── utils/
    ├── validators.dart
    └── date_helpers.dart
```

---

## 4. Modelo de datos local (SQLite)

Esto ya fue diseñado previamente y se reproduce aquí completo para que quede en un solo lugar de referencia.

### `ubicaciones`
| Campo | Tipo SQLite | Notas |
|---|---|---|
| id_ubicacion | INTEGER PK AUTOINCREMENT | |
| id_usuario | INTEGER | id devuelto por el backend al loguearse (no es FK real, SQLite no valida contra otra BD) |
| nombre | TEXT | |
| direccion | TEXT | opcional |
| latitud | REAL | |
| longitud | REAL | |
| fecha_creacion | TEXT | ISO 8601 |
| fecha_actualizacion | TEXT | |

### `actividades`
| Campo | Tipo SQLite | Notas |
|---|---|---|
| id_actividad | INTEGER PK AUTOINCREMENT | |
| id_ubicacion | INTEGER FK | → ubicaciones(id_ubicacion), ON DELETE CASCADE |
| descripcion | TEXT | |
| fecha | TEXT | formato 'YYYY-MM-DD' |
| hora_inicio | TEXT | formato 'HH:mm' |
| hora_fin | TEXT | |
| tipo_actividad | TEXT | 'aire_libre' \| 'interior' |
| estado | TEXT | 'pendiente' \| 'finalizada' \| 'reagendada' |
| fecha_creacion | TEXT | |
| fecha_actualizacion | TEXT | |

### `historial_actividades`
| Campo | Tipo SQLite | Notas |
|---|---|---|
| id_historial | INTEGER PK AUTOINCREMENT | |
| id_actividad | INTEGER FK | → actividades |
| estado_anterior | TEXT | |
| estado_nuevo | TEXT | |
| fecha_cambio | TEXT | |
| comentario | TEXT | opcional |

### `condiciones_climaticas` (catálogo, precargado en `onCreate`)
| Campo | Tipo SQLite | Notas |
|---|---|---|
| id_condicion | INTEGER PK AUTOINCREMENT | |
| nombre | TEXT | Soleado, Lluvioso, Nublado, Ventoso, Templado, Nevado |
| descripcion | TEXT | opcional |

### `actividad_condicion` (relación N:M)
| Campo | Tipo SQLite | Notas |
|---|---|---|
| id_actividad | INTEGER FK | → actividades |
| id_condicion | INTEGER FK | → condiciones_climaticas |
| *PK compuesta* | | (id_actividad, id_condicion) |

**Importante:** activar `PRAGMA foreign_keys = ON` en cada conexión abierta a la base, o `ON DELETE CASCADE` no funcionará.

---

## 5. Conexión a servicios externos

### 5.1 Backend propio (auth y perfil)

El backend expone estos endpoints (ver documento completo `especificacion_backend_nodejs.md` para el detalle total; acá va el resumen necesario para construir la app):

| Método | Ruta | Uso desde la app |
|---|---|---|
| POST | `/api/auth/register` | Pantalla de registro |
| POST | `/api/auth/login` | Pantalla de login. Respuesta incluye `token` y `requiereCambioContrasena` |
| POST | `/api/auth/forgot-password` | Pantalla de recuperación, solo pide correo |
| POST | `/api/auth/change-password` | Pantalla de cambio de contraseña (doble confirmación), requiere el JWT del login con contraseña temporal |
| GET | `/api/users/me` | Pantalla de perfil, al entrar |
| PUT | `/api/users/me` | Guardar cambios de perfil (nunca envía `nombreUsuario` ni contraseña) |

**Reglas de manejo del token:**
- Guardar el JWT en `flutter_secure_storage` inmediatamente después de un login exitoso.
- Configurar un interceptor de `dio` que agregue `Authorization: Bearer <token>` a toda request hacia rutas protegidas.
- Si `requiereCambioContrasena == true` en la respuesta de login, la navegación debe forzar la pantalla de cambio de contraseña — el usuario no puede llegar al Home todavía.
- Si cualquier request responde 401, limpiar el token guardado y redirigir a login (sesión expirada o inválida).
- Al cerrar sesión (botón del menú lateral), borrar el token de `flutter_secure_storage` y volver a login. **No borrar la base SQLite local** — los datos del planificador siguen siendo del usuario y deben seguir ahí si vuelve a loguearse en el mismo dispositivo.

### 5.2 Google Maps API

- Usada en el formulario de ubicaciones para: (a) autocompletar direcciones, y (b) permitir seleccionar un punto en el mapa y obtener sus coordenadas.
- La API key va en `.env`, nunca hardcodeada en el código ni subida a un repositorio público.
- Se llama directo desde la app — no pasa por el backend (ver justificación en el documento de arquitectura general).

### 5.3 API de Clima

- El enunciado menciona "la API de Google del clima", pero Google no ofrece una API pública de clima de uso general para consumidores. Se recomienda usar un servicio equivalente y documentar la sustitución con el profesor si hace falta justificarlo (ej. **OpenWeatherMap** o **WeatherAPI.com**, ambos con planes gratuitos suficientes para un proyecto académico).
- Se consulta por coordenadas (latitud/longitud de la ubicación) + fecha, para obtener el pronóstico del día de la actividad.
- Se llama directo desde la app, igual que Maps.

### 5.4 GPS del dispositivo

- Paquete `geolocator`, usado en el formulario de ubicaciones como alternativa a seleccionar manualmente en el mapa.
- Requiere pedir permisos de ubicación en tiempo de ejecución (`geolocator` lo maneja, pero hay que codificar la UI de solicitud/rechazo de permiso).

---

## 6. Plan de trabajo por fases

**Regla general: cada fase debe terminar con algo que se pueda correr y probar en un emulador/dispositivo real antes de pasar a la siguiente.** No avanzar con una fase a medio probar.

### Fase 0 — Setup del proyecto
**Objetivo:** proyecto Flutter corriendo, estructura de carpetas lista, dependencias instaladas.
- Crear proyecto Flutter, configurar `pubspec.yaml` con todas las dependencias de la sección 2.
- Crear la estructura de carpetas de la sección 3 (vacía, con archivos placeholder si hace falta).
- Configurar `flutter_dotenv` y un `.env.example` con las variables que se van a necesitar (`API_BASE_URL`, `GOOGLE_MAPS_API_KEY`, `WEATHER_API_KEY`, `WEATHER_API_KEY`).
- Definir la paleta de colores y el logo (requisito del enunciado, Login inciso c) en `config/theme.dart`.
- **Checkpoint:** la app corre y muestra una pantalla en blanco o un splash con el logo, sin errores de compilación.

### Fase 1 — Base de datos local
**Objetivo:** SQLite funcionando de forma aislada, sin ninguna pantalla todavía.
- Implementar `database_helper.dart` con la creación de las 5 tablas de la sección 4.
- Precargar el catálogo de `condiciones_climaticas` en el `onCreate`.
- Escribir un pequeño script o botón de prueba temporal (que se elimina después) que inserte y lea un registro de cada tabla, para confirmar que las tablas y las relaciones (incluido `ON DELETE CASCADE`) funcionan.
- **Checkpoint:** se puede insertar una ubicación, una actividad asociada, y verificar que al borrar la ubicación se borra la actividad en cascada. Sin esto funcionando, no seguir.

### Fase 2 — Autenticación contra el backend
**Objetivo:** login, registro, recuperación y cambio de contraseña funcionando de punta a punta contra el backend real (o contra un backend de prueba/mock si el backend de Node aún no está desplegado).
- Implementar `auth_service.dart` y `api_service.dart` (cliente dio + interceptor JWT).
- Construir las 4 pantallas de `screens/auth/`.
- Implementar el guardado/borrado del token en `flutter_secure_storage`.
- Implementar el flujo de `requiereCambioContrasena`.
- **Checkpoint:** se puede registrar un usuario nuevo, cerrar la app, volver a abrir, loguearse, pedir recuperación de contraseña (revisar que llegue el correo si el backend ya lo tiene implementado), loguearse con la temporal, y que la app fuerce el cambio de contraseña con doble confirmación antes de dejar entrar al Home.
- Si el backend todavía no está desplegado: usar un servidor mock (ej. `json-server` o respuestas hardcodeadas temporales en `auth_service.dart` claramente marcadas con `// TODO: reemplazar por backend real`) para no bloquear esta fase. Reemplazar apenas el backend esté disponible, sin cambiar la interfaz del service (para que el resto de la app no note la diferencia).

### Fase 3 — Navegación principal
**Objetivo:** Home con menú lateral funcional.
- Construir `home_screen.dart` y `app_drawer.dart` con accesos a los módulos (aunque las pantallas de destino todavía estén vacías/placeholder).
- Botón de cerrar sesión funcional (limpia token, vuelve a login).
- **Checkpoint:** desde login se llega al Home, el menú lateral navega (aunque sea a pantallas en blanco todavía), y cerrar sesión regresa a login correctamente.

### Fase 4 — Módulo de Usuario
**Objetivo:** ver y editar perfil.
- Construir `perfil_screen.dart`, conectada a `GET/PUT /api/users/me`.
- Validar que `nombreUsuario` y contraseña no sean editables desde esta pantalla (mostrar solo lectura).
- **Checkpoint:** los datos del usuario logueado se muestran correctamente, se pueden editar nombre completo/teléfono, y el cambio persiste (recargar la pantalla y seguir viendo el dato nuevo).

### Fase 5 — Módulo de Ubicaciones
**Objetivo:** CRUD completo de ubicaciones, con GPS y Google Maps.
- Construir `listado_ubicaciones_screen.dart` y `formulario_ubicacion_screen.dart`.
- Integrar `geolocator` para obtener ubicación actual.
- Integrar Google Maps para selección manual de punto en el mapa.
- Implementar edición y eliminación (con confirmación, dado que borra en cascada las actividades asociadas — avisar claramente al usuario antes de confirmar).
- **Checkpoint:** se puede crear una ubicación por GPS, otra por selección manual en el mapa, editarlas, y eliminar una viendo que sus actividades (si las tuviera) también desaparecen.

### Fase 6 — Módulo de Actividades
**Objetivo:** CRUD de actividades ligadas a una ubicación, con validación de cruce de horarios y selección de condiciones climáticas deseables.
- Construir `listado_actividades_screen.dart` (filtrado por ubicación) y `formulario_actividad_screen.dart`.
- Implementar la validación: al guardar una actividad, consultar las actividades existentes de la misma ubicación y misma fecha, y rechazar si el rango `hora_inicio`–`hora_fin` se cruza con otra.
- Selector múltiple de condiciones climáticas deseables (contra el catálogo `condiciones_climaticas`), guardando en `actividad_condicion`.
- Selector de `tipo_actividad` (aire libre / interior).
- **Checkpoint:** se puede crear una actividad, intentar crear otra que se cruce en horario en la misma ubicación (debe rechazarse con un mensaje claro), y editar/eliminar actividades existentes.

### Fase 7 — Módulo de Actividades Pendientes
**Objetivo:** el módulo de mayor peso (30%), con integración de clima real y cálculo de probabilidad.
- Construir `actividades_pendientes_screen.dart`.
- Implementar `clima_service.dart` (consulta a la API de clima elegida, por coordenadas + fecha).
- Implementar `probabilidad_service.dart`: lógica que cruza `tipo_actividad` (aire libre/interior) con las `condiciones_climaticas` deseables de la actividad y el pronóstico real, para producir un indicador (ej. "Alta probabilidad", "Baja probabilidad", con un color asociado en `clima_indicator.dart`).
- Filtros por proximidad de fecha, ubicación, y probabilidad.
- Acción de marcar finalizada (inserta en `historial_actividades` y actualiza `estado`).
- Acción de reagendar (cambia `fecha`/horario, inserta también en `historial_actividades` con `estado_nuevo = 'reagendada'`).
- **Checkpoint:** la pantalla muestra actividades próximas con el clima real de su ubicación/fecha, el indicador de probabilidad cambia según el clima consultado, los filtros funcionan, y marcar finalizada/reagendar deja rastro en `historial_actividades`.

### Fase 8 — Pulido y revisión general
**Objetivo:** integración completa, sin pantallas placeholder, con manejo de errores visible al usuario (loading states, mensajes de error de red, validación de formularios).
- Revisar que todos los formularios tengan validación de campos obligatorios.
- Revisar manejo de estados de carga/error en cada pantalla que consuma red (backend, Maps, clima).
- Revisar que el logout y el manejo de token 401 funcionen en todos los flujos, no solo en login.
- **Checkpoint:** recorrido completo de la app de principio a fin (registro → login → crear ubicación → crear actividad → verla en pendientes → finalizarla) sin errores ni pantallas rotas.

### Fase 9 — Plus (fuera del alcance inmediato)
No arrancar esta fase hasta tener las fases 0–8 completas y probadas. Referencia completa en el documento `diseno_planificador_actividades.md`, sección 5 (Backlog de plus): notificaciones locales, actividades recurrentes, papelera, gráficas, favoritos, etc.

---

## 7. Qué NO debe hacer la app en esta etapa

- No implementar la sincronización cifrada con el backend (`/api/sync/*`) — esos endpoints son un stub en el servidor por ahora. La app no debe llamarlos todavía.
- No implementar ninguna de las funcionalidades "plus" de la Fase 9 antes de terminar el MVP completo.
- No guardar el JWT en SQLite ni en `shared_preferences` — siempre `flutter_secure_storage`.
- No llamar a Google Maps ni a la API de clima desde el backend — siempre directo desde la app.

---

## 8. Checklist de entrega del MVP de la app

- [ ] Fase 0 a 8 completas y probadas en orden
- [ ] Las 5 tablas SQLite creadas y funcionando con relaciones correctas
- [ ] Login, registro, recuperación y cambio de contraseña conectados al backend real
- [ ] Logout limpia el token y preserva los datos locales
- [ ] CRUD completo de ubicaciones con GPS y Google Maps
- [ ] CRUD completo de actividades con validación de cruce de horarios
- [ ] Actividades Pendientes con clima real, filtros, marcar finalizada, reagendar, e indicador de probabilidad
- [ ] Manejo de errores de red visible en cada pantalla que lo necesite
- [ ] Logo y paleta de colores aplicados de forma consistente
