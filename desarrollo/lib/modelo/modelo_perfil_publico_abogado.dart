import 'package:cloud_firestore/cloud_firestore.dart';

import 'especialidad_abogado.dart';
import 'modelo_experiencia_profesional.dart';
import 'ubicacion_cali.dart';

/// Modelo de datos real de Firestore para `perfilesPublicosAbogados/{uid}`:
/// la proyección pública de un abogado que ve el buscador y el visualizador
/// de perfil del cliente. Nunca incluye datos privados como la fecha de
/// nacimiento, el teléfono personal o las rutas de los documentos de
/// verificación.
class ModeloPerfilPublicoAbogado {
  final String uid;
  final String nombreCompleto;
  final String nombreBusqueda;
  final String? fotoUrl;
  final EspecialidadAbogado especialidad;
  final int aniosExperiencia;
  final UbicacionCali? ubicacionGeneral;
  final String sector;
  final String direccionProfesional;
  final double? tarifa;
  final String descripcion;
  final List<ModeloExperienciaProfesional> experiencia;
  final String? instagram;
  final String? facebook;
  final String? linkedin;
  final bool verificado;
  final double calificacionPromedio;
  final int cantidadResenas;
  final String telefonoProfesional;
  final String correoContacto;

  const ModeloPerfilPublicoAbogado({
    required this.uid,
    required this.nombreCompleto,
    this.nombreBusqueda = '',
    this.fotoUrl,
    required this.especialidad,
    required this.aniosExperiencia,
    this.ubicacionGeneral,
    this.sector = '',
    this.direccionProfesional = '',
    this.tarifa,
    this.descripcion = '',
    this.experiencia = const [],
    this.instagram,
    this.facebook,
    this.linkedin,
    required this.verificado,
    this.calificacionPromedio = 0,
    this.cantidadResenas = 0,
    required this.telefonoProfesional,
    required this.correoContacto,
  });

