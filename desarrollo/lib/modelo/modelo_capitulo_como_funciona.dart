/// Un capítulo de la guía en video "Cómo funciona ManoLegal".
///
/// Los datos viven en código y no en Firestore porque los videos son assets
/// empaquetados con la app: cambiar un capítulo implica reemplazar el archivo
/// y actualizar su ficha aquí. Por eso la ficha guarda también el tamaño real
/// del video: el reproductor reserva su marco antes de cargarlo y el diseño no
/// se mueve cuando el video llega. La proporción importa de verdad, porque el
/// capítulo 2 está grabado en vertical (9:16) y los demás en horizontal (16:9).
class ModeloCapituloComoFunciona {
  /// Posición del capítulo en la guía, desde 1.
  final int numero;
  final String titulo;

  /// Resumen de lo que muestra el video, en un par de frases.
  final String descripcion;

  /// Tres ideas clave del capítulo, para escanear antes de reproducir.
  final List<String> temas;

  /// Ruta del video dentro de los assets.
  final String rutaVideo;

  /// Ruta de la portada (primer fotograma del video), que se ve antes de
  /// reproducir. Así no se descarga ni se decodifica ningún video hasta que
  /// el usuario lo pide.
  final String rutaPortada;

  final Duration duracion;

  /// Tamaño real del video en píxeles.
  final int anchoPx;
  final int altoPx;

  const ModeloCapituloComoFunciona({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.temas,
    required this.rutaVideo,
    required this.rutaPortada,
    required this.duracion,
    required this.anchoPx,
    required this.altoPx,
  });

  /// Ancho dividido entre alto: 16/9 en horizontal, 9/16 en vertical.
  double get proporcion => anchoPx / altoPx;

  bool get esVertical => altoPx > anchoPx;

  /// Número con dos cifras, como se ve en pantalla: '01', '02'…
  String get numeroTexto => numero.toString().padLeft(2, '0');

  /// Los videos no duran segundos exactos (49,81 s). Se redondea al segundo
  /// más cercano para que lo mostrado y lo leído en voz alta coincidan.
  int get _segundosRedondeados => (duracion.inMilliseconds / 1000).round();

