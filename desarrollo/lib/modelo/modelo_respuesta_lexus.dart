import 'dart:convert';

import '../configuracion/configuracion_lexus.dart';
import 'error_lexus.dart';
import 'especialidad_abogado.dart';

/// Clasificación que el modelo hace del mensaje de la persona.
enum AmbitoLexus {
  juridico('juridico'),
  manolegal('manolegal'),
  fueraDeAlcance('fuera_de_alcance'),
  intentoDeManipulacion('intento_de_manipulacion');

  const AmbitoLexus(this.clave);

  final String clave;

  /// Devuelve `null` si [valor] no es una clave conocida.
  static AmbitoLexus? desdeClave(Object? valor) {
    for (final ambito in values) {
      if (ambito.clave == valor) return ambito;
    }
    return null;
  }
}

/// Respuesta estructurada de Lexus ya validada.
class ModeloRespuestaLexus {
  const ModeloRespuestaLexus({
    required this.respuesta,
    required this.ambito,
    required this.areaProbable,
    required this.urgente,
    required this.sugerirAbogados,
    required this.preguntasPendientes,
  });

  final String respuesta;
  final AmbitoLexus ambito;
  final EspecialidadAbogado? areaProbable;
  final bool urgente;
  final bool sugerirAbogados;
  final List<String> preguntasPendientes;

  /// Interpreta el JSON crudo del modelo. Es estricto con lo que decide el
  /// comportamiento de la aplicación (ámbito y texto) y tolerante con lo
  /// accesorio: un área desconocida es `null`, no «otra», para no mostrar un
  /// botón de abogados que el modelo no pidió.
  ///
  /// Lanza [ErrorLexus] con [TipoErrorLexus.respuestaInvalida] si no se puede
  /// usar.
  static ModeloRespuestaLexus desdeJson(String crudo) {
    final Object? decodificado;
    try {
      decodificado = jsonDecode(_sinCercas(crudo));
    } on FormatException {
      throw const ErrorLexus(TipoErrorLexus.respuestaInvalida);
    }
    if (decodificado is! Map) {
      throw const ErrorLexus(TipoErrorLexus.respuestaInvalida);
    }

    final ambito = AmbitoLexus.desdeClave(decodificado['ambito']);
    if (ambito == null) {
      throw const ErrorLexus(TipoErrorLexus.respuestaInvalida);
    }

    final texto = decodificado['respuesta'];
    final requiereTexto =
        ambito == AmbitoLexus.juridico || ambito == AmbitoLexus.manolegal;
    if (requiereTexto && (texto is! String || texto.trim().isEmpty)) {
      throw const ErrorLexus(TipoErrorLexus.respuestaInvalida);
    }

    return ModeloRespuestaLexus(
      respuesta: texto is String ? _recortar(texto.trim()) : '',
      ambito: ambito,
      areaProbable: _area(decodificado['area_probable']),
      urgente: decodificado['urgente'] == true,
      sugerirAbogados: decodificado['sugerir_abogados'] == true,
      preguntasPendientes: _preguntas(decodificado['preguntas_pendientes']),
    );
  }

  static String _sinCercas(String crudo) {
    final coincidencia = RegExp(r'^\s*```(?:json)?\s*([\s\S]*?)\s*```\s*$')
        .firstMatch(crudo);
    return coincidencia?.group(1) ?? crudo;
  }

  static EspecialidadAbogado? _area(Object? valor) {
    for (final area in EspecialidadAbogado.values) {
      if (area.clave == valor) return area;
    }
    return null;
  }

  static List<String> _preguntas(Object? valor) {
    if (valor is! List) return const [];
    return [
      for (final pregunta in valor)
        if (pregunta is String && pregunta.trim().isNotEmpty) pregunta.trim(),
    ].take(3).toList();
  }

  static String _recortar(String texto) {
    const maximo = ConfiguracionLexus.largoMaximoRespuesta;
    if (texto.length <= maximo) return texto;
    var corte = texto.substring(0, maximo - 1);
    final ultimoEspacio = corte.lastIndexOf(RegExp(r'\s'));
    if (ultimoEspacio > 0) corte = corte.substring(0, ultimoEspacio);
    return '${corte.trimRight()}…';
  }
}
