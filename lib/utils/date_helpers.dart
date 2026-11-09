import 'package:intl/intl.dart';

/// Fecha/hora actual en ISO 8601 (para campos fecha_creacion/fecha_actualizacion).
String ahoraIso() => DateTime.now().toIso8601String();

/// Fecha en formato 'YYYY-MM-DD' (formato de la tabla actividades).
String formatearFecha(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);

/// Hora en formato 'HH:mm' (formato de la tabla actividades).
String formatearHora({required int hora, required int minuto}) =>
    '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

/// Fecha legible para la UI (p. ej. '20 ago 2026').
String formatearFechaLegible(DateTime fecha) =>
    DateFormat('d MMM yyyy', 'es').format(fecha);
