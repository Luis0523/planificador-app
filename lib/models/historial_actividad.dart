class HistorialActividad {
  final int? idHistorial;
  final int idActividad;
  final String estadoAnterior;
  final String estadoNuevo;
  final String fechaCambio;
  final String? comentario;

  const HistorialActividad({
    this.idHistorial,
    required this.idActividad,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.fechaCambio,
    this.comentario,
  });

  factory HistorialActividad.fromMap(Map<String, Object?> map) =>
      HistorialActividad(
        idHistorial: map['id_historial'] as int?,
        idActividad: map['id_actividad'] as int,
        estadoAnterior: map['estado_anterior'] as String,
        estadoNuevo: map['estado_nuevo'] as String,
        fechaCambio: map['fecha_cambio'] as String,
        comentario: map['comentario'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (idHistorial != null) 'id_historial': idHistorial,
        'id_actividad': idActividad,
        'estado_anterior': estadoAnterior,
        'estado_nuevo': estadoNuevo,
        'fecha_cambio': fechaCambio,
        'comentario': comentario,
      };
}
