import '../configuracion/instrucciones_lexus.dart';

// El control del alcance también es local porque las instrucciones de sistema
// pueden filtrarse y un modelo puede ser manipulado. Estos filtros son una
// primera capa barata, no la única: el modelo clasifica el ámbito y la
// aplicación decide qué texto mostrar (ver `ControladorLexus`).

const Map<String, String> _equivalencias = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'ñ': 'n',
};

String _normalizar(String texto, {bool quitarPuntuacion = false}) {
  final buffer = StringBuffer();
  for (final caracter in texto.toLowerCase().split('')) {
    buffer.write(_equivalencias[caracter] ?? caracter);
  }
  var resultado = buffer.toString();
  if (quitarPuntuacion) {
    resultado = resultado.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  }
  return resultado.replaceAll(RegExp(r'\s+'), ' ').trim();
}

// Los patrones se evalúan sobre texto normalizado (minúsculas, sin tildes ni
// puntuación). Los de "ignora ..." exigen una referencia a las reglas del
// asistente para no confundir "mi jefe ignora las reglas del contrato".
final List<RegExp> _patronesDeManipulacion = [
  RegExp(
    r'\bignor(?:a|ar|es) (?:todas )?(?:tus|las) (?:instrucciones|reglas) (?:anteriores|previas|del sistema|de lexus)\b',
  ),
  RegExp(r'\bignor(?:a|ar|es) (?:todas )?tus (?:instrucciones|reglas)\b'),
  RegExp(r'\bignor(?:a|ar|es) todo lo anterior\b'),
  RegExp(
    r'\bolvida (?:que eres|tus instrucciones|tus reglas|tu rol|todo lo anterior)\b',
  ),
  RegExp(
    r'\b(?:muestrame|dime|revela|ensename|repite|cual es|cuales son) (?:tu|tus|el|las) '
    r'(?:prompt|instrucciones|configuracion|reglas internas)\b'
    r'(?!\s+(?:de|del|para|que)\b(?!\s+(?:sistema|lexus)\b))',
  ),
  RegExp(r'\bprompt del sistema\b'),
  RegExp(r'\bsystem prompt\b'),
  RegExp(r'\binstrucciones del sistema\b'),
  RegExp(
    r'\bactua como (?:otro|otra|un asistente|chatgpt|gemini|si no fueras)\b',
  ),
  RegExp(r'\b(?:modo|mode) (?:desarrollador|developer|dan|jailbreak)\b'),
  RegExp(r'\bya no eres lexus\b'),
  RegExp(r'\bdime todo lo que tienes configurado\b'),
];

/// Indica si el mensaje de la persona intenta cambiar las reglas de Lexus o
/// revelar su configuración.
bool pareceIntentoDeManipulacion(String texto) {
  final normalizado = _normalizar(texto, quitarPuntuacion: true);
  return _patronesDeManipulacion.any((patron) => patron.hasMatch(normalizado));
}

/// Encabezados de las instrucciones que una respuesta normal no repite junto
/// a otro encabezado.
const List<String> _encabezadosDeInstrucciones = [
  'no eres:',
  'jurisdiccion:',
  'clasificacion:',
  'derivacion:',
  'comportamiento:',
];

/// Indica si la respuesta del modelo parece copiar sus propias instrucciones.
bool revelaInstrucciones(String respuesta) {
  final normalizada = _normalizar(respuesta);
  if (frasesDistintivasInstrucciones.any(
    (frase) => normalizada.contains(_normalizar(frase)),
  )) {
    return true;
  }
  final encabezados = _encabezadosDeInstrucciones
      .where(normalizada.contains)
      .length;
  return encabezados >= 2;
}
