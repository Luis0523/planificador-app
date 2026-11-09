# Guía para explicar el proyecto: Planificador de Actividades

Esta guía está pensada para que puedas defender el código sin memorizar archivo por archivo. Primero entiendes el flujo general y después cada módulo con su lógica, su archivo y un fragmento clave.

**Orden recomendado para estudiar (5 pasos):**

1. Lee la idea en 30 segundos y la regla de arquitectura.
2. Aprende el flujo de login y el de SQLite.
3. Estudia ubicaciones y actividades con sus fragmentos.
4. Entiende clima y probabilidad (es lo que más preguntan).
5. Repasa la chuleta final y las preguntas de defensa.

**Contenido**

1. Idea general
2. Mapa de archivos
3. Arranque y navegación
4. Login, backend y token
5. SQLite en el teléfono
6. Módulo de ubicaciones
7. Módulo de actividades
8. API del clima
9. Lógica de probabilidad
10. Módulo de Actividades Pendientes
11. Perfil y contraseñas
12. Seguridad
13. Preguntas típicas de defensa
14. Chuleta final
15. Comandos para probar

---

## 1. La idea en 30 segundos

La app hace cuatro cosas:

1. **Login** contra un backend por API.
2. Guarda **ubicaciones** en SQLite dentro del teléfono (con GPS o Google Maps).
3. Guarda **actividades** asociadas a esas ubicaciones, validando que no se crucen.
4. En **Actividades Pendientes**, consulta el clima real de la ubicación y la hora, calcula una probabilidad y permite finalizar o reagendar.

La regla de oro de la arquitectura es:

```
Pantalla (UI) -> Provider (estado) -> Service (lógica) -> SQLite o API
```

- La **pantalla** solo muestra datos y captura acciones.
- El **Provider** guarda el estado y avisa a la UI cuando cambia.
- El **Service** hace el trabajo real: consultar, guardar, validar.
- Al final, los datos van a **SQLite** (local) o a una **API** (internet).

**Tip para memorizar:** “La UI pide, el Provider piensa, el Service ejecuta y la base de datos o la API guardan.”

---

## 2. Mapa de archivos que debes ubicar

| Qué quieres explicar | Archivo principal |
|---|---|
| Arranque de la app y decisión de pantalla | `lib/main.dart` |
| Login, logout y estado de sesión | `lib/providers/auth_provider.dart` |
| Llamadas al backend de login/registro | `lib/services/auth_service.dart` |
| Cliente HTTP, token y errores | `lib/services/api_service.dart` |
| Base de datos SQLite y tablas | `lib/database/database_helper.dart` |
| CRUD de ubicaciones | `lib/services/ubicacion_service.dart` |
| CRUD de actividades y cruces | `lib/services/actividad_service.dart` |
| GPS y selección en mapa | `lib/screens/ubicaciones/formulario_ubicacion_screen.dart`, `seleccion_mapa_screen.dart` |
| Geocodificación de Google Maps | `lib/services/maps_service.dart` |
| Clima real | `lib/services/clima_service.dart` |
| Lógica de probabilidad | `lib/services/probabilidad_service.dart` |
| Módulo de pendientes | `lib/providers/actividades_pendientes_provider.dart` y `lib/screens/actividades_pendientes/actividades_pendientes_screen.dart` |
| Perfil del usuario | `lib/screens/usuario/perfil_screen.dart` y `lib/services/usuario_service.dart` |
| Navegación y menú | `lib/screens/home/home_screen.dart` y `lib/widgets/app_drawer.dart` |

---

## 3. Arranque y navegación

### Qué pasa al abrir la app

`lib/main.dart` hace tres cosas antes de mostrar la interfaz:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await dotenv.load(fileName: '.env');
  runApp(const PlanificadorApp());
}
```

- `initializeDateFormatting('es')` prepara las fechas en español.
- `dotenv.load` lee `.env`, donde están la URL del backend y las API keys.
- Luego se registran los cuatro Providers y se muestra `AuthGate`.

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => UbicacionesProvider()),
    ChangeNotifierProvider(create: (_) => ActividadesProvider()),
    ChangeNotifierProvider(create: (_) => ActividadesPendientesProvider()),
  ],
  child: MaterialApp(home: const AuthGate()),
)
```

