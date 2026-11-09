import 'package:flutter/foundation.dart';

import '../models/actividad.dart';
import '../models/condicion_climatica.dart';
import '../services/actividad_service.dart';

class ActividadesProvider extends ChangeNotifier {
  final ActividadService _service = ActividadService.instance;

  List<Actividad> _actividades = [];
  List<CondicionClimatica> _condiciones = [];
  Map<int, List<CondicionClimatica>> _condicionesPorActividad = {};
  int? _idUbicacionActual;
  bool _cargando = false;
  String? _error;

  List<Actividad> get actividades => List.unmodifiable(_actividades);
  List<CondicionClimatica> get condiciones => List.unmodifiable(_condiciones);
  bool get cargando => _cargando;
  String? get error => _error;

  List<CondicionClimatica> condicionesDeActividad(int idActividad) =>
      List.unmodifiable(_condicionesPorActividad[idActividad] ?? const []);

  Future<void> cargar(int idUbicacion) async {
    _idUbicacionActual = idUbicacion;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _actividades = await _service.listarPorUbicacion(idUbicacion);
      _condicionesPorActividad = await _service.condicionesPorActividad(
        _actividades.map((a) => a.idActividad ?? -1).toList(),
      );
    } catch (_) {
      _error = 'No se pudieron cargar las actividades.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarCondiciones() async {
    try {
      _condiciones = await _service.listarCondiciones();
      notifyListeners();
    } catch (_) {
      _error = 'No se pudieron cargar las condiciones climáticas.';
    }
  }

  Future<bool> crear(Actividad actividad, List<int> idCondiciones) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final conflicto = await _service.obtenerActividadEnConflicto(
        idUbicacion: actividad.idUbicacion,
        fecha: actividad.fecha,
        horaInicio: actividad.horaInicio,
        horaFin: actividad.horaFin,
      );
      if (conflicto != null) {
        _error = _mensajeConflicto(conflicto);
        return false;
      }
      final id = await _service.crear(actividad);
      await _service.guardarCondiciones(id, idCondiciones);
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo guardar la actividad.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> actualizar(Actividad actividad, List<int> idCondiciones) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final conflicto = await _service.obtenerActividadEnConflicto(
        idUbicacion: actividad.idUbicacion,
        fecha: actividad.fecha,
        horaInicio: actividad.horaInicio,
        horaFin: actividad.horaFin,
        idExcluida: actividad.idActividad,
      );
      if (conflicto != null) {
        _error = _mensajeConflicto(conflicto);
        return false;
      }
      await _service.actualizar(actividad);
      await _service.guardarCondiciones(actividad.idActividad!, idCondiciones);
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo actualizar la actividad.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> eliminar(int idActividad) async {
    try {
      await _service.eliminar(idActividad);
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo eliminar la actividad.';
      return false;
    }
  }

  Future<List<int>> obtenerCondicionesIds(int idActividad) =>
      _service.obtenerCondiciones(idActividad);

  String _mensajeConflicto(Actividad conflicto) =>
      'Se cruza con "${conflicto.descripcion}" '
      '(${conflicto.horaInicio}–${conflicto.horaFin}).';

  Future<void> _recargar() async {
    final id = _idUbicacionActual;
    if (id != null) await cargar(id);
  }
}