  /// Crea el perfil público a partir de un mapa de Firestore. Es tolerante
  /// con cada campo: nunca lanza una excepción porque un campo nuevo esté
  /// ausente, ya que este documento puede evolucionar con el tiempo.
  factory ModeloPerfilPublicoAbogado.fromMap(String uid, Map<String, dynamic> mapa) {
    final nombreCompleto = (mapa['nombreCompleto'] as String?) ?? '';
    return ModeloPerfilPublicoAbogado(
      uid: uid,
      nombreCompleto: nombreCompleto,
      nombreBusqueda: (mapa['nombreBusqueda'] as String?) ?? normalizarTexto(nombreCompleto),
      fotoUrl: mapa['fotoUrl'] as String?,
      especialidad: especialidadDesdeClave(mapa['especialidad']),
      aniosExperiencia: (mapa['aniosExperiencia'] as num?)?.toInt() ?? 0,
      ubicacionGeneral: ubicacionDesdeClave(mapa['ubicacionGeneral']),
      sector: (mapa['sector'] as String?) ?? '',
      direccionProfesional: (mapa['direccionProfesional'] as String?) ?? '',
      tarifa: (mapa['tarifa'] as num?)?.toDouble(),
      descripcion: (mapa['descripcion'] as String?) ?? '',
      experiencia: (mapa['experiencia'] as List<dynamic>? ?? const [])
          .map((e) => ModeloExperienciaProfesional.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      instagram: mapa['instagram'] as String?,
      facebook: mapa['facebook'] as String?,
      linkedin: mapa['linkedin'] as String?,
      verificado: (mapa['verificado'] as bool?) ?? false,
      calificacionPromedio: (mapa['calificacionPromedio'] as num?)?.toDouble() ?? 0,
      cantidadResenas: (mapa['cantidadResenas'] as num?)?.toInt() ?? 0,
      telefonoProfesional: (mapa['telefonoProfesional'] as String?) ?? '',
      correoContacto: (mapa['correoContacto'] as String?) ?? '',
    );
  }

  /// Convierte este perfil a un mapa para guardarlo en Firestore.
  ///
  /// Deliberadamente NO incluye `calificacionPromedio` ni `cantidadResenas`:
  /// esos dos campos son responsabilidad exclusiva de la Cloud Function que
  /// recalcula las reseñas. Omitirlos aquí permite usar
  /// `set(..., SetOptions(merge: true))` desde el cliente sin pisar el
  /// valor que la función ya calculó.
  Map<String, dynamic> toMap() {
    return {
      // Redundante con el identificador del documento, pero se guarda para
      // que el documento sea autodescriptivo al inspeccionarlo en la consola
      // de Firebase. Las reglas impiden modificarlo después de la creación.
      'uid': uid,
      'nombreCompleto': nombreCompleto,
      'nombreBusqueda': nombreBusqueda,
      'fotoUrl': fotoUrl,
      'especialidad': especialidad.clave,
      'aniosExperiencia': aniosExperiencia,
      'ubicacionGeneral': ubicacionGeneral?.clave,
      'sector': sector,
      'direccionProfesional': direccionProfesional,
      'tarifa': tarifa,
      'descripcion': descripcion,
      'experiencia': experiencia.map((e) => e.toMap()).toList(),
      'instagram': instagram,
      'facebook': facebook,
      'linkedin': linkedin,
      'verificado': verificado,
      'telefonoProfesional': telefonoProfesional,
      'correoContacto': correoContacto,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
  }

  /// Indica si el abogado ya cuenta con al menos una reseña (no es un campo
  /// almacenado, se deriva de [cantidadResenas]).
  bool get tieneResenas => cantidadResenas > 0;

  /// Devuelve una copia de este perfil reemplazando solo los campos que el
  /// propio abogado puede editar. Los demás campos (identidad, verificación,
  /// calificación y cantidad de reseñas) los gestiona ManoLegal.
  ModeloPerfilPublicoAbogado copiarCon({
    String? fotoUrl,
    UbicacionCali? ubicacionGeneral,
    String? sector,
    String? direccionProfesional,
    double? tarifa,
    String? descripcion,
    List<ModeloExperienciaProfesional>? experiencia,
    String? instagram,
    String? facebook,
    String? linkedin,
    String? telefonoProfesional,
    String? correoContacto,
  }) {
    return ModeloPerfilPublicoAbogado(
      uid: uid,
      nombreCompleto: nombreCompleto,
      nombreBusqueda: nombreBusqueda,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      especialidad: especialidad,
      aniosExperiencia: aniosExperiencia,
      ubicacionGeneral: ubicacionGeneral ?? this.ubicacionGeneral,
      sector: sector ?? this.sector,
      direccionProfesional: direccionProfesional ?? this.direccionProfesional,
      tarifa: tarifa ?? this.tarifa,
      descripcion: descripcion ?? this.descripcion,
      experiencia: experiencia ?? this.experiencia,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      linkedin: linkedin ?? this.linkedin,
      verificado: verificado,
      calificacionPromedio: calificacionPromedio,
      cantidadResenas: cantidadResenas,
      telefonoProfesional: telefonoProfesional ?? this.telefonoProfesional,
      correoContacto: correoContacto ?? this.correoContacto,
    );
  }
}

/// Normaliza texto para búsqueda: minúsculas, sin tildes y sin espacios
/// sobrantes. Firestore no ofrece búsqueda de texto libre, así que el
/// nombre se almacena también normalizado para poder compararlo.
String normalizarTexto(String texto) {
  const remplazos = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var resultado = texto.toLowerCase().trim();
  remplazos.forEach((conTilde, sinTilde) {
    resultado = resultado.replaceAll(conTilde, sinTilde);
  });
  resultado = resultado.replaceAll(RegExp(r'\s+'), ' ');
  return resultado;
}
