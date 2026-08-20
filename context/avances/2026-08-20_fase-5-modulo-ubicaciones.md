# Avance — Fase 5: Módulo de Ubicaciones

**Fecha y hora:** 2026-08-20 13:49
**Estado:** Completada y probada (23 tests pasan; builds web y Android OK)

---

## Qué se hizo

CRUD completo de ubicaciones guardadas en SQLite local, con GPS y selección de punto "en el mapa". Como aún no hay API key de Google Maps, Maps y el selector de mapa se implementan con **mock** (`TODO` para sustituir cuando se configure `GOOGLE_MAPS_API_KEY`).

- **`services/ubicacion_service.dart` (nuevo):** CRUD local (`sqflite`) de ubicaciones. `eliminar` deja que el `ON DELETE CASCADE` borre las actividades asociadas.
- **`services/maps_service.dart` (nuevo):** autocompletar y geocodificación inversa. Con `googleMapsApiKey` vacío responde datos simulados; cuando haya key se conecta a Google Places/Geocoding.
- **`providers/ubicaciones_provider.dart` (nuevo):** carga, crear, actualizar y eliminar; recarga la lista desde la BD después de cada cambio.
- **`widgets/ubicacion_card.dart` (nuevo):** tarjeta Planazo con nombre, dirección, coordenadas y botón de eliminar.
- **`screens/ubicaciones/formulario_ubicacion_screen.dart` (nuevo):** crear y editar; campos nombre (obligatorio), dirección (opcional), latitud y longitud (validados); botones **"Usar mi ubicación"** (GPS vía `geolocator`, con fallback a mock si no hay permiso/GPS) y **"Seleccionar en mapa"** (selector mock de coordenadas).
- **`screens/ubicaciones/seleccion_mapa_screen.dart` (nuevo):** selector de punto por coordenadas; se reemplazará por un GoogleMap real cuando haya API key.
- **`screens/ubicaciones/listado_ubicaciones_screen.dart` (nuevo):** listado con estado vacío, botón de nueva ubicación y **confirmación al eliminar** avisando que se borran las actividades asociadas.
- **Integración:** `main.dart` registra `UbicacionesProvider`; `home_screen.dart` carga ubicaciones al iniciar, usa el listado real en la pestaña "Ubicaciones" y muestra el conteo real en el bento del dashboard.

### Flujo verificado (checkpoint)
Se crea una ubicación por GPS (mock), otra por selección en mapa (coordenadas), se editan y se elimina una confirmando el aviso de borrado en cascada.

---

## Archivos creados

| Archivo | Descripción |
|---|---|
| `lib/services/ubicacion_service.dart` | CRUD local de ubicaciones |
| `lib/services/maps_service.dart` | Google Maps API (mock hasta API key) |
| `lib/providers/ubicaciones_provider.dart` | Estado de ubicaciones |
| `lib/widgets/ubicacion_card.dart` | Tarjeta de ubicación |
| `lib/screens/ubicaciones/listado_ubicaciones_screen.dart` | Listado con CRUD y confirmación |
| `lib/screens/ubicaciones/formulario_ubicacion_screen.dart` | Crear/editar con GPS y mapa |
| `lib/screens/ubicaciones/seleccion_mapa_screen.dart` | Selector de punto (mock) |
| `lib/utils/date_helpers.dart` | Timestamps ISO 8601 |
| `test/ubicaciones_test.dart` | Tests del CRUD (6 casos, con BD real via sqflite ffi) |

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/main.dart` | Registro de `UbicacionesProvider` |
| `lib/screens/home/home_screen.dart` | Carga de ubicaciones al inicio; pestaña Ubicaciones real; conteo en bento |
| `lib/utils/validators.dart` | `validarLatitud` y `validarLongitud` |
| `test/navigation_test.dart` | Assertion del tab de ubicaciones (ya no es placeholder) |

## Verificación

- `flutter analyze`: 0 issues
- `flutter test`: 23 tests pasan (incluye 6 de ubicaciones con SQLite real vía `sqflite_common_ffi`)
- Build web: OK
- Build Android debug: OK

> Nota de testing: los tests de ubicaciones usan `tester.runAsync` + `databaseFactoryFfi` porque el I/O real de SQLite no avanza bajo el reloj fake de `pumpAndSettle`, y se borra el archivo de la BD entre tests para evitar contaminación.

## Siguiente fase

**Fase 6 — Módulo de Actividades:** CRUD de actividades ligadas a una ubicación, validación de cruce de horarios, selector de condiciones climáticas deseables y tipo de actividad.

---

## Actualización posterior — Integración de Google Maps API (2026-08-20)

Se obtuvo y configuró la **API key de Google Maps** (restringida a la app Android por paquete + SHA-1 del debug keystore). Con esto los mocks de maps se reemplazan por llamadas reales:

- **`.env`** y **`android/local.properties`**: `GOOGLE_MAPS_API_KEY` (ambos archivos ignorados por git; la clave no se sube al repositorio).
- **`android/app/build.gradle.kts`**: lee la key de `local.properties` y la inyecta con `manifestPlaceholders["googleMapsApiKey"]`.
- **`AndroidManifest.xml`**: meta-data `com.google.android.geo.API_KEY` con el placeholder; permisos `INTERNET`, `ACCESS_COARSE_LOCATION` y `ACCESS_FINE_LOCATION`.
- **`maps_service.dart`**: implementado Google **Geocoding inverso** (`geocode/json`) y **Places Autocomplete** (`place/autocomplete/json`) con `dio`. Sin clave, sigue respondiendo con datos simulados (útil en tests).
- **`seleccion_mapa_screen.dart`**: ahora muestra un **GoogleMap real** en Android/iOS (tap para elegir punto + marcador + dirección geocodificada). En web o sin clave, cae al formulario de coordenadas.
- **`formulario_ubicacion_screen.dart`**: al elegir un punto en el mapa, autocompleta la dirección con geocoding inverso.
- **`constants.dart`**: lectura de variables de entorno robusta (no lanza si dotenv no está inicializado, p. ej. en tests).

### Verificación
- La key respondió `REQUEST_DENIED` a una consulta directa desde el servidor (correcto: está restringida solo a la app Android).
- Manifest final del build contiene la key inyectada.
- `flutter analyze` 0 issues; 23 tests pasan (en tests la clave está vacía → se usa el mock); builds web y Android OK.
- Falta probar el mapa en dispositivo físico (comando: `flutter run` en el SM-S908U1).

> Pendiente para la Fase 7 (clima): Google no ofrece una API de clima general; se necesitará una key de **OpenWeatherMap** o **WeatherAPI.com** en `WEATHER_API_KEY`.
