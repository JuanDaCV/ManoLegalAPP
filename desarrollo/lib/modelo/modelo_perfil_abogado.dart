import 'modelo_abogado.dart';
import 'modelo_experiencia_profesional.dart';
import 'modelo_perfil_publico_abogado.dart';
import 'modelo_resena.dart';
import 'ubicacion_cali.dart';

/// Modelo de PRESENTACIÓN del perfil de un abogado. Lo consumen tanto la
/// pantalla "Mi perfil" del panel del abogado como el visualizador público
/// que ve el cliente.
///
/// No es un modelo de datos de Firestore. Existen dos orígenes reales y una
/// fábrica para cada uno:
///
///   - [ModeloPerfilAbogado.desdeAbogadoPrivado] parte de `abogados/{uid}`,
///     el documento privado que solo lee su dueño. Incluye la fecha de
///     nacimiento, así que la edad se puede mostrar.
///   - [ModeloPerfilAbogado.desdePerfilPublico] parte de
///     `perfilesPublicosAbogados/{uid}`. Ese documento no contiene la fecha
///     de nacimiento a propósito, de modo que [edad] queda en `null` y la
///     interfaz pública simplemente no muestra ese dato.
class ModeloPerfilAbogado {
  final String uid;
  final String nombreCompleto;

  /// Fecha de nacimiento, solo disponible cuando el perfil proviene del
  /// documento privado. Es `null` en el perfil público porque ese dato no se
  /// publica.
  final DateTime? fechaNacimiento;

  final String especialidad;
  final bool verificado;
  final String ubicacionGeneral;
  final String sector;
  final String direccion;
  final String sobreMi;
  final List<ModeloExperienciaProfesional> experiencia;
  final String? instagram;
  final String? facebook;
  final String? linkedin;

  /// Reseñas cargadas para mostrar en pantalla. No se usan para calcular el
  /// promedio: ese valor llega ya calculado en [calificacion].
  final List<ModeloResena> resenas;

  final String? fotoUrl;
  final double? tarifa;
  final String telefonoContacto;
  final String correoContacto;

  /// Promedio de calificación mantenido por la Cloud Function. NO se deriva
  /// de [resenas]: la lista mostrada puede estar paginada o incompleta, y
  /// promediarla daría un número distinto al real. Vale 0 si no hay reseñas.
  final double calificacion;

  /// Cantidad total de reseñas, también mantenida por la Cloud Function.
  final int cantidadResenas;

  const ModeloPerfilAbogado({
    required this.uid,
    required this.nombreCompleto,
    this.fechaNacimiento,
    required this.especialidad,
    required this.verificado,
    required this.ubicacionGeneral,
    required this.sector,
    required this.direccion,
    required this.sobreMi,
    required this.experiencia,
    this.instagram,
    this.facebook,
    this.linkedin,
    required this.resenas,
    this.fotoUrl,
    required this.tarifa,
    required this.telefonoContacto,
    required this.correoContacto,
    this.calificacion = 0,
    this.cantidadResenas = 0,
  });

  /// Construye el perfil a partir del documento privado del abogado. Los
  /// agregados de reputación no viven en ese documento, así que se reciben
  /// aparte: provienen del perfil público, que es donde los mantiene la
  /// Cloud Function.
  factory ModeloPerfilAbogado.desdeAbogadoPrivado(
    ModeloAbogado abogado, {
    List<ModeloResena> resenas = const [],
    double calificacion = 0,
    int cantidadResenas = 0,
  }) {
    return ModeloPerfilAbogado(
      uid: abogado.uid,
      nombreCompleto: '${abogado.nombre} ${abogado.apellido}',
      fechaNacimiento: abogado.fechaNacimiento,
      especialidad: abogado.especialidad.textoLegible,
      verificado: abogado.estado == 'verificado',
      ubicacionGeneral: abogado.ubicacionGeneral?.textoLegible ?? '',
      sector: abogado.sector,
      direccion: abogado.direccionProfesional,
      sobreMi: abogado.descripcion,
      experiencia: abogado.experiencia,
      instagram: abogado.instagram,
      facebook: abogado.facebook,
      linkedin: abogado.linkedin,
      resenas: resenas,
      fotoUrl: abogado.fotoPerfilRuta.isEmpty ? null : abogado.fotoPerfilRuta,
      tarifa: abogado.tarifa,
      telefonoContacto: abogado.telefonoProfesional,
      correoContacto: abogado.correoContacto.isEmpty ? abogado.correo : abogado.correoContacto,
      calificacion: calificacion,
      cantidadResenas: cantidadResenas,
    );
  }

