import 'package:flutter/foundation.dart';

import '../../../../configuracion/respuestas_locales_lexus.dart';
import '../../../../controlador/controlador_dictado_lexus.dart';
import '../../../../modelo/error_lexus.dart';

/// Textos del dictado por voz de Lexus.
abstract final class TextosDictadoLexus {
  static const String tituloPermiso = 'Activa el micrófono';
  static const String botonEntendido = 'Entendido';

  static const String dictar = 'Dictar consulta';
  static const String detenerDictado = 'Detener y transcribir';
  static const String cancelar = 'Cancelar';
  static const String cancelarDictado = 'Cancelar grabación';
  static const String grabando = 'Grabando';
  static const String transcribiendo = 'Transcribiendo…';
  static const String pidiendoPermiso = 'Esperando el permiso del micrófono…';

  static const String mensajeNoDisponible =
      'No se pudo usar el micrófono. Revisa que tu dispositivo tenga uno disponible o escribe tu consulta.';
  static const String mensajeMuyCorto =
      'La grabación fue muy corta y se descartó. Habla un poco más antes de detenerla o escribe tu consulta.';
  static const String mensajeSinTexto =
      'No se entendió ninguna palabra. Acércate al micrófono e inténtalo de nuevo, o escribe tu consulta.';
  static const String mensajeTranscripcionFallida =
      'No se pudo transcribir el audio. Inténtalo de nuevo o escribe tu consulta.';

  /// Cuenta atrás con minutos y segundos, por ejemplo «1:45». Los segundos
  /// parciales se redondean hacia arriba para que «0:00» solo aparezca al
  /// terminar.
  static String cuentaAtras(Duration restante) {
    final segundos = (restante.inMilliseconds / 1000).ceil().clamp(0, 86399);
    final minutos = segundos ~/ 60;
    final resto = (segundos % 60).toString().padLeft(2, '0');
    return '$minutos:$resto';
  }

  /// Mensaje para un fallo que no es de permiso (ese se explica con un
  /// diálogo). Para fallos de la transcripción reutiliza los textos de Lexus
  /// que describen el mismo problema.
  static String mensajeDeError(ErrorDictadoLexus error) {
    switch (error.tipo) {
      case TipoErrorDictadoLexus.permisoDenegado:
        return instruccionesPermisoMicrofono(
          esWeb: kIsWeb,
          plataforma: defaultTargetPlatform,
        );
      case TipoErrorDictadoLexus.noDisponible:
        return mensajeNoDisponible;
      case TipoErrorDictadoLexus.demasiadoCorto:
        return mensajeMuyCorto;
      case TipoErrorDictadoLexus.sinTexto:
        return mensajeSinTexto;
      case TipoErrorDictadoLexus.transcripcionFallida:
        final causa = error.causa;
        return switch (causa) {
          TipoErrorLexus.sinConexion ||
          TipoErrorLexus.tiempoAgotado ||
          TipoErrorLexus.cuotaExcedida ||
          TipoErrorLexus.appCheckRechazado ||
          TipoErrorLexus.modeloNoDisponible =>
            RespuestasLocalesLexus.mensajeParaError(causa!),
          _ => mensajeTranscripcionFallida,
        };
    }
  }
}

/// Pasos para volver a permitir el micrófono, según dónde se ejecuta la app.
/// Siempre recuerda que la persona puede seguir escribiendo mientras tanto.
String instruccionesPermisoMicrofono({
  required bool esWeb,
  required TargetPlatform plataforma,
}) {
  const seguirEscribiendo =
      'Mientras tanto puedes seguir escribiendo tu consulta.';
  final String pasos;
  if (esWeb) {
    pasos =
        'Pulsa el icono que está junto a la dirección del sitio (el candado o '
        'los ajustes del sitio), permite el uso del micrófono e inténtalo de '
        'nuevo. Si no cambia, recarga la página.';
  } else {
    switch (plataforma) {
      case TargetPlatform.android:
        pasos =
            'Ve a Ajustes > Aplicaciones > ManoLegal > Permisos > Micrófono y '
            'permite el acceso.';
      case TargetPlatform.iOS:
        pasos = 'Ve a Ajustes > ManoLegal > Micrófono y permite el acceso.';
      case TargetPlatform.fuchsia ||
          TargetPlatform.linux ||
          TargetPlatform.macOS ||
          TargetPlatform.windows:
        pasos =
            'Abre los ajustes de privacidad de tu sistema y permite que '
            'ManoLegal use el micrófono.';
    }
  }
  return 'No tenemos permiso para usar el micrófono. $pasos '
      '$seguirEscribiendo';
}
