class Usuario {
  final int id;
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
    required this.telefono,
    this.requiereCambioContrasena = false,
  });

  factory Usuario.fromMap(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nombreUsuario: json['nombreUsuario'] as String? ?? '',
        nombreCompleto: json['nombreCompleto'] as String? ?? '',
        correo: json['correo'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        requiereCambioContrasena:
            json['requiereCambioContrasena'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombreUsuario': nombreUsuario,
        'nombreCompleto': nombreCompleto,
        'correo': correo,
        'telefono': telefono,
        'requiereCambioContrasena': requiereCambioContrasena,
      };
}
