import '../modelo/modelo_abogado.dart';
import '../modelo/modelo_perfil_publico_abogado.dart' show normalizarTexto;

// =============================================================================
// Lógica pura del panel de administrador.
//
// Nada en este archivo toca Firebase ni Flutter: recibe la lista de abogados
// que ya entrega el stream en tiempo real de [ControladorAdministrador] y la
// resume, filtra u ordena en memoria. Por eso se puede probar sin emuladores.
//
// Decisión documentada: la búsqueda y los filtros del panel se aplican en
// memoria sobre el stream completo de `abogados`, en lugar de lanzar consultas
// nuevas a Firestore. Con el volumen actual es lo más simple y no añade
// lecturas. Si el directorio crece a miles de abogados, la consulta de
// `ServicioFirestore.observarAbogados()` necesitará `limit()` y paginación por
// cursor del lado del servidor.
// =============================================================================

/// Un abogado cuenta como verificado solo si su estado es exactamente
/// `verificado`. Cualquier otro valor, incluido uno desconocido, se trata
/// como pendiente: el panel nunca presume una verificación que no existe.
bool estaVerificado(ModeloAbogado abogado) => abogado.estado == 'verificado';

/// Conteo de verificación del directorio completo.
class ResumenVerificacion {
  final int total;
  final int verificados;

  const ResumenVerificacion({required this.total, required this.verificados});

  int get pendientes => total - verificados;

  /// Fracción verificada, entre 0 y 1. Vale 0 cuando no hay abogados.
  double get proporcionVerificados => total == 0 ? 0 : verificados / total;

  /// Porcentajes enteros de verificados y pendientes.
  ///
  /// Siempre suman 100, salvo con cero abogados, donde ambos valen 0. Una
  /// categoría con al menos un abogado nunca se muestra como 0 %, y una que
  /// no es la única nunca se muestra como 100 %: redondear 1 de 300 a "0 %"
  /// ocultaría a ese abogado en el gráfico.
  (int, int) get porcentajes {
    if (total == 0) return (0, 0);
    var verificadosPorCiento = (verificados * 100 / total).round();
    if (verificados > 0 && verificadosPorCiento == 0) verificadosPorCiento = 1;
    if (pendientes > 0 && verificadosPorCiento == 100) verificadosPorCiento = 99;
    return (verificadosPorCiento, 100 - verificadosPorCiento);
  }
}

ResumenVerificacion calcularResumen(List<ModeloAbogado> abogados) {
  return ResumenVerificacion(
    total: abogados.length,
    verificados: abogados.where(estaVerificado).length,
  );
}

/// Filtro de estado disponible en el listado del administrador.
enum FiltroEstadoAbogado { todos, verificados, pendientes }

/// Filtra en memoria por texto, estado y especialidad. Los tres criterios se
/// combinan con Y lógico.
///
/// El texto se compara sin tildes ni mayúsculas contra nombre completo,
/// correo, UID, teléfono y especialidad.
List<ModeloAbogado> filtrarAbogados(
  List<ModeloAbogado> abogados, {
  String texto = '',
  FiltroEstadoAbogado estado = FiltroEstadoAbogado.todos,
  EspecialidadAbogado? especialidad,
}) {
  final busqueda = normalizarTexto(texto);

  return abogados.where((abogado) {
    if (estado == FiltroEstadoAbogado.verificados && !estaVerificado(abogado)) return false;
    if (estado == FiltroEstadoAbogado.pendientes && estaVerificado(abogado)) return false;
    if (especialidad != null && abogado.especialidad != especialidad) return false;
    if (busqueda.isEmpty) return true;

    final campos = [
      '${abogado.nombre} ${abogado.apellido}',
      abogado.correo,
      abogado.uid,
      abogado.telefono,
      abogado.especialidad.textoLegible,
    ];
    return campos.any((campo) => normalizarTexto(campo).contains(busqueda));
  }).toList();
}

/// Ordena para la revisión administrativa: primero los pendientes, que son
/// los que requieren acción, y dentro de cada grupo por apellido y nombre.
List<ModeloAbogado> ordenarParaRevision(List<ModeloAbogado> abogados) {
  final copia = List<ModeloAbogado>.of(abogados);
  copia.sort((a, b) {
    final porEstado = (estaVerificado(a) ? 1 : 0).compareTo(estaVerificado(b) ? 1 : 0);
    if (porEstado != 0) return porEstado;
    final porApellido = normalizarTexto(a.apellido).compareTo(normalizarTexto(b.apellido));
    if (porApellido != 0) return porApellido;
    return normalizarTexto(a.nombre).compareTo(normalizarTexto(b.nombre));
  });
  return copia;
}

/// Un documento de verificación tal como lo muestra el panel.
class DocumentoVerificacion {
  final String etiqueta;
  final String? ruta;
  final bool obligatorio;

  const DocumentoVerificacion({required this.etiqueta, required this.ruta, required this.obligatorio});

  /// Indica que Firestore registra una ruta para este documento. No prueba
  /// que el archivo exista en Storage: eso se comprueba aparte, en el
  /// detalle, leyendo sus metadatos.
  bool get tieneRuta => ruta != null && ruta!.trim().isNotEmpty;
}

/// Los cinco documentos de verificación, en el orden en que se piden en el
/// registro. El diploma es el único opcional.
List<DocumentoVerificacion> documentosDeVerificacion(ModeloAbogado abogado) {
  final documentos = abogado.documentos;
  return [
    DocumentoVerificacion(etiqueta: 'Cédula de ciudadanía', ruta: documentos.cedulaRuta, obligatorio: true),
    DocumentoVerificacion(
      etiqueta: 'Tarjeta profesional',
      ruta: documentos.tarjetaProfesionalRuta,
      obligatorio: true,
    ),
    DocumentoVerificacion(
      etiqueta: 'Certificado de vigencia RNA',
      ruta: documentos.certificadoRnaRuta,
      obligatorio: true,
    ),
    DocumentoVerificacion(etiqueta: 'Diploma de pregrado', ruta: documentos.diplomaRuta, obligatorio: false),
    DocumentoVerificacion(
      etiqueta: 'Antecedentes disciplinarios',
      ruta: documentos.antecedentesRuta,
      obligatorio: true,
    ),
  ];
}

/// Resumen de la documentación registrada de un abogado.
class EstadoDocumentacion {
  static const int obligatoriosTotal = 4;

  final int obligatoriosCargados;
  final bool diplomaCargado;

  const EstadoDocumentacion({required this.obligatoriosCargados, required this.diplomaCargado});

  bool get completa => obligatoriosCargados == obligatoriosTotal;

  /// Texto corto para la tabla, por ejemplo `4/4 · +Diploma`.
  String get resumen => '$obligatoriosCargados/$obligatoriosTotal${diplomaCargado ? ' · +Diploma' : ''}';
}

EstadoDocumentacion estadoDocumentacion(ModeloAbogado abogado) {
  final documentos = documentosDeVerificacion(abogado);
  return EstadoDocumentacion(
    obligatoriosCargados: documentos.where((documento) => documento.obligatorio && documento.tieneRuta).length,
    diplomaCargado: documentos.any((documento) => !documento.obligatorio && documento.tieneRuta),
  );
}

/// Primeros ocho caracteres del UID, suficientes para distinguirlo en una
/// tabla. El UID completo sigue disponible para copiar.
String abreviarUid(String uid) => uid.length <= 8 ? uid : '${uid.substring(0, 8)}…';

/// Tamaño legible de un archivo, con coma decimal: `850 KB`, `1,2 MB`.
String formatearTamanio(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}
