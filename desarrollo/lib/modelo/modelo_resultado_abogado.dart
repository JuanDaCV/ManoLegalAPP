/// Modelo de PRESENTACIÓN para el buscador de abogados del panel del
/// cliente (sección Inicio).
///
/// Es el modelo que consume la tarjeta de resultados; no es el modelo de
/// datos real de Firestore (ese es [ModeloPerfilPublicoAbogado] en
/// `modelo_perfil_publico_abogado.dart`). Se construye a partir de un
/// [ModeloPerfilPublicoAbogado] mediante `aResultadoBusqueda`, definida en
/// `filtros_abogados.dart`.
class ModeloResultadoAbogado {
  final String uid;
  final String nombreCompleto;
  final String especialidad;
  final String ubicacion;
  final bool verificado;
  final double calificacion;

  /// Tarifa desde la que cobra el abogado. Es opcional porque declararla es
  /// opcional para el abogado; mostrar `$0` como si fuera una tarifa real
  /// sería incorrecto.
  final double? tarifaDesde;
  final String? fotoUrl;

  /// Cantidad de reseñas recibidas. Permite mostrar "Sin reseñas" en vez de
  /// una calificación inventada cuando todavía no hay ninguna.
  final int cantidadResenas;

  const ModeloResultadoAbogado({
    required this.uid,
    required this.nombreCompleto,
    required this.especialidad,
    required this.ubicacion,
    required this.verificado,
    required this.calificacion,
    this.tarifaDesde,
    this.fotoUrl,
    this.cantidadResenas = 0,
  });

  /// Indica si el abogado ya cuenta con al menos una reseña.
  bool get tieneResenas => cantidadResenas > 0;

  /// Iniciales del nombre completo (máximo 2 letras, en mayúscula), para
  /// mostrar en el avatar cuando no hay [fotoUrl].
  String get iniciales {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+')).where((parte) => parte.isNotEmpty).toList();
    if (partes.isEmpty) return '';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }
}
