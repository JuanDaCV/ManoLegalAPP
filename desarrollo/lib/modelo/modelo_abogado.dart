import 'package:cloud_firestore/cloud_firestore.dart';

import 'especialidad_abogado.dart';
import 'modelo_documento_abogado.dart';
import 'modelo_experiencia_profesional.dart';
import 'modelo_perfil_publico_abogado.dart';
import 'ubicacion_cali.dart';

export 'especialidad_abogado.dart';

/// Datos de un usuario con rol de abogado.
class ModeloAbogado {
  final String uid;
  final String nombre;
  final String apellido;
  final DateTime fechaNacimiento;
  final String telefono;
  final String correo;
  final String telefonoProfesional;
  final EspecialidadAbogado especialidad;
  final int aniosExperiencia;
  final double? tarifa;
  final String descripcion;

  /// URL de descarga de la foto de perfil en Firebase Storage
  /// (`abogados/{uid}/foto_perfil.jpg`). Vacía si el abogado no cargó foto.
  final String fotoPerfilRuta;

  /// Rutas de los documentos de verificación del abogado en Firebase
  /// Storage (ver [ModeloDocumentoAbogado]).
  final ModeloDocumentoAbogado documentos;
  final String estado;
  final UbicacionCali? ubicacionGeneral;
  final String sector;
  final String direccionProfesional;
  final String? instagram;
  final String? facebook;
  final String? linkedin;
  final List<ModeloExperienciaProfesional> experiencia;
  final String correoContacto;

  const ModeloAbogado({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.telefono,
    required this.correo,
    required this.telefonoProfesional,
    required this.especialidad,
    required this.aniosExperiencia,
    this.tarifa,
    required this.descripcion,
    required this.fotoPerfilRuta,
    required this.documentos,
    required this.estado,
    this.ubicacionGeneral,
    this.sector = '',
    this.direccionProfesional = '',
    this.instagram,
    this.facebook,
    this.linkedin,
    this.experiencia = const [],
    this.correoContacto = '',
  });

