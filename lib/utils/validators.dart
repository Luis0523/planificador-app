String? validarRequerido(String? value, [String etiqueta = 'Este campo']) {
  if (value == null || value.trim().isEmpty) {
    return '$etiqueta es obligatorio';
  }
  return null;
}

String? validarCorreo(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El correo es obligatorio';
  }
  final exp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!exp.hasMatch(value.trim())) {
    return 'Ingresa un correo válido';
  }
  return null;
}

String? validarContrasena(String? value) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es obligatoria';
  }
  if (value.length < 6) {
    return 'La contraseña debe tener al menos 6 caracteres';
  }
  return null;
}

String? validarConfirmacion(String? value, String original) {
  if (value == null || value.isEmpty) {
    return 'Confirma la contraseña';
  }
  if (value != original) {
    return 'Las contraseñas no coinciden';
  }
  return null;
}

String? validarTelefono(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El teléfono es obligatorio';
  }
  if (!RegExp(r'^\d{7,15}$').hasMatch(value.trim())) {
    return 'Teléfono inválido (solo dígitos)';
  }
  return null;
}

String? validarNombreUsuario(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El nombre de usuario es obligatorio';
  }
  if (value.trim().length < 3) {
    return 'Mínimo 3 caracteres';
  }
  return null;
}

String? validarLatitud(String? value) {
  final valor = double.tryParse(value?.trim() ?? '');
  if (valor == null) return 'Ingresa una latitud válida';
  if (valor < -90 || valor > 90) return 'La latitud va de -90 a 90';
  return null;
}

String? validarLongitud(String? value) {
  final valor = double.tryParse(value?.trim() ?? '');
  if (valor == null) return 'Ingresa una longitud válida';
  if (valor < -180 || valor > 180) return 'La longitud va de -180 a 180';
  return null;
}
