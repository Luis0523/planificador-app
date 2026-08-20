import '../models/usuario.dart';

/// TODO: eliminar cuando esté desplegado el backend real
/// (`Constants.useMockBackend = false`). Simula el backend de auth/perfil
/// en memoria para que la app funcione sin servidor.
class MockBackend {
  MockBackend._();
  static final MockBackend instance = MockBackend._();

  final List<Map<String, String>> _usuarios = [
    {
      'id': '1',
      'nombreCompleto': 'Alumno Demo',
      'nombreUsuario': 'demo',
      'correo': 'demo@planificador.com',
      'telefono': '5551234567',
      'contrasena': '123456',
    },
  ];

  String _usuarioActualId = '1';

  /// Restaura el estado inicial (útil en tests).
  void reset() {
    _usuarios
      ..clear()
      ..addAll([
        {
          'id': '1',
          'nombreCompleto': 'Alumno Demo',
          'nombreUsuario': 'demo',
          'correo': 'demo@planificador.com',
          'telefono': '5551234567',
          'contrasena': '123456',
        },
      ]);
    _usuarioActualId = '1';
  }

  Map<String, String> get usuarioActual {
    return _usuarios.firstWhere(
      (u) => u['id'] == _usuarioActualId,
      orElse: () => _usuarios.first,
    );
  }

  void setUsuarioActualId(String id) => _usuarioActualId = id;

  Map<String, String>? buscarPorCorreo(String correo) {
    final matches =
        _usuarios.where((u) => u['correo'] == correo.trim()).toList();
    return matches.isEmpty ? null : matches.first;
  }

  Map<String, String>? buscarPorNombreUsuario(String nombreUsuario) {
    final matches = _usuarios
        .where((u) => u['nombreUsuario'] == nombreUsuario.trim())
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  void registrar({
    required String nombreCompleto,
    required String nombreUsuario,
    required String correo,
    required String telefono,
    required String contrasena,
  }) {
    _usuarios.add({
      'id': (_usuarios.length + 1).toString(),
      'nombreCompleto': nombreCompleto.trim(),
      'nombreUsuario': nombreUsuario.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'contrasena': contrasena,
    });
  }

  Usuario perfilActual() {
    final u = usuarioActual;
    return Usuario(
      id: int.parse(u['id']!),
      nombreUsuario: u['nombreUsuario']!,
      nombreCompleto: u['nombreCompleto']!,
      correo: u['correo']!,
      telefono: u['telefono']!,
    );
  }

  Usuario actualizarPerfil({
    required String nombreCompleto,
    required String telefono,
  }) {
    final u = usuarioActual;
    u['nombreCompleto'] = nombreCompleto.trim();
    u['telefono'] = telefono.trim();
    return perfilActual();
  }
}
