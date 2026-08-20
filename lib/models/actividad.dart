class Actividad {
  final int? idActividad;
  final int idUbicacion;
  final String descripcion;
  final String fecha; // 'YYYY-MM-DD'
  final String horaInicio; // 'HH:mm'
  final String horaFin; // 'HH:mm'
  final String tipoActividad; // 'aire_libre' | 'interior'
  final String estado; // 'pendiente' | 'finalizada' | 'reagendada'
  final String fechaCreacion;
  final String fechaActualizacion;

  const Actividad({
    this.idActividad,
    required this.idUbicacion,
    required this.descripcion,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.tipoActividad,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Actividad.fromMap(Map<String, Object?> map) => Actividad(
        idActividad: map['id_actividad'] as int?,
        idUbicacion: map['id_ubicacion'] as int,
        descripcion: map['descripcion'] as String,
        fecha: map['fecha'] as String,
        horaInicio: map['hora_inicio'] as String,
        horaFin: map['hora_fin'] as String,
        tipoActividad: map['tipo_actividad'] as String,
        estado: map['estado'] as String,
        fechaCreacion: map['fecha_creacion'] as String,
        fechaActualizacion: map['fecha_actualizacion'] as String,
      );

  Map<String, Object?> toMap() => {
        if (idActividad != null) 'id_actividad': idActividad,
        'id_ubicacion': idUbicacion,
        'descripcion': descripcion,
        'fecha': fecha,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'tipo_actividad': tipoActividad,
        'estado': estado,
        'fecha_creacion': fechaCreacion,
        'fecha_actualizacion': fechaActualizacion,
      };

  Actividad copyWith({
    int? idActividad,
    int? idUbicacion,
    String? descripcion,
    String? fecha,
    String? horaInicio,
    String? horaFin,
    String? tipoActividad,
    String? estado,
    String? fechaCreacion,
    String? fechaActualizacion,
  }) =>
      Actividad(
        idActividad: idActividad ?? this.idActividad,
        idUbicacion: idUbicacion ?? this.idUbicacion,
        descripcion: descripcion ?? this.descripcion,
        fecha: fecha ?? this.fecha,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFin: horaFin ?? this.horaFin,
        tipoActividad: tipoActividad ?? this.tipoActividad,
        estado: estado ?? this.estado,
        fechaCreacion: fechaCreacion ?? this.fechaCreacion,
        fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      );
}
