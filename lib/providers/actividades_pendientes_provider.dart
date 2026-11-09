import 'package:flutter/foundation.dart';

import '../models/actividad.dart';
import '../models/condicion_climatica.dart';
import '../models/ubicacion.dart';
import '../services/actividad_service.dart';
import '../services/clima_service.dart';
import '../services/probabilidad_service.dart';
import '../services/ubicacion_service.dart';

class ActividadConClima {
  final Actividad actividad;
  final Ubicacion ubicacion;
  final List<CondicionClimatica> condicionesDeseables;
  final ClimaInfo? clima;
  final String? errorClima;
  final ProbabilidadNivel probabilidad;

  const ActividadConClima({
    required this.actividad,
    required this.ubicacion,
    required this.condicionesDeseables,
    this.clima,
    this.errorClima,
    required this.probabilidad,
  });
}

class ActividadesPendientesProvider extends ChangeNotifier {
  final ActividadService _actividadService = ActividadService.instance;
  final UbicacionService _ubicacionService = UbicacionService.instance;
  final ClimaService _climaService = ClimaService.instance;
  final ProbabilidadService _probabilidadService = ProbabilidadService.instance;

  List<ActividadConClima> _items = [];
  bool _cargando = false;
  String? _error;
  String? _idUsuario;

  int? _filtroIdUbicacion;
  ProbabilidadNivel? _filtroProbabilidad;
  bool _soloProximos = false;

  bool get cargando => _cargando;
  String? get error => _error;
  int? get filtroIdUbicacion => _filtroIdUbicacion;
  ProbabilidadNivel? get filtroProbabilidad => _filtroProbabilidad;
  bool get soloProximos => _soloProximos;

  List<ActividadConClima> get items {
    var resultado = _items;

    if (_filtroIdUbicacion != null) {
      resultado = resultado
          .where((i) => i.ubicacion.idUbicacion == _filtroIdUbicacion)
          .toList();
    }

    if (_filtroProbabilidad != null) {
      resultado = resultado
          .where((i) => i.probabilidad == _filtroProbabilidad)
          .toList();
    }

    if (_soloProximos) {
      final hoy = DateTime.now();
      final limite = hoy.add(const Duration(days: 7));
      resultado = resultado.where((i) {
        final fecha = DateTime.tryParse(i.actividad.fecha);
        if (fecha == null) return false;
        return !fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day)) &&
            !fecha.isAfter(limite);
      }).toList();
    }

    return resultado;
  }

  void cambiarFiltroUbicacion(int? idUbicacion) {
    _filtroIdUbicacion = idUbicacion;
    notifyListeners();
  }

  void cambiarFiltroProbabilidad(ProbabilidadNivel? nivel) {
    _filtroProbabilidad = nivel;
    notifyListeners();
  }

  void cambiarSoloProximos(bool valor) {
    _soloProximos = valor;
    notifyListeners();
  }

  void limpiarFiltros() {
    _filtroIdUbicacion = null;
    _filtroProbabilidad = null;
    _soloProximos = false;
    notifyListeners();
  }

  Future<void> cargar(String idUsuario) async {
    _idUsuario = idUsuario;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final ubicaciones = await _ubicacionService.listar(idUsuario);
      if (ubicaciones.isEmpty) {
        _items = [];
        return;
      }

      final mapaUbicaciones = {for (final u in ubicaciones) u.idUbicacion!: u};

      final actividades = await _actividadService.listarPendientes(
        ubicaciones.map((u) => u.idUbicacion!).toList(),
      );

      if (actividades.isEmpty) {
        _items = [];
        return;
      }

      final catalogoCondiciones = await _actividadService.listarCondiciones();
      final mapaCatalogo = {
        for (final c in catalogoCondiciones) c.idCondicion!: c,
      };

      final nuevosItems = <ActividadConClima>[];

      for (final actividad in actividades) {
        final ubicacion = mapaUbicaciones[actividad.idUbicacion];
        if (ubicacion == null) continue;

        final condicionesIds = await _actividadService.obtenerCondiciones(
          actividad.idActividad!,
        );
        final condicionesDeseables = condicionesIds
            .map((id) => mapaCatalogo[id])
            .whereType<CondicionClimatica>()
            .toList();

        final nombresDeseables = condicionesDeseables
            .map((c) => c.nombre)
            .toList();

        ClimaInfo? clima;
        String? errorClima;

        try {
          clima = await _climaService.obtenerClima(
            latitud: ubicacion.latitud,
            longitud: ubicacion.longitud,
            fecha: _fechaHora(actividad),
          );
        } catch (e) {
          errorClima = e.toString();
        }

        final probabilidad = _probabilidadService.calcular(
          tipoActividad: actividad.tipoActividad,
          condicionesDeseables: nombresDeseables,
          condicionReal: clima?.condicion ?? 'Nublado',
        );

        nuevosItems.add(
          ActividadConClima(
            actividad: actividad,
            ubicacion: ubicacion,
            condicionesDeseables: condicionesDeseables,
            clima: clima,
            errorClima: errorClima,
            probabilidad: probabilidad,
          ),
        );
      }

      _items = nuevosItems;
    } catch (e) {
      _error = 'No se pudieron cargar las actividades pendientes.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  DateTime _fechaHora(Actividad actividad) {
    final partesHora = actividad.horaInicio.split(':');
    return DateTime(
      int.parse(actividad.fecha.substring(0, 4)),
      int.parse(actividad.fecha.substring(5, 7)),
      int.parse(actividad.fecha.substring(8, 10)),
      int.tryParse(partesHora.first) ?? 0,
      int.tryParse(partesHora.last) ?? 0,
    );
  }

  Future<void> _recargar() async {
    if (_idUsuario != null) await cargar(_idUsuario!);
  }

  Future<bool> marcarFinalizada(ActividadConClima item) async {
    _error = null;
    try {
      await _actividadService.marcarFinalizada(item.actividad);
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo finalizar la actividad.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reagendar(
    ActividadConClima item, {
    required String nuevaFecha,
    required String nuevaHoraInicio,
    required String nuevaHoraFin,
  }) async {
    _error = null;
    try {
      final conflicto = await _actividadService.obtenerActividadEnConflicto(
        idUbicacion: item.actividad.idUbicacion,
        fecha: nuevaFecha,
        horaInicio: nuevaHoraInicio,
        horaFin: nuevaHoraFin,
        idExcluida: item.actividad.idActividad,
      );
      if (conflicto != null) {
        _error =
            'Se cruza con "${conflicto.descripcion}" '
            '(${conflicto.horaInicio}–${conflicto.horaFin}).';
        notifyListeners();
        return false;
      }

      await _actividadService.reagendar(
        item.actividad,
        nuevaFecha: nuevaFecha,
        nuevaHoraInicio: nuevaHoraInicio,
        nuevaHoraFin: nuevaHoraFin,
      );
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo reagendar la actividad.';
      notifyListeners();
      return false;
    }
  }
}