  /// Crea el abogado a partir de un mapa de Firestore.
  ///
  /// El campo `fotoPerfilRuta` y los campos agregados con posterioridad al
  /// lanzamiento (`ubicacionGeneral`, `sector`, `direccionProfesional`,
  /// `instagram`, `facebook`, `linkedin`, `experiencia`, `correoContacto`)
  /// son tolerantes: si faltan, se asume un valor por defecto, porque un
  /// documento anterior a su creación no debería romper la aplicación. En
  /// cambio, los campos estructurales originales (`nombre`, `apellido`,
  /// `fechaNacimiento`, `telefono`, `correo`, `telefonoProfesional`,
  /// `aniosExperiencia`, `descripcion`, `estado`, `documentos`) siguen
  /// lanzando una excepción si faltan de verdad, porque su ausencia indica
  /// una corrupción real del documento que no se debe ocultar.
  factory ModeloAbogado.fromMap(String uid, Map<String, dynamic> mapa) {
    return ModeloAbogado(
      uid: uid,
      nombre: mapa['nombre'] as String,
      apellido: mapa['apellido'] as String,
      fechaNacimiento: (mapa['fechaNacimiento'] as Timestamp).toDate(),
      telefono: mapa['telefono'] as String,
      correo: mapa['correo'] as String,
      telefonoProfesional: mapa['telefonoProfesional'] as String,
      especialidad: especialidadDesdeClave(mapa['especialidad']),
      aniosExperiencia: mapa['aniosExperiencia'] as int,
      tarifa: (mapa['tarifa'] as num?)?.toDouble(),
      descripcion: mapa['descripcion'] as String,
      fotoPerfilRuta: (mapa['fotoPerfilRuta'] as String?) ?? '',
      documentos: ModeloDocumentoAbogado.fromMap(
        Map<String, dynamic>.from(mapa['documentos'] as Map),
      ),
      estado: mapa['estado'] as String,
      ubicacionGeneral: ubicacionDesdeClave(mapa['ubicacionGeneral']),
      sector: (mapa['sector'] as String?) ?? '',
      direccionProfesional: (mapa['direccionProfesional'] as String?) ?? '',
      instagram: mapa['instagram'] as String?,
      facebook: mapa['facebook'] as String?,
      linkedin: mapa['linkedin'] as String?,
      experiencia: (mapa['experiencia'] as List<dynamic>? ?? const [])
          .map((e) => ModeloExperienciaProfesional.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      correoContacto: (mapa['correoContacto'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
      'telefono': telefono,
      'correo': correo,
      'telefonoProfesional': telefonoProfesional,
      'especialidad': especialidad.clave,
      'aniosExperiencia': aniosExperiencia,
      'tarifa': tarifa,
      'descripcion': descripcion,
      'fotoPerfilRuta': fotoPerfilRuta,
      'documentos': documentos.toMap(),
      'estado': estado,
      'ubicacionGeneral': ubicacionGeneral?.clave,
      'sector': sector,
      'direccionProfesional': direccionProfesional,
      'instagram': instagram,
      'facebook': facebook,
      'linkedin': linkedin,
      'experiencia': experiencia.map((e) => e.toMap()).toList(),
      'correoContacto': correoContacto,
    };
  }

  /// Copia el abogado con nuevos valores, útil para armar el modelo final
  /// tras subir los archivos y antes de guardarlo en Firestore.
  ModeloAbogado copiarCon({
    String? fotoPerfilRuta,
    ModeloDocumentoAbogado? documentos,
    String? estado,
    UbicacionCali? ubicacionGeneral,
    String? sector,
    String? direccionProfesional,
    String? instagram,
    String? facebook,
    String? linkedin,
    List<ModeloExperienciaProfesional>? experiencia,
    String? correoContacto,
    double? tarifa,
    String? descripcion,
    String? telefonoProfesional,
  }) {
    return ModeloAbogado(
      uid: uid,
      nombre: nombre,
      apellido: apellido,
      fechaNacimiento: fechaNacimiento,
      telefono: telefono,
      correo: correo,
      telefonoProfesional: telefonoProfesional ?? this.telefonoProfesional,
      especialidad: especialidad,
      aniosExperiencia: aniosExperiencia,
      tarifa: tarifa ?? this.tarifa,
      descripcion: descripcion ?? this.descripcion,
      fotoPerfilRuta: fotoPerfilRuta ?? this.fotoPerfilRuta,
      documentos: documentos ?? this.documentos,
      estado: estado ?? this.estado,
      ubicacionGeneral: ubicacionGeneral ?? this.ubicacionGeneral,
      sector: sector ?? this.sector,
      direccionProfesional: direccionProfesional ?? this.direccionProfesional,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      linkedin: linkedin ?? this.linkedin,
      experiencia: experiencia ?? this.experiencia,
      correoContacto: correoContacto ?? this.correoContacto,
    );
  }

  /// Proyecta los datos públicos de este abogado. Nunca incluye fecha de
  /// nacimiento, teléfono personal ni rutas de documentos.
  ModeloPerfilPublicoAbogado aPerfilPublico() {
    final nombreCompleto = '$nombre $apellido';
    return ModeloPerfilPublicoAbogado(
      uid: uid,
      nombreCompleto: nombreCompleto,
      nombreBusqueda: normalizarTexto(nombreCompleto),
      fotoUrl: fotoPerfilRuta.isEmpty ? null : fotoPerfilRuta,
      especialidad: especialidad,
      aniosExperiencia: aniosExperiencia,
      ubicacionGeneral: ubicacionGeneral,
      sector: sector,
      direccionProfesional: direccionProfesional,
      tarifa: tarifa,
      descripcion: descripcion,
      experiencia: experiencia,
      instagram: instagram,
      facebook: facebook,
      linkedin: linkedin,
      verificado: estado == 'verificado',
      calificacionPromedio: 0,
      cantidadResenas: 0,
      telefonoProfesional: telefonoProfesional,
      correoContacto: correoContacto.isEmpty ? correo : correoContacto,
    );
  }
}
