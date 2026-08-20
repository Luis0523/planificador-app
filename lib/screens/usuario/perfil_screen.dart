import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Pantalla de perfil de usuario (se construye completa en la Fase 4).
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
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
                  Icons.person,
                  size: 40,
                  color: PlanazoColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mi perfil',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Ver y editar tus datos personales. (Fase 4)',
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
