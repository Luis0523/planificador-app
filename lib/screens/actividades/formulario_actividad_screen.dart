import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/actividad.dart';
import '../../models/condicion_climatica.dart';
import '../../models/ubicacion.dart';
import '../../providers/actividades_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../services/clima_service.dart';
import '../../services/probabilidad_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/clima_dia_chart.dart';
import '../ubicaciones/formulario_ubicacion_screen.dart';

class FormularioActividadScreen extends StatefulWidget {
  const FormularioActividadScreen({super.key, this.actividad});

  final Actividad? actividad;

  @override
  State<FormularioActividadScreen> createState() =>
      _FormularioActividadScreenState();
}

class _FormularioActividadScreenState extends State<FormularioActividadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();

  int? _idUbicacion;
  DateTime? _fecha;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String _tipoActividad = Constants.tipoAireLibre;

  List<ClimaInfo> _puntosDia = const [];
  bool _cargandoClima = false;
  final Set<int> _condicionesSeleccionadas = {};

  bool get _editando => widget.actividad != null;

  @override
  void initState() {
    super.initState();
    final a = widget.actividad;
    if (a != null) {
      _descripcionCtrl.text = a.descripcion;
      _idUbicacion = a.idUbicacion;
      _fecha = DateTime.parse(a.fecha);
      _horaInicio = _parseHora(a.horaInicio);
      _horaFin = _parseHora(a.horaFin);
      _tipoActividad = a.tipoActividad;
    } else {
      final ubicaciones = context.read<UbicacionesProvider>().ubicaciones;
      if (ubicaciones.isNotEmpty) _idUbicacion = ubicaciones.first.idUbicacion;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ActividadesProvider>().cargarCondiciones();
      final idActividad = widget.actividad?.idActividad;
      if (idActividad != null) _cargarCondicionesSeleccionadas(idActividad);
      if (_fecha != null) _consultarClima();
    });
  }

  TimeOfDay? _parseHora(String hora) {
    final partes = hora.split(':');
    if (partes.length != 2) return null;
    return TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 0,
      minute: int.tryParse(partes[1]) ?? 0,
    );
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final inicial = _fecha ?? ahora;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 2),
      helpText: 'Fecha de la actividad',
    );
    if (fecha != null && mounted) {
      setState(() => _fecha = fecha);
      _consultarClima();
    }
  }

  Future<void> _consultarClima() async {
    final fecha = _fecha;
    final idUbicacion = _idUbicacion;
    if (fecha == null || idUbicacion == null) {
      _reiniciarClima();
      return;
    }
    final hoy = DateTime.now();
    final dias = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (dias < 0 || dias > 5) {
      _reiniciarClima();
      return;
    }
    final ubicacion = _ubicacionPorId(idUbicacion);
    if (ubicacion == null) {
      _reiniciarClima();
      return;
    }

    setState(() => _cargandoClima = true);
    try {
      final puntos = await ClimaService.instance.obtenerPronosticoDia(
        latitud: ubicacion.latitud,
        longitud: ubicacion.longitud,
        fecha: fecha,
      );
      if (!mounted) return;
      setState(() {
        _puntosDia = puntos;
        _cargandoClima = false;
      });
    } catch (_) {
      _reiniciarClima();
    }
  }

  void _reiniciarClima() {
    if (!mounted) return;
    setState(() {
      _puntosDia = const [];
      _cargandoClima = false;
    });
  }

  Ubicacion? _ubicacionPorId(int id) {
    final ubicaciones = context.read<UbicacionesProvider>().ubicaciones;
    for (final u in ubicaciones) {
      if (u.idUbicacion == id) return u;
    }
    return null;
  }

  Future<void> _crearUbicacionInline() async {
    final creada = await Navigator.of(context).push<Ubicacion>(
      MaterialPageRoute(builder: (_) => const FormularioUbicacionScreen()),
    );
    if (creada == null || !mounted) return;
    setState(() => _idUbicacion = creada.idUbicacion);
    _consultarClima();
  }

  Future<void> _seleccionarHora({required bool inicio}) async {
    final actual = inicio ? _horaInicio : _horaFin;
    final hora = await showTimePicker(
      context: context,
      initialTime: actual ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (hora == null || !mounted) return;
    setState(() {
      if (inicio) {
        _horaInicio = hora;
      } else {
        _horaFin = hora;
      }
    });
  }

  String? _validarHoraFin(String? _) {
    final inicio = _horaInicio;
    final fin = _horaFin;
    if (inicio == null || fin == null) return null;
    final s = formatearHora(hora: inicio.hour, minuto: inicio.minute);
    final e = formatearHora(hora: fin.hour, minuto: fin.minute);
    if (s.compareTo(e) >= 0) {
      return 'La hora de fin debe ser posterior a la de inicio';
    }
    return null;
  }

  Widget _construirClima() {
    if (_cargandoClima) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PlanazoColors.surfaceContainer,
          borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Consultando el clima…'),
          ],
        ),
      );
    }

    if (_puntosDia.isEmpty) return const SizedBox.shrink();

    final fecha = _fecha;
    return Container(
      key: const Key('clima_dia_preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlanazoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: PlanazoColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Clima del día',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (fecha != null)
                Text(
                  formatearFechaLegible(fecha),
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: PlanazoColors.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClimaDiaChart(puntos: _puntosDia),
          const SizedBox(height: 6),
          Text(
            'La línea muestra la temperatura (°C). Debajo de cada hora, '
            'el ícono indica la condición de ese momento.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: PlanazoColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarCondicionesSeleccionadas(int idActividad) async {
    final ids = await context.read<ActividadesProvider>().obtenerCondicionesIds(
      idActividad,
    );
    if (!mounted) return;
    setState(() {
      _condicionesSeleccionadas
        ..clear()
        ..addAll(ids);
    });
  }

  String? _condicionEnHora() {
    if (_puntosDia.isEmpty) return null;
    final fecha = _fecha;
    final inicio = _horaInicio;
    DateTime objetivo = fecha ?? DateTime.now();
    if (fecha != null && inicio != null) {
      objetivo = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        inicio.hour,
        inicio.minute,
      );
    }
    var mejor = _puntosDia.first;
    var diff = (mejor.fecha.difference(objetivo)).abs();
    for (final p in _puntosDia.skip(1)) {
      final d = (p.fecha.difference(objetivo)).abs();
      if (d < diff) {
        diff = d;
        mejor = p;
      }
    }
    return mejor.condicion;
  }

  Set<String> _nombresSeleccionados(List<CondicionClimatica> catalogo) {
    return {
      for (final c in catalogo)
        if (_condicionesSeleccionadas.contains(c.idCondicion)) c.nombre,
    };
  }

  Widget _seccionCondiciones(List<CondicionClimatica> condiciones) {
    final condicion = _condicionEnHora();
    final ProbabilidadNivel? nivel = condicion == null
        ? null
        : ProbabilidadService.instance.calcular(
            tipoActividad: _tipoActividad,
            condicionesDeseables: _nombresSeleccionados(condiciones).toList(),
            condicionReal: condicion,
          );

    return Column(
      key: const Key('seccion_condiciones'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Condiciones climáticas deseables (opcional)',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: PlanazoColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          'Marca cómo te gustaría que esté el clima. Si no marcas nada, se '
          'recomienda según el clima del día.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: PlanazoColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (condiciones.isEmpty)
          const Text('Cargando condiciones…')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in condiciones)
                FilterChip(
                  key: Key('cond_${c.nombre}'),
                  label: Text(c.nombre),
                  selected: _condicionesSeleccionadas.contains(c.idCondicion),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _condicionesSeleccionadas.add(c.idCondicion!);
                    } else {
                      _condicionesSeleccionadas.remove(c.idCondicion);
                    }
                  }),
                  selectedColor: PlanazoColors.secondaryContainer,
                  checkmarkColor: PlanazoColors.onSecondaryContainer,
                  labelStyle: TextStyle(
                    color: _condicionesSeleccionadas.contains(c.idCondicion)
                        ? PlanazoColors.onSecondaryContainer
                        : PlanazoColors.onSurface,
                  ),
                ),
            ],
          ),
        if (nivel != null) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('recomendacion'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: nivel.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
              border: Border.all(color: nivel.color.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Icon(nivel.icono, color: nivel.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nivel.etiqueta,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: nivel.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idUbicacion == null ||
        _fecha == null ||
        _horaInicio == null ||
        _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa ubicación, fecha y horario.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final provider = context.read<ActividadesProvider>();
    final ahora = ahoraIso();
    final actividad = Actividad(
      idActividad: _editando ? widget.actividad!.idActividad : null,
      idUbicacion: _idUbicacion!,
      descripcion: _descripcionCtrl.text.trim(),
      fecha: formatearFecha(_fecha!),
      horaInicio: formatearHora(
        hora: _horaInicio!.hour,
        minuto: _horaInicio!.minute,
      ),
      horaFin: formatearHora(hora: _horaFin!.hour, minuto: _horaFin!.minute),
      tipoActividad: _tipoActividad,
      estado: _editando ? widget.actividad!.estado : Constants.estadoPendiente,
      fechaCreacion: _editando ? widget.actividad!.fechaCreacion : ahora,
      fechaActualizacion: ahora,
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = _editando
        ? await provider.actualizar(
            actividad,
            _condicionesSeleccionadas.toList(),
          )
        : await provider.crear(actividad, _condicionesSeleccionadas.toList());

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (_editando ? 'Actividad actualizada.' : 'Actividad creada.')
              : (provider.error ?? 'Error al guardar'),
        ),
      ),
    );
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final actividadesProv = context.watch<ActividadesProvider>();
    final cargando = actividadesProv.cargando;
    final condiciones = actividadesProv.condiciones;
    final ubicaciones = context.watch<UbicacionesProvider>().ubicaciones;
    final fecha = _fecha;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar actividad' : 'Nueva actividad'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('actividad_ubicacion'),
                        initialValue: _idUbicacion,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación *',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        items: [
                          for (final u in ubicaciones)
                            DropdownMenuItem(
                              value: u.idUbicacion,
                              child: Text(u.nombre),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() => _idUbicacion = v);
                          _consultarClima();
                        },
                        validator: (v) =>
                            v == null ? 'Selecciona una ubicación' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton.filledTonal(
                        key: const Key('btn_nueva_ubicacion_inline'),
                        tooltip: 'Nueva ubicación',
                        onPressed: _crearUbicacionInline,
                        icon: const Icon(Icons.add_location_alt_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('actividad_nombre'),
                  controller: _descripcionCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la actividad *',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (v) => validarRequerido(v, 'El nombre'),
                ),
                const SizedBox(height: 16),
                _campoFecha(fecha),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _campoHora(
                        key: const Key('actividad_hora_inicio'),
                        etiqueta: 'Inicio',
                        icono: Icons.schedule,
                        hora: _horaInicio,
                        onTap: () => _seleccionarHora(inicio: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _campoHora(
                        key: const Key('actividad_hora_fin'),
                        etiqueta: 'Fin',
                        icono: Icons.schedule,
                        hora: _horaFin,
                        onTap: () => _seleccionarHora(inicio: false),
                      ),
                    ),
                  ],
                ),
                if (_horaFin != null)
                  FormField<String>(
                    validator: _validarHoraFin,
                    builder: (campo) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        campo.errorText ?? '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _construirClima(),
                const SizedBox(height: 24),
                Text(
                  'Tipo de actividad',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: PlanazoColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: Constants.tipoAireLibre,
                      icon: Icon(Icons.directions_run),
                      label: Text('Aire libre'),
                    ),
                    ButtonSegment(
                      value: Constants.tipoInterior,
                      icon: Icon(Icons.meeting_room),
                      label: Text('Interior'),
                    ),
                  ],
                  selected: {_tipoActividad},
                  onSelectionChanged: (nuevo) =>
                      setState(() => _tipoActividad = nuevo.first),
                ),
                const SizedBox(height: 24),
                _seccionCondiciones(condiciones),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('actividad_guardar'),
                  onPressed: cargando ? null : _guardar,
                  child: cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(_editando ? 'Guardar cambios' : 'Crear actividad'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoFecha(DateTime? fecha) {
    return InkWell(
      key: const Key('actividad_fecha'),
      onTap: _seleccionarFecha,
      borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha *',
          prefixIcon: Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          fecha == null ? 'Selecciona la fecha' : formatearFechaLegible(fecha),
          style: TextStyle(
            color: fecha == null
                ? PlanazoColors.onSurfaceVariant
                : PlanazoColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _campoHora({
    required Key key,
    required String etiqueta,
    required IconData icono,
    required TimeOfDay? hora,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '$etiqueta *',
          prefixIcon: Icon(icono),
        ),
        child: Text(
          hora == null
              ? 'HH:mm'
              : formatearHora(hora: hora.hour, minuto: hora.minute),
          style: TextStyle(
            color: hora == null
                ? PlanazoColors.onSurfaceVariant
                : PlanazoColors.onSurface,
          ),
        ),
      ),
    );
  }
}
