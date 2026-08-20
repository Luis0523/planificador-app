import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Listado de actividades (se construye completo en la Fase 6).
class ListadoActividadesScreen extends StatelessWidget {
  const ListadoActividadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis actividades')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: PlanazoColors.primaryContainer,
                child: Icon(
                  Icons.celebration_outlined,
                  size: 40,
                  color: PlanazoColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mis actividades',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Gestiona tus actividades por ubicación. (Fase 6)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PlanazoColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