### El portero: AuthGate

`AuthGate` decide qué pantalla mostrar según el estado de autenticación:

```dart
switch (auth.status) {
  case AuthStatus.desconocido:
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  case AuthStatus.noAutenticado:
    return const LoginScreen();
  case AuthStatus.requiereCambio:
    return const CambiarContrasenaScreen();
  case AuthStatus.autenticado:
    return const HomeScreen();
}
```

Estados posibles: `desconocido`, `noAutenticado`, `requiereCambio`, `autenticado`.

**Tip para memorizar:** “AuthGate es un switch gigante: sin sesión -> login; contraseña temporal -> cambio; sesión lista -> Home.”

### Home y navegación

`lib/screens/home/home_screen.dart` usa:

- Un `Scaffold` con `AppBar` y menú lateral (`AppDrawer`).
- Un `IndexedStack` para conservar el estado de las secciones.
- Una barra inferior con Inicio, Actividades y Pendientes.
- Un botón flotante `+` para crear una actividad.

`IndexedStack` mantiene vivas las cuatro pantallas internas. Por eso al cambiar de pestaña no se pierde el estado.

**Tip para memorizar:** “Home es un contenedor; las pantallas reales viven dentro del IndexedStack.”

---

## 4. Login, backend y token

### Flujo completo del login

```
LoginScreen
  -> AuthProvider.login()
  -> AuthService.login()
  -> ApiService.dio.post('/api/auth/login')
  -> backend responde { token, usuario, requiereCambioContrasena }
  -> token se guarda en flutter_secure_storage
  -> AuthProvider cambia el estado
  -> AuthGate muestra Home o CambiarContrasenaScreen
```

### Fragmento clave: login en AuthService

**Archivo:** `lib/services/auth_service.dart:42`

```dart
final res = await _api.dio.post(
  Constants.authLogin,
  data: {'correo': correo, 'contrasena': contrasena},
);

final body = res.data as Map<String, dynamic>;
return LoginResult(
  token: body['token'] as String,
  usuario: Usuario.fromMap(body['usuario'] as Map<String, dynamic>),
  requiereCambioContrasena: body['requiereCambioContrasena'] as bool,
);
```

El backend recibe correo y contraseña, valida contra su base de datos y devuelve un **JWT** (token) junto con los datos del usuario.

### Endpoints del backend

| Método | Ruta | Uso |
|---|---|---|
| POST | `/api/auth/login` | Iniciar sesión |
| POST | `/api/auth/register` | Registrarse |
| POST | `/api/auth/forgot-password` | Recuperar contraseña |
| POST | `/api/auth/change-password` | Cambiar contraseña temporal |
| GET | `/api/users/me` | Ver perfil |
| PUT | `/api/users/me` | Editar nombre y teléfono |

**Importante:** la app **no guarda la contraseña**. La envía por HTTPS y el backend se encarga de compararla con su hash. La app solo guarda el JWT.

### Dónde vive el token

**Archivo:** `lib/services/api_service.dart:28`

```dart
static Future<void> guardarToken(String token) =>
    _storage.write(key: Constants.storageKeyJwt, value: token);

static Future<String?> leerToken() =>
    _storage.read(key: Constants.storageKeyJwt);
```

Se usa `flutter_secure_storage`, que en Android usa el KeyStore y en iOS el Keychain. No se guarda en SQLite ni en `shared_preferences`.

### Cómo se envía el token en cada petición

**Archivo:** `lib/services/api_service.dart:82`

