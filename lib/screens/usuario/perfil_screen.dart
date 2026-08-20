import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

/// Perfil de usuario (Fase 4): muestra datos en solo lectura y permite
/// editar nombre completo y teléfono contra `GET/PUT /api/users/me`.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nombreCtrl =
        TextEditingController(text: auth.usuario?.nombreCompleto ?? '');
    _telefonoCtrl = TextEditingController(text: auth.usuario?.telefono ?? '');
    // Refresca los datos (GET /api/users/me) después del primer frame
    // para no notificar listeners durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargarPerfil();
    });
  }

  /// Refresca los datos al entrar (GET /api/users/me).
  Future<void> _cargarPerfil() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.cargarPerfil();
    if (!mounted || !ok) return;
    setState(() {
      _nombreCtrl.text = auth.usuario?.nombreCompleto ?? _nombreCtrl.text;
      _telefonoCtrl.text = auth.usuario?.telefono ?? _telefonoCtrl.text;
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.actualizarPerfil(
      nombreCompleto: _nombreCtrl.text,
      telefono: _telefonoCtrl.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Perfil actualizado correctamente.' : (auth.error ?? 'Error'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Encabezado(usuario: usuario),
                const SizedBox(height: 24),
                const _TituloSeccion('Datos de cuenta'),
                _campoSoloLectura(
                  key: const Key('perfil_nombre_usuario'),
                  etiqueta: 'Nombre de usuario',
                  icono: Icons.badge_outlined,
                  valor: usuario?.nombreUsuario ?? '',
                ),
                const SizedBox(height: 12),
                _campoSoloLectura(
                  key: const Key('perfil_correo'),
                  etiqueta: 'Correo',
                  icono: Icons.email_outlined,
                  valor: usuario?.correo ?? '',
                ),
                const SizedBox(height: 12),
                _campoSoloLectura(
                  key: const Key('perfil_contrasena'),
                  etiqueta: 'Contraseña',
                  icono: Icons.lock_outline,
                  valor: '••••••••',
                  ayuda: 'La contraseña se gestiona en el flujo de recuperación.',
                ),
                const SizedBox(height: 24),
                const _TituloSeccion('Información editable'),
                TextFormField(
                  key: const Key('perfil_nombre_completo'),
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => validarRequerido(v, 'El nombre completo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('perfil_telefono'),
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _guardar(),
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: validarTelefono,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('perfil_guardar'),
                  onPressed: auth.cargando ? null : _guardar,
                  child: auth.cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoSoloLectura({
    required Key key,
    required String etiqueta,
    required IconData icono,
    required String valor,
    String? ayuda,
  }) {
    return TextFormField(
      key: key,
      enabled: false,
      initialValue: valor,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        helperText: ayuda,
        filled: true,
        fillColor: PlanazoColors.surfaceContainerHigh,
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.usuario});

  final Usuario? usuario;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: PlanazoColors.primary, width: 2),
          ),
          child: const CircleAvatar(
            radius: 40,
            backgroundColor: PlanazoColors.primaryContainer,
            child: Icon(
              Icons.person,
              size: 44,
              color: PlanazoColors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          usuario?.nombreCompleto ?? 'Planazero',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          usuario?.correo ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PlanazoColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: PlanazoColors.onSurfaceVariant,
            ),
      ),
    );
  }
}
