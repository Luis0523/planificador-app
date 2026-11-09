# 📅 Planificador de Actividades

Aplicación móvil desarrollada en **Flutter** para la planificación inteligente de actividades recreativas y al aire libre, evaluando condiciones meteorológicas en tiempo real y calculando la viabilidad mediante un motor de reglas y probabilidad.

---

## 🏛️ Arquitectura del Sistema (Documentada con Archify)

Este proyecto cuenta con diagramas interactivos y verificables generados con **[Archify](https://github.com/tt-a1i/archify)** en formato HTML autocontenido (con soporte para modo claro/oscuro, trazado de rutas, historias guiadas y exportación de imágenes):

| Diagrama | Tipo | Descripción | Enlace Interactivo |
|---|---|---|---|
| **Arquitectura General** | `Architecture` | Mapa de capas: Presentación (UI), Estado (`Provider`), Servicios de Dominio, Persistencia SQLite / SecureStorage e Integraciones Externas. | [Abrir Mapa Interactivo](./docs/architecture/system-architecture.html) |
| **Evaluación de Clima & Probabilidad** | `Workflow` | Flujo paso a paso desde la selección de la actividad, consulta meteorológica, evaluación de umbrales hasta la recomendación visual. | [Abrir Flujo de Viabilidad](./docs/architecture/weather-probability.workflow.html) |
| **Autenticación & Persistencia** | `Sequence` | Secuencia de inicio de sesión, validación de token JWT, cifrado en KeyStore/Keychain y carga de base de datos local. | [Abrir Secuencia de Auth](./docs/architecture/auth-flow.sequence.html) |

> 💡 **Cómo abrir los diagramas:** Puedes abrir cualquiera de los archivos `.html` dentro de `docs/architecture/` directamente en tu navegador web.

---

## 🚀 Características Principales

- **Login contra API:** credenciales validadas en el backend desplegado; el JWT se guarda con `flutter_secure_storage` (nunca en SQLite).
- **Módulo de usuario:** perfil con edición de nombre y teléfono; usuario y contraseña en solo lectura; recuperación de contraseña y cambio obligatorio cuando es temporal.
- **Ubicaciones:** GPS del teléfono o selección de punto en Google Maps; coordenadas guardadas en SQLite; edición y borrado en cascada.
- **Actividades:** CRUD por ubicación, tipo aire libre/interior, condiciones climáticas deseadas y validación de cruces de horario.
- **Actividades pendientes:** clima real de la hora y ubicación, probabilidad Alta/Media/Baja con porcentaje, filtros por fecha, ubicación y probabilidad, finalizar y reagendar con historial.
- **Persistencia local:** SQLite (`sqflite`) con `ubicaciones`, `actividades`, `condiciones_climaticas`, `actividad_condicion` e `historial_actividades`.

---

## 📂 Estructura del Código

```text
lib/
├── config/             # Configuración global, temas y constantes
├── database/           # SQLite: un solo DatabaseHelper con todas las tablas
├── models/             # Modelos de datos (Actividad, CondicionClimatica, Ubicacion, Usuario)
├── providers/          # Estado con Provider (auth, ubicaciones, actividades, pendientes)
├── screens/            # Pantallas de la UI organizadas por módulo
│   ├── auth/           # Login, Registro, Recuperación de contraseña
│   ├── home/           # Pantalla principal con resumen y accesos rápidos
│   ├── actividades/    # Listado y formularios de actividades
│   ├── ubicaciones/    # Gestión y selección en mapa
│   └── usuario/        # Perfil y ajustes
├── services/           # Lógica de negocio (auth, clima, mapas, probabilidad, CRUD local)
└── utils/              # Funciones auxiliares y formateadores
```

---

## 🛠️ Regenerar o Actualizar los Diagramas con Archify

Para actualizar los diagramas de arquitectura tras cambios en el código:

```bash
# Validar y compilar arquitectura general
node ~/.agents/skills/archify/bin/archify.mjs deliver architecture docs/architecture/system-architecture.json docs/architecture/system-architecture.html --quality showcase

# Validar y compilar flujo de probabilidad
node ~/.agents/skills/archify/bin/archify.mjs deliver workflow docs/architecture/weather-probability.workflow.json docs/architecture/weather-probability.workflow.html --quality showcase

# Validar y compilar flujo de autenticación
node ~/.agents/skills/archify/bin/archify.mjs deliver sequence docs/architecture/auth-flow.sequence.json docs/architecture/auth-flow.sequence.html --quality showcase
```

---

## ✅ Correspondencia con el enunciado

| Requisito | Implementación |
|---|---|
| 1. Login con API y menú lateral | `screens/auth/login_screen.dart`, `providers/auth_provider.dart`, `screens/home/home_screen.dart`, `widgets/app_drawer.dart` |
| 1c. Logo y paleta | `config/theme.dart` (paleta Planazo) + logo/ícono en login y home |
| 2. Perfil, recuperación y cambio obligatorio | `screens/usuario/perfil_screen.dart`, `screens/auth/recuperar_contrasena_screen.dart`, `screens/auth/cambiar_contrasena_screen.dart` |
| 3. Ubicaciones con GPS/Google Maps y cascada | `screens/ubicaciones/`, `services/maps_service.dart`, `database/database_helper.dart` |
| 4. Actividades, cruces y condiciones | `screens/actividades/`, `services/actividad_service.dart` |
| 5. Pendientes, clima, filtros, finalizar y reagendar | `screens/actividades_pendientes/`, `providers/actividades_pendientes_provider.dart`, `services/clima_service.dart`, `services/probabilidad_service.dart` |

> **Nota sobre el clima:** Google no ofrece una API pública de clima gratuita para este uso, por lo que se utiliza OpenWeatherMap (plan gratuito), consultada directo desde el teléfono. El resto de requisitos de mapas sí usa Google Maps.

---

## ▶️ Ejecución del Proyecto

1. Clona el repositorio e instala las dependencias:
   ```bash
   flutter pub get
   ```
2. Configura las variables de entorno en `.env` (API Keys de Google Maps y OpenWeather).
3. Ejecuta la aplicación en tu emulador o dispositivo:
   ```bash
   flutter run
   ```