```dart
final token = await ApiService.leerToken();
if (token != null && token.isNotEmpty) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

Es un **interceptor**: se ejecuta antes de cada request y agrega el header automáticamente.

### Si el token ya no sirve

**Archivo:** `lib/services/api_service.dart:96`

```dart
if (err.response?.statusCode == 401) {
  await ApiService.limpiarSesion();
}
```

Si el servidor responde 401, se borra la sesión. Al abrir la app, `AuthProvider._init()` valida el token llamando a `/users/me`; si falla, manda al login.

### Contraseña temporal

1. El usuario pide recuperación en `RecuperarContrasenaScreen`.
2. El backend genera una contraseña temporal y la envía al correo.
3. Al iniciar sesión con esa contraseña, el backend responde `requiereCambioContrasena: true`.
4. La app guarda esa marca en `flutter_secure_storage`.
5. `AuthGate` muestra `CambiarContrasenaScreen`.
6. Al cambiarla con doble confirmación, la marca se borra.

**Tip para memorizar:** “El login no guarda contraseñas: guarda un token. El token es la llave temporal de la sesión.”

---

## 5. SQLite en el teléfono

### Por qué SQLite

Las ubicaciones, actividades, condiciones e historial son datos del planificador y se guardan **localmente** en el teléfono con `sqflite`. Así la app funciona sin depender del backend para el CRUD. El backend solo maneja usuarios, login y perfil.

### El singleton de la base

**Archivo:** `lib/database/database_helper.dart:11`

```dart
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
}
```

Se usa una sola instancia para no abrir la base varias veces. El `??=` significa: “si no existe, créala; si ya existe, reutilízala”.

### Las cinco tablas

| Tabla | Para qué |
|---|---|
| `ubicaciones` | Lugares del usuario con latitud y longitud |
| `actividades` | Actividades de cada ubicación |
| `condiciones_climaticas` | Catálogo fijo: Soleado, Lluvioso, Nublado, Ventoso, Templado, Nevado |
| `actividad_condicion` | Relación muchos-a-muchos entre actividad y condiciones deseadas |
| `historial_actividades` | Cambios de estado: finalizada o reagendada |

### Relaciones y borrado en cascada

```sql
FOREIGN KEY (id_ubicacion)
  REFERENCES ubicaciones (id_ubicacion)
  ON DELETE CASCADE
```

Significa: si borras una ubicación, SQLite borra automáticamente sus actividades. Si borras una actividad, se borran sus condiciones y su historial.

Para que esto funcione hay que activar las llaves foráneas en cada conexión:

```dart
Future<void> _onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}
```

**Tip para memorizar:** “Ubicación manda: si se va la ubicación, se van sus actividades; si se va la actividad, se va su historial.”

### Operaciones genéricas

`DatabaseHelper` tiene `insert`, `update`, `delete`, `query` y `rawQuery`. Los services usan esos métodos. Por ejemplo, listar ubicaciones de un usuario:

**Archivo:** `lib/services/ubicacion_service.dart:13`

```dart
final filas = await DatabaseHelper.instance.query(
  Constants.tableUbicaciones,
  where: 'id_usuario = ?',
  whereArgs: [idUsuario],
  orderBy: 'fecha_creacion DESC',
);
return filas.map(Ubicacion.fromMap).toList();
```

El `?` evita inyección SQL y el `id_usuario` aísla los datos: cada usuario ve solo sus ubicaciones.

### Aislamiento por usuario

La tabla `ubicaciones` guarda `id_usuario` (el UUID que devuelve el backend). Todas las consultas de ubicaciones filtran por ese id. Las actividades se cargan a partir de las ubicaciones del usuario, así que también quedan aisladas.

**Tip para memorizar:** “SQLite es la libreta local; el id_usuario es el nombre en la portada para que nadie vea la libreta de otro.”

---

## 6. Módulo de ubicaciones

### Dos formas de obtener una ubicación

**Archivo:** `lib/screens/ubicaciones/formulario_ubicacion_screen.dart:62`

1. **GPS del teléfono** con `geolocator`:

```dart
var permiso = await Geolocator.checkPermission();
if (permiso == LocationPermission.denied) {
  permiso = await Geolocator.requestPermission();
}

final pos = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  ),
);

