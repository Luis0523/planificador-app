import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCompletoCtrl = TextEditingController();
  final _nombreUsuarioCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCompletoCtrl.dispose();
    _nombreUsuarioCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _contrasenaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();

    final ok = await auth.registrar(
      nombreCompleto: _nombreCompletoCtrl.text,
      nombreUsuario: _nombreUsuarioCtrl.text,
      correo: _correoCtrl.text,
      telefono: _telefonoCtrl.text,
      contrasena: _contrasenaCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. Ahora puedes iniciar sesión.'),
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error al registrarse')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('registro_nombre_completo'),
                  controller: _nombreCompletoCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => validarRequerido(v, 'El nombre completo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('registro_nombre_usuario'),
                  controller: _nombreUsuarioCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: validarNombreUsuario,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('registro_correo'),
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: validarCorreo,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('registro_telefono'),
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: validarTelefono,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('registro_contrasena'),
                  controller: _contrasenaCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: validarContrasena,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('registro_confirmar'),
                  controller: _confirmarCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      validarConfirmacion(v, _contrasenaCtrl.text),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.cargando ? null : _submit,
                  child: auth.cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
