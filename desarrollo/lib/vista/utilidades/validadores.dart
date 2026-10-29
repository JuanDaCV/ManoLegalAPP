/// Funciones de validación puras para formularios.
/// Retornan `null` si el valor es válido, o un mensaje de error en caso contrario.
library;

String? validarCorreo(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Ingresa tu correo';
  final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  if (!regex.hasMatch(valor.trim())) return 'Correo no válido';
  return null;
}

String? validarContrasena(String? valor) {
  if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña';
  if (valor.length < 6) return 'Debe tener al menos 6 caracteres';
  return null;
}

String? validarConfirmacionContrasena(String contrasena, String? confirmacion) {
  if (confirmacion == null || confirmacion.isEmpty) return 'Confirma tu contraseña';
  if (confirmacion != contrasena) return 'Las contraseñas no coinciden';
  return null;
}

String? validarCampoRequerido(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Este campo es obligatorio';
  return null;
}

String? validarTelefonoColombiano(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Ingresa tu número de celular';
  final regex = RegExp(r'^3\d{9}$');
  if (!regex.hasMatch(valor.trim())) {
    return 'Ingresa un celular colombiano válido (10 dígitos, inicia en 3)';
  }
  return null;
}

String? validarFechaNacimiento(DateTime? fecha) {
  if (fecha == null) return 'Selecciona tu fecha de nacimiento';
  final ahora = DateTime.now();
  if (fecha.isAfter(ahora)) return 'La fecha no puede ser futura';
  final edadMinima = DateTime(fecha.year + 18, fecha.month, fecha.day);
  if (edadMinima.isAfter(ahora)) return 'Debes ser mayor de 18 años';
  return null;
}

String? validarDescripcionAbogado(String? valor) {
  if (valor == null || valor.trim().isEmpty) return 'Ingresa una descripción';
  if (valor.length > 300) return 'Máximo 300 caracteres';
  return null;
}
