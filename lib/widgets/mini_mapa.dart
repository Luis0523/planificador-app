import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/constants.dart';
import '../config/theme.dart';

/// Mini vista previa de un punto en el mapa (no interactiva).
/// En web o sin API key muestra un marcador de respaldo en su lugar.
class MiniMapa extends StatelessWidget {
  const MiniMapa({
    super.key,
    required this.latitud,
    required this.longitud,
    this.altura = 140,
  });

  final double latitud;
  final double longitud;
  final double altura;

  bool get _puedeMostrarMapa =>
      !kIsWeb && Constants.googleMapsApiKey.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_puedeMostrarMapa) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
        child: SizedBox(
          height: altura,
          child: IgnorePointer(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(latitud, longitud),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('minimapa'),
                  position: LatLng(latitud, longitud),
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
          ),
        ),
      );
    }

    // Respaldo: web / sin API key (evita plataformas nativas en esos casos).
    return Container(
      height: altura,
      decoration: BoxDecoration(
        color: PlanazoColors.surfaceContainer,
        borderRadius: BorderRadius.circular(PlanazoColors.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, color: PlanazoColors.primary),
          const SizedBox(width: 8),
          Text(
            '${latitud.toStringAsFixed(4)}, ${longitud.toStringAsFixed(4)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PlanazoColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