_setCoordenadas(pos.latitude, pos.longitude);
```

2. **Selección en Google Maps** con `google_maps_flutter`. La pantalla `SeleccionMapaScreen` devuelve una tupla `(latitud, longitud)`.

Después de obtener el punto, se llama a Google Geocoding para autocompletar la dirección:

**Archivo:** `lib/services/maps_service.dart:20`

```dart
final res = await _dio.get(
  'https://maps.googleapis.com/maps/api/geocode/json',
  queryParameters: {
    'latlng': '$latitud,$longitud',
    'key': Constants.googleMapsApiKey,
  },
);
```

### Qué se guarda

**Archivo:** `lib/screens/ubicaciones/formulario_ubicacion_screen.dart:137`

```dart
final ubicacion = Ubicacion(
  idUbicacion: _editando ? widget.ubicacion!.idUbicacion : null,
  idUsuario: usuario.id,
  nombre: _nombreCtrl.text.trim(),
  direccion: _direccionCtrl.text.trim().isEmpty
      ? null
      : _direccionCtrl.text.trim(),
  latitud: _latitud!,
  longitud: _longitud!,
  fechaCreacion: _editando ? widget.ubicacion!.fechaCreacion : ahora,
  fechaActualizacion: ahora,
);
```

Las coordenadas se guardan como `REAL` en la tabla `ubicaciones`. Son obligatorias.

### Eliminación en cascada

El listado pregunta antes de borrar y avisa que también se borrarán las actividades. No hay que borrar las actividades manualmente: lo hace SQLite con `ON DELETE CASCADE`.

**Tip para memorizar:** “Ubicación = nombre + dirección + latitud + longitud. El resto se cae solo si borro la ubicación.”

---

## 7. Módulo de actividades

### Qué guarda una actividad

- `id_ubicacion`: a qué lugar pertenece.
- `descripcion`: nombre de la actividad.
- `fecha`: `YYYY-MM-DD`.
- `hora_inicio` y `hora_fin`: `HH:mm`.
- `tipo_actividad`: `aire_libre` o `interior`.
- `estado`: `pendiente`, `finalizada` o `reagendada`.
- Condiciones deseadas: se guardan aparte en `actividad_condicion`.

### Validación de cruce de horarios

**Archivo:** `lib/services/actividad_service.dart:66`

```dart
final filas = await DatabaseHelper.instance.query(
  Constants.tableActividades,
  where: 'id_ubicacion = ? AND fecha = ? AND id_actividad != ?',
  whereArgs: [idUbicacion, fecha, idExcluida ?? -1],
);

for (final fila in filas) {
  final otra = Actividad.fromMap(fila);
  if (seCruzan(horaInicio, horaFin, otra.horaInicio, otra.horaFin)) {
    return otra;
  }
}
```

La regla matemática del cruce es:

```dart
static bool seCruzan(String s1, String e1, String s2, String e2) =>
    s1.compareTo(e2) < 0 && s2.compareTo(e1) < 0;
```

Se lee así: “empiezo antes de que la otra termine **y** la otra empieza antes de que yo termine”. Si una termina justo cuando la otra empieza, no se cruzan.

### Dónde se aplica

**Archivo:** `lib/providers/actividades_provider.dart:52`

```dart
final conflicto = await _service.obtenerActividadEnConflicto(
  idUbicacion: actividad.idUbicacion,
  fecha: actividad.fecha,
  horaInicio: actividad.horaInicio,
  horaFin: actividad.horaFin,
);

if (conflicto != null) {
  _error = _mensajeConflicto(conflicto);
  return false;
}
```

Se valida al **crear**, al **editar** (excluyendo la propia actividad) y también al **reagendar**.

### Condiciones deseadas: relación N:M

Una actividad puede tener varias condiciones y una condición puede estar en varias actividades. Por eso existe la tabla intermedia `actividad_condicion`.

**Archivo:** `lib/services/actividad_service.dart:108`

```dart
batch.delete(
  Constants.tableActividadCondicion,
  where: 'id_actividad = ?',
  whereArgs: [idActividad],
);

