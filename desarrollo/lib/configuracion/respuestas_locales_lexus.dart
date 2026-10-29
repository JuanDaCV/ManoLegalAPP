import '../modelo/error_lexus.dart';
import '../modelo/especialidad_abogado.dart';

/// Textos fijos de Lexus. Los que se muestran en lugar de una respuesta del
/// modelo (fuera de alcance, manipulación, errores) viven aquí para que su
/// contenido no dependa de lo que el modelo diga.
abstract final class RespuestasLocalesLexus {
  static const String saludo =
      'Hola, soy Lexus, el asistente jurídico de ManoLegal. Cuéntame qué está pasando y trataré de orientarte.';

  static const String introduccionTitulo = 'Hola, soy Lexus.';
  static const String introduccionTexto =
      'Puedo ayudarte a entender mejor una situación jurídica y orientarte dentro de ManoLegal.';
  static const String introduccionInvitacion = 'Cuéntame qué sucede.';

  static const String respuestaFueraDeAlcance =
      'Puedo ayudarte con orientación relacionada con temas jurídicos y con ManoLegal. Esa pregunta no está dentro de mi ámbito.';
  static const String respuestaIntentoManipulacion =
      'Soy Lexus, el asistente jurídico de ManoLegal, y debo mantenerme dentro de ese ámbito. Si quieres, cuéntame tu situación jurídica y te oriento.';

  static const String respuestaErrorGeneral =
      'No pude procesar la consulta en este momento. Revisa tu conexión e inténtalo nuevamente.';
  static const String respuestaSinConexion =
      'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.';
  static const String respuestaTiempoAgotado =
      'La respuesta está tardando más de lo normal. Inténtalo de nuevo en un momento.';
  static const String respuestaCuota =
      'Lexus tiene mucha demanda en este momento. Intenta de nuevo en unos minutos.';
  static const String respuestaAppCheck =
      'Lexus no está disponible en esta versión de la aplicación. Actualízala o inténtalo más tarde.';
  static const String respuestaModeloNoDisponible =
      'El servicio de Lexus no está disponible por ahora. Inténtalo más tarde.';
  static const String respuestaInvalida =
      'No pude interpretar la respuesta. Intenta de nuevo.';
  static const String respuestaBloqueoSeguridad =
      'No puedo responder a eso tal como está planteado. Si estás en una situación de riesgo, busca ayuda profesional o de las autoridades.';
  static const String respuestaSesionExpirada =
      'Tu sesión expiró. Vuelve a iniciar sesión para continuar.';

  static const String avisoUrgencia =
      'Si tu situación implica un riesgo inmediato para ti o para otra persona, comunícate con las autoridades (línea 123 en Colombia) o busca ayuda profesional sin demora.';
  static const String avisoConversacionLarga =
      'Esta conversación ya es extensa. Puedes iniciar una nueva conversación para continuar.';
  static const String avisoLimiteTurnos =
      'Llegaste al límite de esta conversación. Inicia una nueva conversación para seguir con Lexus.';

  static const String mensajeSinAbogados =
      'Por ahora no encontramos abogados que coincidan con esta categoría.';
  static const String mensajeErrorAbogados =
      'No pudimos cargar los abogados. Inténtalo de nuevo.';
  static const String notaAbogadosSugeridos =
      'Estos son perfiles reales de ManoLegal. Lexus no recomienda a un abogado en particular: revisa cada perfil y elige con criterio.';

  static const String avisoIdentidad =
      'Lexus es un sistema de inteligencia artificial que ofrece orientación inicial. No es un abogado, puede equivocarse y no sustituye la asesoría de un profesional.';

  /// Versión corta para teléfonos, donde el aviso completo ocuparía demasiado
  /// alto de forma permanente. Conserva todo lo que debe quedar claro.
  static const String avisoIdentidadBreve =
      'Lexus es una IA de orientación inicial: no es un abogado, puede equivocarse y no reemplaza la asesoría profesional.';
  static const String avisoPrivacidad =
      'No compartas contraseñas, números de tarjetas ni datos que no sean necesarios.';

  static String textoBotonAbogados(EspecialidadAbogado area) {
    if (area == EspecialidadAbogado.otra) {
      return 'Ver abogados de otras especialidades';
    }
    return 'Ver abogados de ${area.textoLegible}';
  }

  static String mensajeParaError(TipoErrorLexus tipo) {
    switch (tipo) {
      case TipoErrorLexus.sinConexion:
        return respuestaSinConexion;
      case TipoErrorLexus.tiempoAgotado:
        return respuestaTiempoAgotado;
      case TipoErrorLexus.cuotaExcedida:
        return respuestaCuota;
      case TipoErrorLexus.appCheckRechazado:
        return respuestaAppCheck;
      case TipoErrorLexus.modeloNoDisponible:
        return respuestaModeloNoDisponible;
      case TipoErrorLexus.respuestaInvalida:
        return respuestaInvalida;
      case TipoErrorLexus.bloqueoSeguridad:
        return respuestaBloqueoSeguridad;
      case TipoErrorLexus.sesionExpirada:
        return respuestaSesionExpirada;
      case TipoErrorLexus.interno:
        return respuestaErrorGeneral;
    }
  }
}
