import 'package:intl/intl.dart';

String ahoraIso() => DateTime.now().toIso8601String();

String formatearFecha(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);

String formatearHora({required int hora, required int minuto}) =>
    '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

String formatearFechaLegible(DateTime fecha) =>
    DateFormat('d MMM yyyy', 'es').format(fecha);
