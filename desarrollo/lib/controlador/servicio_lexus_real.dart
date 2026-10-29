import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../configuracion/configuracion_lexus.dart';
import '../configuracion/instrucciones_lexus.dart';
import '../modelo/error_lexus.dart';
import '../modelo/modelo_mensaje_lexus.dart';
import 'servicio_lexus.dart';

/// Implementación de [ServicioLexus] sobre Firebase AI Logic (Gemini
/// Developer API). Es el único archivo que importa `firebase_ai`.
class ServicioLexusReal implements ServicioLexus {
  ServicioLexusReal({this._crearModelo});

  final GenerativeModel Function()? _crearModelo;

  /// Se crea en el primer envío: tocar Firebase al construir la clase la
  /// haría fallar en cualquier prueba o pantalla que no lo haya inicializado.
  late final GenerativeModel _modelo =
      _crearModelo?.call() ??
      FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true).generativeModel(
        model: ConfiguracionLexus.modelo,
        systemInstruction: Content.system(instruccionesLexus),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: esquemaRespuestaLexus,
          maxOutputTokens: ConfiguracionLexus.maxTokensSalida,
        ),
      );

  static const Set<FinishReason> _motivosDeBloqueo = {
    FinishReason.safety,
    FinishReason.recitation,
    FinishReason.blocklist,
    FinishReason.prohibitedContent,
    FinishReason.spii,
  };

  @override
  Future<String> enviar({
    required List<TurnoLexus> historial,
    required String mensaje,
  }) async {
    try {
      final contenidos = <Content>[
        for (final turno in historial)
          turno.esUsuario
              ? Content('user', [TextPart(turno.texto)])
              : Content.model([TextPart(turno.texto)]),
        Content('user', [TextPart(mensaje)]),
      ];
      final respuesta = await _modelo
          .generateContent(contenidos)
          .timeout(ConfiguracionLexus.tiempoLimiteRespuesta);

      final candidatos = respuesta.candidates;
      if (candidatos.isEmpty && respuesta.promptFeedback?.blockReason != null) {
        throw const ErrorLexus(TipoErrorLexus.bloqueoSeguridad);
      }
      if (candidatos.isNotEmpty &&
          _motivosDeBloqueo.contains(candidatos.first.finishReason)) {
        throw const ErrorLexus(TipoErrorLexus.bloqueoSeguridad);
      }

      final String? texto;
      try {
        texto = respuesta.text;
      } catch (e) {
        throw ErrorLexus(
          e.toString().toLowerCase().contains('blocked')
              ? TipoErrorLexus.bloqueoSeguridad
              : TipoErrorLexus.respuestaInvalida,
        );
      }
      if (texto == null || texto.trim().isEmpty) {
        throw const ErrorLexus(TipoErrorLexus.respuestaInvalida);
      }
      return texto;
    } catch (e) {
      final error = mapearErrorLexus(e);
      debugPrint('Lexus: error tipo=${error.tipo.name}');
      throw error;
    }
  }
}

/// Traduce cualquier fallo del SDK o de la red a un [ErrorLexus]. Es pura y
/// no registra el mensaje original: puede contener texto de la conversación.
///
/// La comprobación de App Check va antes que la de [ServerException] porque
/// el rechazo llega como un `ServerException` genérico sin tipo propio.
ErrorLexus mapearErrorLexus(Object error) {
  if (error is ErrorLexus) return error;
  if (error is TimeoutException) {
    return const ErrorLexus(TipoErrorLexus.tiempoAgotado);
  }
  if (error is http.ClientException) {
    return const ErrorLexus(TipoErrorLexus.sinConexion);
  }
  if (error is QuotaExceeded) {
    return const ErrorLexus(TipoErrorLexus.cuotaExcedida);
  }
  if (error is ServiceApiNotEnabled ||
      error is InvalidApiKey ||
      error is UnsupportedUserLocation) {
    return const ErrorLexus(TipoErrorLexus.modeloNoDisponible);
  }

  final texto = error.toString().toLowerCase();
  bool contiene(List<String> fragmentos) => fragmentos.any(texto.contains);

  // Sin red, obtener el token de App Check también falla y su mensaje lo
  // nombra: la falta de conexión se decide antes para no confundirla con un
  // rechazo de App Check.
  if (contiene(const [
    'failed host lookup',
    'failed to fetch',
    'fetch-network-error',
    'network',
    'xmlhttprequest',
    'socketexception',
    'connection',
  ])) {
    return const ErrorLexus(TipoErrorLexus.sinConexion);
  }
  if (contiene(const [
    'app check',
    'appcheck',
    'app_check',
    'unauthenticated',
  ])) {
    return const ErrorLexus(TipoErrorLexus.appCheckRechazado);
  }
  if (error is FirebaseAIException) {
    // Saldo de facturación agotado: no se resuelve esperando unos minutos.
    if (contiene(const [
      'prepayment',
      'credits are depleted',
      'billing',
      'payment required',
    ])) {
      return const ErrorLexus(TipoErrorLexus.modeloNoDisponible);
    }
    if (contiene(const ['quota', 'resource_exhausted', '429'])) {
      return const ErrorLexus(TipoErrorLexus.cuotaExcedida);
    }
    if (contiene(const [
          'not found',
          'not_found',
          'is not supported',
          'api_key_service_blocked',
          'permission_denied',
        ]) ||
        error.message.toLowerCase().startsWith('server error [5')) {
      return const ErrorLexus(TipoErrorLexus.modeloNoDisponible);
    }
  }
  if (error is FormatException || error is FirebaseAISdkException) {
    return const ErrorLexus(TipoErrorLexus.respuestaInvalida);
  }
  if (contiene(const [
    'failed host lookup',
    'network',
    'xmlhttprequest',
    'socketexception',
    'connection',
  ])) {
    return const ErrorLexus(TipoErrorLexus.sinConexion);
  }
  return const ErrorLexus(TipoErrorLexus.interno);
}
