import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/ubicacion.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../services/maps_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/validators.dart';
import 'seleccion_mapa_screen.dart';

class FormularioUbicacionScreen extends StatefulWidget {
  const FormularioUbicacionScreen({super.key, this.ubicacion});

  final Ubicacion? ubicacion;

  @override
  State<FormularioUbicacionScreen> createState() =>
      _FormularioUbicacionScreenState();
}

class _FormularioUbicacionScreenState extends State<FormularioUbicacionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;

  double? _latitud;
  double? _longitud;
  bool _buscandoGps = false;

  bool get _editando => widget.ubicacion != null;
  bool get _tienePunto => _latitud != null && _longitud != null;

  @override
  void initState() {
    super.initState();
    final u = widget.ubicacion;
    _nombreCtrl = TextEditingController(text: u?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: u?.direccion ?? '');
    _latitud = u?.latitud;
    _longitud = u?.longitud;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _setCoordenadas(double latitud, double longitud) {
    setState(() {
      _latitud = latitud;
      _longitud = longitud;
    });
  }

  Future<void> _usarMiUbicacion() async {
    setState(() => _buscandoGps = true);
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _avisar('Debes permitir el acceso a la ubicación.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      _setCoordenadas(pos.latitude, pos.longitude);

      final direccion = await MapsService.instance.geocodificarInverso(
        pos.latitude,
        pos.longitude,
      );
      if (direccion != null) _direccionCtrl.text = direccion;
    } catch (_) {
      _avisar(
        'No se pudo obtener tu ubicación. Revisa el GPS e intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _seleccionarEnMapa() async {
    final resultado = await Navigator.of(context).push<(double, double)>(
      MaterialPageRoute(
        builder: (_) => SeleccionMapaScreen(
          latitud: _latitud ?? 19.4326,
          longitud: _longitud ?? -99.1332,
        ),
      ),
    );
    if (resultado == null || !mounted) return;
    _setCoordenadas(resultado.$1, resultado.$2);
    _direccionCtrl.clear();
    final direccion = await MapsService.instance.geocodificarInverso(
      resultado.$1,
      resultado.$2,
    );
    if (direccion != null && mounted) _direccionCtrl.text = direccion;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_tienePunto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el punto en el mapa o usa tu ubicación.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final provider = context.read<UbicacionesProvider>();
    final usuario = auth.usuario;
    if (usuario == null) return;

    final ahora = ahoraIso();
    final ubicacion = Ubicacion(
      idUbicacion: _editando ? widget.ubicacion!.idUbicacion : null,
      idUsuario: usuario.id,
      nombre: _nombreCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim().isEmpty
          ? null
          : _direccionCtrl.text.trim(),
      latitud: _latitud!,
      longitud: _longitud!,
      fechaCreacion: _editando ? widget.ubicacion!.fechaCreacion : ahora,
      fechaActualizacion: ahora,
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = _editando
        ? await provider.actualizar(ubicacion)
        : await provider.crear(ubicacion);

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (_editando ? 'Ubicación actualizada.' : 'Ubicación guardada.')
              : (provider.error ?? 'Error al guardar'),
        ),
      ),
    );
    if (ok) navigator.pop(ubicacion);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UbicacionesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar ubicación' : 'Nueva ubicación'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('ubicacion_nombre'),
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (v) => validarRequerido(v, 'El nombre'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('ubicacion_direccion'),
                  controller: _direccionCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dirección (opcional)',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                _SelectorPunto(
                  tienePunto: _tienePunto,
                  latitud: _latitud,
                  longitud: _longitud,
                  buscandoGps: _buscandoGps,
                  onGps: _usarMiUbicacion,
                  onMapa: _seleccionarEnMapa,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('ubicacion_guardar'),
                  onPressed: provider.cargando ? null : _guardar,
                  child: provider.cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _editando ? 'Guardar cambios' : 'Guardar ubicación',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorPunto extends StatelessWidget {
  const _SelectorPunto({
    required this.tienePunto,
    required this.latitud,
    required this.longitud,
    required this.buscandoGps,
    required this.onGps,
    required this.onMapa,
  });

  final bool tienePunto;
  final double? latitud;
  final double? longitud;
  final bool buscandoGps;
  final VoidCallback onGps;
  final VoidCallback onMapa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('btn_gps'),
                onPressed: buscandoGps ? null : onGps,
                icon: buscandoGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Usar mi ubicación'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('btn_mapa'),
                onPressed: onMapa,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Seleccionar en mapa'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tienePunto)
          Container(
            key: const Key('ubicacion_punto_seleccionado'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PlanazoColors.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
              border: Border.all(color: PlanazoColors.primary),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: PlanazoColors.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Punto seleccionado: '
                    '${latitud!.toStringAsFixed(4)}, ${longitud!.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: PlanazoColors.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            key: const Key('ubicacion_sin_punto'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PlanazoColors.surfaceContainer,
              borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: PlanazoColors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Elige el lugar con "Usar mi ubicación" o '
                    '"Seleccionar en el mapa". No hace falta escribir coordenadas.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: PlanazoColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
