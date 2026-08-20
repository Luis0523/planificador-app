import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/ubicacion.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ubicaciones_provider.dart';
import '../../services/maps_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/validators.dart';
import 'seleccion_mapa_screen.dart';

/// Formulario de ubicación: sirve para crear y editar.
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
  late final TextEditingController _latitudCtrl;
  late final TextEditingController _longitudCtrl;

  bool _buscandoGps = false;

  bool get _editando => widget.ubicacion != null;

  @override
  void initState() {
    super.initState();
    final u = widget.ubicacion;
    _nombreCtrl = TextEditingController(text: u?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: u?.direccion ?? '');
    _latitudCtrl =
        TextEditingController(text: u?.latitud.toStringAsFixed(6) ?? '');
    _longitudCtrl =
        TextEditingController(text: u?.longitud.toStringAsFixed(6) ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _latitudCtrl.dispose();
    _longitudCtrl.dispose();
    super.dispose();
  }

  void _setCoordenadas(double latitud, double longitud) {
    _latitudCtrl.text = latitud.toStringAsFixed(6);
    _longitudCtrl.text = longitud.toStringAsFixed(6);
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
        _usarUbicacionMock('Permiso de ubicación denegado');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _setCoordenadas(pos.latitude, pos.longitude);
      final direccion = await MapsService.instance
          .geocodificarInverso(pos.latitude, pos.longitude);
      if (direccion != null) _direccionCtrl.text = direccion;
    } catch (_) {
      _usarUbicacionMock('No se pudo obtener tu ubicación');
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  void _usarUbicacionMock(String mensaje) {
    if (!mounted) return;
    // TODO: quitar cuando haya API key de Google Maps.
    _setCoordenadas(19.4326, -99.1332);
    _direccionCtrl.text = 'Ubicación de ejemplo (mock)';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$mensaje. Se usó una ubicación de ejemplo.')),
    );
  }

  Future<void> _seleccionarEnMapa() async {
    final actual = double.tryParse(_latitudCtrl.text.trim());
    final resultado = await Navigator.of(context).push<(double, double)>(
      MaterialPageRoute(
        builder: (_) => SeleccionMapaScreen(
          latitud: actual ?? 19.4326,
          longitud: double.tryParse(_longitudCtrl.text.trim()) ?? -99.1332,
        ),
      ),
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _setCoordenadas(resultado.$1, resultado.$2);
      _direccionCtrl.clear();
    });
    // Geocodificación inversa del punto elegido para autocompletar la dirección.
    final direccion = await MapsService.instance
        .geocodificarInverso(resultado.$1, resultado.$2);
    if (direccion != null && mounted) _direccionCtrl.text = direccion;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
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
      latitud: double.parse(_latitudCtrl.text.trim()),
      longitud: double.parse(_longitudCtrl.text.trim()),
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
              ? (_editando
                  ? 'Ubicación actualizada.'
                  : 'Ubicación guardada.')
              : (provider.error ?? 'Error al guardar'),
        ),
      ),
    );
    if (ok) navigator.pop();
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
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('ubicacion_latitud'),
                  controller: _latitudCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Latitud *',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  validator: validarLatitud,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('ubicacion_longitud'),
                  controller: _longitudCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Longitud *',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  validator: validarLongitud,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('btn_gps'),
                        onPressed: _buscandoGps ? null : _usarMiUbicacion,
                        icon: _buscandoGps
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Usar mi ubicación'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('btn_mapa'),
                        onPressed: _seleccionarEnMapa,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Seleccionar en mapa'),
                      ),
                    ),
                  ],
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
                      : Text(_editando ? 'Guardar cambios' : 'Guardar ubicación'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