  /// Duración para mostrar en pantalla, como '0:25' o '1:03'.
  String get duracionTexto {
    final total = _segundosRedondeados;
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  /// Duración para lectores de pantalla: '25 segundos', '1 minuto y 3
  /// segundos'. Leer '1:03' en voz alta es ambiguo; la frase completa no.
  String get duracionHablada {
    final total = _segundosRedondeados;
    final minutos = total ~/ 60;
    final segundos = total % 60;
    final textoMinutos = minutos == 1 ? '1 minuto' : '$minutos minutos';
    final textoSegundos = segundos == 1 ? '1 segundo' : '$segundos segundos';
    if (minutos == 0) return textoSegundos;
    if (segundos == 0) return textoMinutos;
    return '$textoMinutos y $textoSegundos';
  }

  /// Etiqueta del botón de reproducir para lectores de pantalla. Incluye el
  /// título y la duración: es lo único que oye quien no ve la portada.
  String get etiquetaReproducir => 'Reproducir video: $titulo. Duración: $duracionHablada.';
}

const String _carpetaVideos = 'video/como_funciona';
const String _carpetaPortadas = 'video/como_funciona/portadas';

/// Los seis capítulos, en el orden en que se recomienda verlos.
const List<ModeloCapituloComoFunciona> capitulosComoFunciona = [
  ModeloCapituloComoFunciona(
    numero: 1,
    titulo: '¿Qué es ManoLegal?',
    descripcion:
        'Un recorrido breve, con música y textos en pantalla, por la plataforma que te ayuda a encontrar '
        'orientación jurídica en Cali: filtra abogados, compara perfiles, identifica los verificados y '
        'contáctalos por WhatsApp o correo.',
    temas: ['Búsqueda y filtros', 'Perfiles verificados', 'Contacto directo'],
    rutaVideo: '$_carpetaVideos/video_01_que_es_manolegal.mp4',
    rutaPortada: '$_carpetaPortadas/video_01_que_es_manolegal.jpg',
    duracion: Duration(milliseconds: 25000),
    anchoPx: 1920,
    altoPx: 1080,
  ),
  ModeloCapituloComoFunciona(
    numero: 2,
    titulo: '¿Cómo encontrar un abogado?',
    descripcion:
        'Desde que abres ManoLegal hasta la lista de abogados: ingresas a tu cuenta, recorres el Inicio y llegas '
        'a los resultados, donde ves la especialidad, la valoración, la ubicación, la tarifa y la verificación '
        'de cada perfil.',
    temas: ['Ingreso a tu cuenta', 'Inicio y buscador', 'Lista de abogados'],
    rutaVideo: '$_carpetaVideos/video_02_encontrar_abogado.mp4',
    rutaPortada: '$_carpetaPortadas/video_02_encontrar_abogado.jpg',
    duracion: Duration(milliseconds: 49810),
    anchoPx: 1080,
    altoPx: 1920,
  ),
  ModeloCapituloComoFunciona(
    numero: 3,
    titulo: '¿Cómo funciona la selección?',
    descripcion:
        'ManoLegal no elige por ti: compara en la lista la especialidad, la calificación, la ubicación y la '
        'tarifa, y abre el perfil para revisar la verificación, la experiencia y las reseñas antes de decidir.',
    temas: ['Comparar resultados', 'Perfil del abogado', 'La decisión es tuya'],
    rutaVideo: '$_carpetaVideos/video_03_como_funciona_la_seleccion.mp4',
    rutaPortada: '$_carpetaPortadas/video_03_como_funciona_la_seleccion.jpg',
    duracion: Duration(milliseconds: 48000),
    anchoPx: 1920,
    altoPx: 1080,
  ),
  ModeloCapituloComoFunciona(
    numero: 4,
    titulo: '¿Qué significa que un abogado esté verificado?',
    descripcion:
        'La insignia indica que el abogado presentó su documentación profesional, como la tarjeta profesional y '
        'el certificado de vigencia, y que el equipo de ManoLegal la revisó. No es una recomendación ni una '
        'garantía de resultado.',
    temas: ['Insignia «Verificado»', 'Revisión documental', 'Tarjeta profesional y vigencia'],
    rutaVideo: '$_carpetaVideos/video_04_que_significa_abogado_verificado.mp4',
    rutaPortada: '$_carpetaPortadas/video_04_que_significa_abogado_verificado.jpg',
    duracion: Duration(milliseconds: 52800),
    anchoPx: 1920,
    altoPx: 1080,
  ),
  ModeloCapituloComoFunciona(
    numero: 5,
    titulo: '¿Cómo funciona el contacto?',
    descripcion:
        'Desde el perfil puedes escribirle al abogado por WhatsApp, que abre la conversación con su número, o por '
        'correo, que se abre con un asunto y un saludo ya escritos. ManoLegal facilita el contacto; el acuerdo '
        'es entre tú y el abogado.',
    temas: ['WhatsApp', 'Correo electrónico', 'Acuerdo entre las partes'],
    rutaVideo: '$_carpetaVideos/video_05_como_funciona_el_contacto.mp4',
    rutaPortada: '$_carpetaPortadas/video_05_como_funciona_el_contacto.jpg',
    duracion: Duration(milliseconds: 63020),
    anchoPx: 1920,
    altoPx: 1080,
  ),
  ModeloCapituloComoFunciona(
    numero: 6,
    titulo: '¿Qué debe tener en cuenta un cliente?',
    descripcion:
        'Revisa la especialidad y la experiencia antes de contactar, y recuerda que la calificación refleja la '
        'opinión de otros usuarios, no una garantía de resultado. Si necesitas presentar una petición, queja, '
        'reclamo o solicitud, usa PQRS y guarda tu número de radicado.',
    temas: ['Antes de contactar', 'PQRS', 'Número de radicado'],
    rutaVideo: '$_carpetaVideos/video_06_que_debe_tener_en_cuenta_un_cliente.mp4',
    rutaPortada: '$_carpetaPortadas/video_06_que_debe_tener_en_cuenta_un_cliente.jpg',
    duracion: Duration(milliseconds: 72810),
    anchoPx: 1920,
    altoPx: 1080,
  ),
];

/// Duración de toda la guía: suma de los seis capítulos.
Duration get duracionTotalComoFunciona =>
    capitulosComoFunciona.fold(Duration.zero, (suma, capitulo) => suma + capitulo.duracion);
