import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../services/maps_service.dart';

/// Selector de punto en el mapa.
/// Con `GOOGLE_MAPS_API_KEY` configurada (y en Android/iOS) muestra un
/// GoogleMap real donde se toca para elegir el punto. En web o sin clave
/// cae a un formulario de coordenadas.
/// Devuelve una tupla (latitud, longitud) vía `Navigator.pop`.
class SeleccionMapaScreen extends StatefulWidget {
  const SeleccionMapaScreen({
    super.key,
    this.latitud = 19.4326,
    this.longitud = -99.1332,
  });

  final double latitud;
  final double longitud;

  @override
  State<SeleccionMapaScreen> createState() => _SeleccionMapaScreenState();
}

class _SeleccionMapaScreenState extends State<SeleccionMapaScreen> {
  late double _latitud;
  late double _longitud;
  late final TextEditingController _latitudCtrl;
  late final TextEditingController _longitudCtrl;
  String? _direccion;
  bool _buscandoDireccion = false;

  bool get _usarMapaReal => !kIsWeb && Constants.googleMapsApiKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _latitud = widget.latitud;
    _longitud = widget.longitud;
    _latitudCtrl = TextEditingController(text: _latitud.toStringAsFixed(6));
    _longitudCtrl = TextEditingController(text: _longitud.toStringAsFixed(6));
    if (_usarMapaReal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buscarDireccion();
      });
    }
  }

  @override
  void dispose() {
    _latitudCtrl.dispose();
    _longitudCtrl.dispose();
    super.dispose();
  }

  void _seleccionarPunto(LatLng punto) {
    setState(() {
      _latitud = punto.latitude;
      _longitud = punto.longitude;
      _direccion = null;
    });
    _latitudCtrl.text = _latitud.toStringAsFixed(6);
    _longitudCtrl.text = _longitud.toStringAsFixed(6);
    _buscarDireccion();
  }

  Future<void> _buscarDireccion() async {
    setState(() => _buscandoDireccion = true);
    final direccion =
        await MapsService.instance.geocodificarInverso(_latitud, _longitud);
    if (!mounted) return;
    setState(() {
      _direccion = direccion;
      _buscandoDireccion = false;
    });
  }

  void _aceptar() {
    if (_usarMapaReal) {
      Navigator.of(context).pop((_latitud, _longitud));
      return;
    }
    final lat = double.tryParse(_latitudCtrl.text.trim());
    final lng = double.tryParse(_longitudCtrl.text.trim());
    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa coordenadas válidas')),
      );
      return;
    }
    Navigator.of(context).pop((lat, lng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar en el mapa')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _usarMapaReal ? _construirMapa() : _construirCoordenadas(),
            ),
            _PanelInferior(
              latitud: _latitud,
              longitud: _longitud,
              direccion: _direccion,
              buscandoDireccion: _buscandoDireccion,
              mostrarDireccion: _usarMapaReal,
              onAceptar: _aceptar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirMapa() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_latitud, _longitud),
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('punto_seleccionado'),
          position: LatLng(_latitud, _longitud),
        ),
      },
      onTap: _seleccionarPunto,
    );
  }

  Widget _construirCoordenadas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PlanazoColors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: PlanazoColors.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'El mapa no está disponible en web. Ingresa las '
                            'coordenadas del punto.'
                        : 'El mapa visual estará disponible cuando se configure '
                            'la API key de Google Maps. Por ahora ingresa las '
                            'coordenadas del punto.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PlanazoColors.onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('mapa_latitud'),
            controller: _latitudCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Latitud',
              prefixIcon: Icon(Icons.pin_drop_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('mapa_longitud'),
            controller: _longitudCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Longitud',
              prefixIcon: Icon(Icons.pin_drop_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelInferior extends StatelessWidget {
  const _PanelInferior({
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.buscandoDireccion,
    required this.mostrarDireccion,
    required this.onAceptar,
  });

  final double latitud;
  final double longitud;
  final String? direccion;
  final bool buscandoDireccion;
  final bool mostrarDireccion;
  final VoidCallback onAceptar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: PlanazoColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: PlanazoColors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: PlanazoColors.onSurfaceVariant,
                ),
          ),
          if (mostrarDireccion) ...[
            const SizedBox(height: 4),
            if (buscandoDireccion)
              const Text('Buscando dirección…')
            else
              Text(
                direccion ?? 'Toca el mapa para elegir un punto.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('mapa_aceptar'),
            onPressed: onAceptar,
            child: const Text('Usar este punto'),
          ),
        ],
      ),
    );
  }
}