  /// Construye el perfil a partir del documento público. [fechaNacimiento]
  /// queda en `null` porque ese documento no publica ese dato.
  factory ModeloPerfilAbogado.desdePerfilPublico(
    ModeloPerfilPublicoAbogado perfil, {
    List<ModeloResena> resenas = const [],
  }) {
    return ModeloPerfilAbogado(
      uid: perfil.uid,
      nombreCompleto: perfil.nombreCompleto,
      especialidad: perfil.especialidad.textoLegible,
      verificado: perfil.verificado,
      ubicacionGeneral: perfil.ubicacionGeneral?.textoLegible ?? '',
      sector: perfil.sector,
      direccion: perfil.direccionProfesional,
      sobreMi: perfil.descripcion,
      experiencia: perfil.experiencia,
      instagram: perfil.instagram,
      facebook: perfil.facebook,
      linkedin: perfil.linkedin,
      resenas: resenas,
      fotoUrl: perfil.fotoUrl,
      tarifa: perfil.tarifa,
      telefonoContacto: perfil.telefonoProfesional,
      correoContacto: perfil.correoContacto,
      calificacion: perfil.calificacionPromedio,
      cantidadResenas: perfil.cantidadResenas,
    );
  }

  /// Iniciales del nombre completo (máximo 2 letras, en mayúscula), para
  /// mostrar en el avatar cuando no hay [fotoUrl].
  String get iniciales {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+')).where((parte) => parte.isNotEmpty).toList();
    if (partes.isEmpty) return '';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }

  /// Edad actual calculada a partir de [fechaNacimiento]: resta 1 si todavía
  /// no se cumplieron años este año. Nunca se almacena como campo. Devuelve
  /// `null` cuando el perfil proviene del documento público, que no incluye
  /// la fecha de nacimiento.
  int? get edad {
    final fecha = fechaNacimiento;
    if (fecha == null) return null;
    final ahora = DateTime.now();
    var edadCalculada = ahora.year - fecha.year;
    final aunNoCumpleAnios =
        ahora.month < fecha.month || (ahora.month == fecha.month && ahora.day < fecha.day);
    if (aunNoCumpleAnios) edadCalculada--;
    return edadCalculada;
  }

  /// Indica si el abogado ya recibió al menos una reseña. Cuando es `false`
  /// la interfaz debe mostrar "Sin reseñas" y nunca una calificación
  /// inventada.
  bool get tieneResenas => cantidadResenas > 0;

  /// Fracción (0.0–1.0) de los campos editables del perfil que ya están
  /// completos (no es un campo almacenado). Cuentan: foto de perfil, "sobre
  /// mí", al menos una experiencia cargada, dirección, y al menos una red
  /// social enlazada.
  double get porcentajeCompletitud {
    const totalCampos = 5;
    var completos = 0;
    if (fotoUrl != null && fotoUrl!.isNotEmpty) completos++;
    if (sobreMi.trim().isNotEmpty) completos++;
    if (experiencia.isNotEmpty) completos++;
    if (direccion.trim().isNotEmpty) completos++;
    if (tieneAlgunaRed) completos++;
    return completos / totalCampos;
  }

  /// Verdadero si hay al menos una red social configurada. Trata una cadena
  /// vacía igual que un valor ausente: al borrar el texto de una red, el
  /// formulario envía una cadena vacía, no `null`.
  bool get tieneAlgunaRed {
    return _tieneValor(instagram) || _tieneValor(facebook) || _tieneValor(linkedin);
  }

  static bool _tieneValor(String? valor) => valor != null && valor.trim().isNotEmpty;

  /// Devuelve una copia de este perfil reemplazando solo los campos
  /// editables que se indiquen. Los demás campos (nombre, fecha de
  /// nacimiento, especialidad, verificación, calificación y cantidad de
  /// reseñas) los gestiona ManoLegal y no se editan desde aquí.
  ModeloPerfilAbogado copiarCon({
    String? sobreMi,
    List<ModeloExperienciaProfesional>? experiencia,
    String? ubicacionGeneral,
    String? sector,
    String? direccion,
    String? instagram,
    String? facebook,
    String? linkedin,
    String? fotoUrl,
    double? tarifa,
    List<ModeloResena>? resenas,
  }) {
    return ModeloPerfilAbogado(
      uid: uid,
      nombreCompleto: nombreCompleto,
      fechaNacimiento: fechaNacimiento,
      especialidad: especialidad,
      verificado: verificado,
      ubicacionGeneral: ubicacionGeneral ?? this.ubicacionGeneral,
      sector: sector ?? this.sector,
      direccion: direccion ?? this.direccion,
      sobreMi: sobreMi ?? this.sobreMi,
      experiencia: experiencia ?? this.experiencia,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      linkedin: linkedin ?? this.linkedin,
      resenas: resenas ?? this.resenas,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      tarifa: tarifa ?? this.tarifa,
      telefonoContacto: telefonoContacto,
      correoContacto: correoContacto,
      calificacion: calificacion,
      cantidadResenas: cantidadResenas,
    );
  }
}

/// Convierte la etiqueta legible de una ubicación de vuelta al enum, para
/// poder guardar en Firestore lo que el abogado eligió en "Mi perfil".
/// Devuelve `null` si el texto no corresponde a ninguna zona conocida.
UbicacionCali? ubicacionDesdeTextoLegible(String texto) {
  final buscado = texto.trim().toLowerCase();
  for (final valor in UbicacionCali.values) {
    if (valor.textoLegible.toLowerCase() == buscado) return valor;
  }
  return null;
}
