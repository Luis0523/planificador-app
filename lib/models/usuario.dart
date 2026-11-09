class Usuario {
  final String id;
  final String nombreUsuario;
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final bool requiereCambioContrasena;

  const Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.nombreCompleto,
    required this.correo,
    this.telefono = '',
    this.requiereCambioContrasena = false,
  });

  factory Usuario.fromMap(Map<String, dynamic> json) => Usuario(
    id: (json['idUsuario'] ?? json['id'] ?? '') as String,
    nombreUsuario: (json['nombreUsuario'] as String?) ?? '',
    nombreCompleto: (json['nombreCompleto'] as String?) ?? '',
    correo: (json['correo'] as String?) ?? '',
    telefono: (json['telefono'] as String?) ?? '',
    requiereCambioContrasena:
        (json['requiereCambioContrasena'] as bool?) ?? false,
  );

  Map<String, dynamic> toMap() => {
    'idUsuario': id,
    'nombreUsuario': nombreUsuario,
    'nombreCompleto': nombreCompleto,
    'correo': correo,
    'telefono': telefono,
    'requiereCambioContrasena': requiereCambioContrasena,
  };
}