for (final id in idCondiciones) {
  batch.insert(Constants.tableActividadCondicion, {
    'id_actividad': idActividad,
    'id_condicion': id,
  });
}
```

Primero borra las condiciones anteriores y luego inserta las nuevas. Es una forma sencilla de “reemplazar” la selección.

**Tip para memorizar:** “Dos actividades chocan si sus rangos se montan. Para condiciones: actividad y condición van a una tabla intermedia.”

---

## 8. API del clima

### Qué se consulta

**Archivo:** `lib/services/clima_service.dart:130`

```dart
final res = await _dio.get(
  '$_baseUrl/forecast',
  queryParameters: {
    'lat': latitud,
    'lon': longitud,
    'appid': Constants.weatherApiKey,
    'units': 'metric',
    'lang': 'es',
  },
);
```

Se usa **OpenWeatherMap**, endpoint `/forecast`, que devuelve puntos cada 3 horas durante 5 días. Se consulta directo desde el teléfono, nunca desde el backend.

### Cómo se elige el clima de una actividad

**Archivo:** `lib/services/clima_service.dart:105`

```dart
final puntos = await _consultarPronostico(latitud, longitud);
if (puntos.isEmpty) {
  throw ClimaException('El pronóstico no tiene datos para esa fecha.');
}
return _masCercano(puntos, fecha);
```

`_masCercano` recorre todos los puntos y elige el que tenga la menor diferencia con la fecha y hora de la actividad. Por eso en Pendientes se combina fecha + hora de inicio.

### Cómo se traduce la condición

**Archivo:** `lib/services/clima_service.dart:54`

```dart
if (viento >= 10.8) return 'Ventoso';

switch (clima) {
  case 'Rain':
  case 'Drizzle':
  case 'Thunderstorm':
    return 'Lluvioso';
  case 'Snow':
  case 'Sleet':
    return 'Nevado';
  case 'Clear':
    return 'Soleado';
  case 'Clouds':
    return 'Nublado';
}
```

OpenWeather devuelve condiciones en inglés; la app las traduce al catálogo local para que coincidan con las condiciones deseadas del usuario.

### La gráfica del día

**Archivo:** `lib/widgets/clima_dia_chart.dart`

- El eje X muestra las horas de los puntos disponibles.
- El eje Y muestra la temperatura en °C.
- Cada punto tiene el color y el ícono de su condición.
- Debajo de cada hora se muestra el ícono: sol, nube, lluvia, etc.
- Solo aparecen las horas que todavía devuelve el pronóstico. Si es hoy y ya pasó la mañana, verás solo las horas restantes.

**Tip para memorizar:** “Coordenadas + fecha/hora -> forecast -> punto más cercano -> condición traducida al catálogo.”

---

## 9. Lógica de probabilidad

**Archivo:** `lib/services/probabilidad_service.dart:55`

### Las cuatro reglas

```dart
if (condicionesDeseables.contains(condicionReal)) {
  return ProbabilidadNivel.alta;
}

final esAireLibre = tipoActividad == 'aire_libre';
if (!esAireLibre) {
  return ProbabilidadNivel.media;
}

if (_condicionesAdversas.contains(condicionReal)) {
  return ProbabilidadNivel.baja;
}

return ProbabilidadNivel.media;
```

| Caso | Resultado |
|---|---|
| La condición real está entre las deseadas | Alta |
| Es interior (no le afecta tanto el clima) | Media |
| Es aire libre y hay Lluvioso, Nevado o Ventoso | Baja |
| Es aire libre y la condición no es adversa | Media |

### Porcentajes

```dart
int get porcentaje => switch (this) {
  alta => 85,
  media => 50,
  baja => 20,
};
```

El porcentaje es una forma sencilla de mostrar el nivel. No es un modelo estadístico: es una regla de negocio.

### Ejemplo para explicar

- Actividad al aire libre, clima Soleado y el usuario marcó Soleado -> Alta (85%).
- Actividad al aire libre, clima Lluvioso y no marcó Lluvioso -> Baja (20%).
- Actividad interior, clima Lluvioso -> Media (50%), porque la lluvia no impide hacerla dentro.

**Tip para memorizar:** “Deseada = Alta; interior = Media; al aire libre con lluvia/nieve/viento = Baja; lo demás = Media.”

---

## 10. Módulo de Actividades Pendientes

**Archivo principal:** `lib/providers/actividades_pendientes_provider.dart`

### Flujo de carga, paso a paso

```dart
// 1. Ubicaciones del usuario
final ubicaciones = await _ubicacionService.listar(idUsuario);

