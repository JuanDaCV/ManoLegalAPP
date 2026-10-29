import 'package:cloud_firestore/cloud_firestore.dart';

/// Datos de un usuario con rol de cliente.
class ModeloCliente {
  final String uid;
  final String nombre;
  final String apellido;
  final DateTime fechaNacimiento;
  final String telefono;
  final String correo;

  const ModeloCliente({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.telefono,
    required this.correo,
  });

  /// Crea el cliente a partir de un mapa de Firestore.
  ///
  /// `nombre`, `apellido`, `telefono` y `correo` son campos estructurales y
  /// siguen lanzando una excepción si faltan de verdad, porque su ausencia
  /// indica una corrupción real del documento. `fechaNacimiento` se valida
  /// aparte para lanzar una [FormatException] con el uid incluido en el
  /// mensaje, en vez de un error de conversión de tipos poco claro.
  factory ModeloCliente.fromMap(String uid, Map<String, dynamic> mapa) {
    final fechaNacimientoCruda = mapa['fechaNacimiento'];
    if (fechaNacimientoCruda is! Timestamp) {
      throw FormatException(
        'El cliente $uid no tiene una fecha de nacimiento válida en Firestore.',
      );
    }
    return ModeloCliente(
      uid: uid,
      nombre: mapa['nombre'] as String,
      apellido: mapa['apellido'] as String,
      fechaNacimiento: fechaNacimientoCruda.toDate(),
      telefono: mapa['telefono'] as String,
      correo: mapa['correo'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
      'telefono': telefono,
      'correo': correo,
    };
  }
}
