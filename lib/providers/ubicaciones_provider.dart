import 'package:flutter/foundation.dart';

import '../models/ubicacion.dart';
import '../services/ubicacion_service.dart';

class UbicacionesProvider extends ChangeNotifier {
  final UbicacionService _service = UbicacionService.instance;

  List<Ubicacion> _ubicaciones = [];
  int? _idUsuario;
  bool _cargando = false;
  String? _error;

  List<Ubicacion> get ubicaciones => List.unmodifiable(_ubicaciones);
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar(int idUsuario) async {
    _idUsuario = idUsuario;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _ubicaciones = await _service.listar(idUsuario);
    } catch (_) {
      _error = 'No se pudieron cargar las ubicaciones.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(Ubicacion ubicacion) async {
    try {
      await _service.crear(ubicacion);
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo guardar la ubicación.';
      return false;
    }
  }

  Future<bool> actualizar(Ubicacion ubicacion) async {
    try {
      await _service.actualizar(ubicacion);
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo actualizar la ubicación.';
      return false;
    }
  }

  Future<bool> eliminar(int idUbicacion) async {
    try {
      await _service.eliminar(idUbicacion);
      await _recargar();
      return true;
    } catch (_) {
      _error = 'No se pudo eliminar la ubicación.';
      return false;
    }
  }

  Future<void> _recargar() async {
    final id = _idUsuario;
    if (id != null) await cargar(id);
  }
}
