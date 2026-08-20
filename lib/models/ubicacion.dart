class Ubicacion {
  final int? idUbicacion;
  final int idUsuario;
  final String nombre;
  final String? direccion;
  final double latitud;
  final double longitud;
  final String fechaCreacion;
  final String fechaActualizacion;

  const Ubicacion({
    this.idUbicacion,
    required this.idUsuario,
    required this.nombre,
    this.direccion,
    required this.latitud,
    required this.longitud,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Ubicacion.fromMap(Map<String, Object?> map) => Ubicacion(
        idUbicacion: map['id_ubicacion'] as int?,
        idUsuario: map['id_usuario'] as int,
        nombre: map['nombre'] as String,
        direccion: map['direccion'] as String?,
        latitud: (map['latitud'] as num).toDouble(),
        longitud: (map['longitud'] as num).toDouble(),
        fechaCreacion: map['fecha_creacion'] as String,
        fechaActualizacion: map['fecha_actualizacion'] as String,
      );

  Map<String, Object?> toMap() => {
        if (idUbicacion != null) 'id_ubicacion': idUbicacion,
        'id_usuario': idUsuario,
        'nombre': nombre,
        'direccion': direccion,
        'latitud': latitud,
        'longitud': longitud,
        'fecha_creacion': fechaCreacion,
        'fecha_actualizacion': fechaActualizacion,
      };

  Ubicacion copyWith({
    int? idUbicacion,
    int? idUsuario,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    String? fechaCreacion,
    String? fechaActualizacion,
  }) =>
      Ubicacion(
        idUbicacion: idUbicacion ?? this.idUbicacion,
        idUsuario: idUsuario ?? this.idUsuario,
        nombre: nombre ?? this.nombre,
        direccion: direccion ?? this.direccion,
        latitud: latitud ?? this.latitud,
        longitud: longitud ?? this.longitud,
        fechaCreacion: fechaCreacion ?? this.fechaCreacion,
        fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      );
}
