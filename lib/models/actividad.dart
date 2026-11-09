class Actividad {
  final int? idActividad;
  final int idUbicacion;
  final String descripcion;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String tipoActividad;
  final String estado;
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
}
