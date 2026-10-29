import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../configuracion/configuracion_lexus.dart';
import '../../../../configuracion/respuestas_locales_lexus.dart';
import '../../../../controlador/controlador_dictado_lexus.dart';
import '../../../../controlador/controlador_lexus.dart';
import '../../../../modelo/modelo_paso_recorrido.dart';
import '../../../compartido/widgets/recorrido/ambito_recorrido.dart';
import '../../../tema/tema_app.dart';
import 'boton_dictado_lexus.dart';
import 'boton_enviar_lexus.dart';
import 'encabezado_lexus.dart';
import 'estilos_lexus.dart';

/// Zona inferior del chat: aviso de conversación larga o de límite, campo de
/// texto, botón de dictado por voz y botón de enviar.
class BarraEntradaLexus extends StatelessWidget {
  const BarraEntradaLexus({
    super.key,
    required this.controlador,
    required this.texto,
    required this.foco,
    this.dictado,
    this.alEnviar,
    this.alRequerirCuenta,
  });

  final ControladorLexus controlador;
  final TextEditingController texto;
  final FocusNode foco;

  /// Dictado por voz. Sin él no se muestra el botón del micrófono.
  final ControladorDictadoLexus? dictado;

  /// Se llama después de enviar, por ejemplo para llevar la lista al final.
  final VoidCallback? alEnviar;

  /// Modo visitante (web, sin sesión). Si no es `null`, enviar (botón o
  /// Enter) y el micrófono llaman a esto en lugar de actuar: piden crear una
  /// cuenta. El texto escrito se conserva para cuando vuelva con sesión.
  final VoidCallback? alRequerirCuenta;

  /// Solo en computadores y navegadores de escritorio Enter envía: en un
  /// teléfono, Enter del teclado en pantalla debe seguir siendo salto de línea.
  static bool get _enterEnvia {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
    }
  }

  bool _puedeEnviar(String valor) {
    final limpio = valor.trim();
    return limpio.isNotEmpty &&
        limpio.runes.length <= ConfiguracionLexus.largoMaximoMensaje &&
        !controlador.cargando &&
        !controlador.enviando &&
        !controlador.limiteAlcanzado &&
        !_dictadoOcupado;
  }

  /// Mientras se graba o se transcribe no se envía: el texto del dictado aún
  /// no llegó al campo y la persona debe poder revisarlo antes.
  bool get _dictadoOcupado => dictado?.ocupado ?? false;

  void _enviar() {
    // El visitante no envía: ni el modelo ni el historial reciben nada, y el
    // texto queda en el campo.
    final requerirCuenta = alRequerirCuenta;
    if (requerirCuenta != null) {
      requerirCuenta();
      return;
    }
    // Enter llega aquí sin pasar por el botón, que ya está desactivado.
    if (_dictadoOcupado) return;
    final validacion = controlador.validar(texto.text);
    if (validacion == ValidacionMensajeLexus.muyRapido) {
      // El mensaje no se pierde: sale apenas termina el intervalo mínimo.
      Future<void>.delayed(controlador.esperaParaEnviar, () {
        if (foco.context != null) _enviar();
      });
      return;
    }
    if (validacion != ValidacionMensajeLexus.valido) return;
    final contenido = texto.text;
    texto.clear();
    controlador.enviar(contenido);
    // Con un lector de pantalla activo, en la web reenfocar el campo por
    // código lo deja desconectado del texto que se escribe después.
    if (!SemanticsBinding.instance.semanticsEnabled) foco.requestFocus();
    alEnviar?.call();
  }

  KeyEventResult _alTeclear(FocusNode nodo, KeyEvent evento) {
    final esEnter =
        evento.logicalKey == LogicalKeyboardKey.enter ||
        evento.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!esEnter || evento is KeyUpEvent || !_enterEnvia) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    if (evento is KeyDownEvent) _enviar();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controlador, texto, foco, ?dictado]),
      builder: (context, _) {
        if (controlador.limiteAlcanzado) {
          return _AvisoLimite(controlador: controlador);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controlador.conversacionExtensa)
              _BannerConversacionLarga(controlador: controlador),
            _campo(context),
          ],
        );
      },
    );
  }

  Widget _campo(BuildContext context) {
    final longitud = texto.text.trim().runes.length;
    final maximo = ConfiguracionLexus.largoMaximoMensaje;
    final excedido = longitud > maximo;
    final mostrarContador = longitud > maximo * 0.8;
    final formato = NumberFormat.decimalPattern('es_CO');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dictado != null) IndicadorDictadoLexus(dictado: dictado!),
        // El campo y el micrófono los señala el recorrido guiado de Lexus;
        // sin ámbito de recorrido las marcas no agregan nada.
        MarcaRecorrido(
          id: MarcaRecorridoId.lexusEntrada,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
            decoration: BoxDecoration(
              color: ColoresApp.blanco,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: excedido
                    ? ColoresApp.rojoNoVerificado
                    : ColoresApp.azulTurqui.withValues(
                        alpha: foco.hasFocus ? 0.6 : 0.15,
                      ),
                width: foco.hasFocus ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140A1930),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Aquí irá la acción futura de adjuntar archivos. Hasta que
                // exista de verdad no se muestran controles que no hacen nada.
                Expanded(
                  child: Focus(
                    onKeyEvent: _alTeclear,
                    child: TextField(
                      controller: texto,
                      focusNode: foco,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: EstilosLexus.cuerpo(
                        color: ColoresApp.azulTurquiOscuro,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu consulta…',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: EstilosLexus.textoSobreGris,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (dictado != null) ...[
                  MarcaRecorrido(
                    id: MarcaRecorridoId.lexusDictado,
                    child: BotonDictadoLexus(
                      dictado: dictado!,
                      habilitado:
                          !controlador.cargando && !controlador.limiteAlcanzado,
                      alToqueSustituto: alRequerirCuenta,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                BotonEnviarLexus(
                  habilitado: _puedeEnviar(texto.text),
                  enviando: controlador.enviando,
                  onPressed: _enviar,
                ),
              ],
            ),
          ),
        ),
        if (excedido)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: ColoresApp.rojoNoVerificado,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tu mensaje supera los ${formato.format(maximo)} caracteres.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: ColoresApp.rojoNoVerificado,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (mostrarContador)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${formato.format(longitud)} / ${formato.format(maximo)}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: EstilosLexus.textoSobreGris,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerConversacionLarga extends StatelessWidget {
  const _BannerConversacionLarga({required this.controlador});

  final ControladorLexus controlador;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: ColoresApp.dorado.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresApp.dorado.withValues(alpha: 0.4)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: ColoresApp.azulTurqui,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              RespuestasLocalesLexus.avisoConversacionLarga,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: ColoresApp.azulTurquiOscuro,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ColoresApp.azulTurqui,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () =>
                confirmarNuevaConversacionLexus(context, controlador),
            child: const Text('Nueva conversación'),
          ),
        ],
      ),
    );
  }
}

class _AvisoLimite extends StatelessWidget {
  const _AvisoLimite({required this.controlador});

  final ControladorLexus controlador;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EstilosLexus.tarjeta(radio: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: ColoresApp.azulTurqui,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  RespuestasLocalesLexus.avisoLimiteTurnos,
                  style: EstilosLexus.cuerpo(tamanio: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () =>
                  confirmarNuevaConversacionLexus(context, controlador),
              child: const Text('Nueva conversación'),
            ),
          ),
        ],
      ),
    );
  }
}
