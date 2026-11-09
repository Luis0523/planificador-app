import 'package:flutter_test/flutter_test.dart';

import 'package:planificador_actividades/models/usuario.dart';

void main() {
  test('parsea el objeto usuario del backend (idUsuario UUID)', () {
    final u = Usuario.fromMap(const {
      'idUsuario': '58172ec3-1128-45d3-8837-b712dc18b387',
      'nombreUsuario': 'prueba',
      'nombreCompleto': 'Usuario Prueba',
      'correo': 'prueba@ejemplo.com',
      'rol': 'usuario',
    });

    expect(u.id, '58172ec3-1128-45d3-8837-b712dc18b387');
    expect(u.nombreUsuario, 'prueba');
    expect(u.correo, 'prueba@ejemplo.com');
    // En login no viene telefono ni requiereCambioContrasena: valores por defecto.
    expect(u.telefono, '');
    expect(u.requiereCambioContrasena, isFalse);
  });

  test('incluye telefono cuando viene en la respuesta', () {
    final u = Usuario.fromMap(const {
      'idUsuario': 'uuid-123',
      'nombreUsuario': 'prueba',
      'nombreCompleto': 'Usuario Prueba',
      'correo': 'prueba@ejemplo.com',
      'telefono': '5551112233',
      'rol': 'usuario',
    });
    expect(u.telefono, '5551112233');
  });

  test('tolerancia: sin idUsuario usa fallback id', () {
    final u = Usuario.fromMap(const {'id': '42', 'nombreCompleto': 'X'});
    expect(u.id, '42');
    expect(u.nombreCompleto, 'X');
  });
}
