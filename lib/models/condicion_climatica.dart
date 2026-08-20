class CondicionClimatica {
  final int? idCondicion;
  final String nombre;
  final String? descripcion;

  const CondicionClimatica({
    this.idCondicion,
    required this.nombre,
    this.descripcion,
  });

  factory CondicionClimatica.fromMap(Map<String, Object?> map) =>
      CondicionClimatica(
        idCondicion: map['id_condicion'] as int?,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (idCondicion != null) 'id_condicion': idCondicion,
        'nombre': nombre,
        'descripcion': descripcion,
      };
}