// 2. Actividades pendientes o reagendadas de hoy en adelante
final actividades = await _actividadService.listarPendientes(
  ubicaciones.map((u) => u.idUbicacion!).toList(),
);

// 3. Catálogo de condiciones
final catalogoCondiciones = await _actividadService.listarCondiciones();

// 4. Para cada actividad: condiciones deseadas + clima + probabilidad
clima = await _climaService.obtenerClima(
  latitud: ubicacion.latitud,
  longitud: ubicacion.longitud,
  fecha: _fechaHora(actividad),
);

final probabilidad = _probabilidadService.calcular(
  tipoActividad: actividad.tipoActividad,
  condicionesDeseables: nombresDeseables,
  condicionReal: clima?.condicion ?? 'Nublado',
);
```

El resultado de cada actividad se guarda en un `ActividadConClima`, que agrupa:

- la actividad,
- su ubicación,
- sus condiciones deseadas,
- el clima consultado,
- el error de clima si falló,
- la probabilidad calculada.

### Filtros

**Archivo:** `lib/providers/actividades_pendientes_provider.dart:59`

- Por **ubicación**: compara `ubicacion.idUbicacion`.
- Por **probabilidad**: compara con `ProbabilidadNivel`.
- Por **proximidad de fecha**: muestra solo los próximos 7 días.

Los filtros se aplican sobre la lista ya cargada, sin volver a consultar la base de datos.

### Finalizar una actividad

1. La pantalla pide confirmación.
2. El provider llama a `ActividadService.marcarFinalizada()`.
3. El service hace una transacción: actualiza el estado a `finalizada` e inserta un registro en `historial_actividades`.
4. Se recarga la lista.

### Reagendar una actividad

1. La pantalla pide nueva fecha, hora de inicio y hora de fin.
2. Se valida que la hora de fin sea mayor que la de inicio.
3. El provider valida que no se cruce con otra actividad.
4. El service actualiza fecha, horas y estado a `reagendada`, y guarda el historial.
5. Se recarga la lista.

**Tip para memorizar:** “Pendientes = ubicaciones -> actividades futuras -> clima -> probabilidad -> filtros -> finalizar o reagendar.”

---

## 11. Perfil y contraseñas

### Ver y editar el perfil

**Archivo:** `lib/services/usuario_service.dart:18`

```dart
final res = await _api.dio.get(Constants.usersMe);
return Usuario.fromMap(_desenvolver(res.data));
```

El backend responde `{ usuario: { ... } }`; `_desenvolver` saca el objeto interno.

Para editar:

**Archivo:** `lib/services/usuario_service.dart:30`

```dart
final res = await _api.dio.put(
  Constants.usersMe,
  data: {'nombreCompleto': nombreCompleto, 'telefono': telefono},
);
```

Nunca se envía `nombreUsuario` ni contraseña. En la pantalla, usuario y contraseña se muestran como campos deshabilitados (solo lectura).

### Recuperación de contraseña

**Archivo:** `lib/services/auth_service.dart:96`

```dart
await _api.dio.post(Constants.authForgotPassword, data: {'correo': correo});
```

El backend responde siempre con un mensaje genérico para no revelar si el correo existe.

### Cambio de contraseña temporal

**Archivo:** `lib/services/auth_service.dart:113`

```dart
await _api.dio.post(
  Constants.authChangePassword,
  data: {
    'nuevaContrasena': nuevaContrasena,
    'confirmarContrasena': confirmarContrasena,
  },
);
```

La app valida primero que ambas contraseñas coincidan y que tengan al menos 8 caracteres. Después del cambio exitoso, se quita la marca de “requiere cambio”.

**Tip para memorizar:** “Perfil: GET y PUT a /users/me, sin tocar usuario ni contraseña. Recuperación: correo -> temporal -> cambio obligatorio.”

---

## 12. Seguridad: qué debes decir si te preguntan

- La contraseña **no se guarda** en el teléfono.
- Viaja por **HTTPS** hasta el backend.
- El backend guarda la contraseña **hasheada** en su base de datos.
- La app guarda solo el **JWT** en `flutter_secure_storage`.
- El JWT se adjunta como `Authorization: Bearer <token>`.
- Si el servidor responde **401**, se borra la sesión.
- Al cerrar sesión se borra el token, pero **no** se borra SQLite: las ubicaciones y actividades siguen en el teléfono.
- SQLite guarda datos del planificador, no credenciales.

**Tip para memorizar:** “Contraseña no se guarda; token sí, pero cifrado; SQLite es solo para los planes.”

---

## 13. Preguntas típicas de defensa

**¿Dónde se valida el login?**
En el backend, por API. La app envía correo y contraseña a `/api/auth/login`.

**¿Dónde se guarda el token?**
En `flutter_secure_storage`, no en SQLite.

**¿Qué pasa si cierro sesión?**
Se borra el token y la marca de cambio de contraseña; SQLite se conserva.

**¿Cómo se aíslan los datos de cada usuario?**
Cada ubicación guarda `id_usuario`; las consultas filtran por ese id.

**¿Cómo se evita que dos actividades se crucen?**
Con `seCruzan`: `s1 < e2 && s2 < e1`. Se valida al crear, editar y reagendar.

**¿Cómo se guardan las condiciones deseadas?**
En la tabla intermedia `actividad_condicion`, relación muchos-a-muchos.

**¿Qué pasa si borro una ubicación?**
Se borran sus actividades, y de esas actividades se borran sus condiciones e historial, por `ON DELETE CASCADE`.

**¿Cómo se calcula la probabilidad?**
Con cuatro reglas: deseada -> Alta; interior -> Media; aire libre con clima adverso -> Baja; resto -> Media.

**¿De dónde sale el clima?**
De OpenWeatherMap, endpoint `/forecast`, usando latitud, longitud y la fecha/hora de la actividad. Se consulta directo desde el teléfono.

**¿Por qué no se usa Google para el clima?**
Google no ofrece una API pública de clima gratuita para este caso. Se documentó el cambio a OpenWeatherMap.

**¿Qué pasa si no hay internet?**
El CRUD local sigue funcionando porque está en SQLite. El clima muestra error en la tarjeta, pero no bloquea la app.

**¿Por qué hay un MockBackend?**
Solo para pruebas automáticas. En producción `USE_MOCK_BACKEND=false` y se usa el backend real.

**¿Dónde está la lógica de probabilidad?**
En `lib/services/probabilidad_service.dart`.

**¿Dónde está la lógica de cruces?**
En `lib/services/actividad_service.dart`, método `seCruzan` y `obtenerActividadEnConflicto`.

**¿Dónde se guardan las coordenadas?**
En la tabla `ubicaciones`, columnas `latitud` y `longitud`, tipo `REAL`.

---

## 14. Chuleta final para memorizar

1. **Arquitectura:** UI -> Provider -> Service -> SQLite/API.
2. **Login:** pantalla -> provider -> service -> Dio -> API -> token -> SecureStorage -> AuthGate.
3. **SQLite:** `DatabaseHelper` abre la base y crea 5 tablas; `PRAGMA foreign_keys = ON` activa la cascada.
4. **Ubicaciones:** GPS o mapa -> latitud/longitud -> tabla `ubicaciones` -> borrar ubicación borra actividades.
5. **Actividades:** ubicación + fecha + horas + tipo + condiciones -> validar cruce -> guardar.
6. **Clima:** latitud/longitud + fecha/hora -> OpenWeather `/forecast` -> punto más cercano -> condición.
7. **Probabilidad:** deseada Alta, interior Media, aire libre con clima adverso Baja, resto Media.
8. **Pendientes:** ubicaciones -> actividades futuras -> clima -> probabilidad -> filtros -> finalizar/reagendar.
9. **Perfil:** GET/PUT `/users/me`; usuario y contraseña no editables.
10. **Seguridad:** contraseña no se guarda; token en SecureStorage; 401 borra sesión.

---

## 15. Comandos para probar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

El APK de depuración queda en:

```
build/app/outputs/flutter-apk/app-debug.apk
```
