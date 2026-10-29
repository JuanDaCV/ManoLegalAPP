import 'package:flutter/material.dart';

import '../../../../controlador/controlador_dictado_lexus.dart';
import '../../../tema/tema_app.dart';
import 'estilos_lexus.dart';
import 'textos_dictado_lexus.dart';

/// Botón de dictado por voz: micrófono en reposo y «detener» mientras graba.
///
/// Solo inicia y detiene el dictado; el texto resultante llega al campo por la
/// devolución de llamada del [ControladorDictadoLexus]. El estado de la
/// grabación se muestra aparte, en [IndicadorDictadoLexus].
class BotonDictadoLexus extends StatelessWidget {
  const BotonDictadoLexus({
    super.key,
    required this.dictado,
    required this.habilitado,
    this.alToqueSustituto,
  });

  final ControladorDictadoLexus dictado;

  /// Falso mientras el chat carga o llegó a su límite. No impide detener una
  /// grabación que ya está en curso.
  final bool habilitado;

  /// Si no es `null`, el toque llama a esto y nunca al dictado: no se graba
  /// ni se pide el permiso del micrófono. Lo usa el visitante web, al que se
  /// le pide una cuenta; el botón se ve activo para que pueda tocarlo.
  final VoidCallback? alToqueSustituto;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dictado,
      builder: (context, _) {
        final grabando = dictado.grabando;
        final sustituto = alToqueSustituto;
        final activo =
            sustituto != null ||
            grabando ||
            (dictado.estado == EstadoDictadoLexus.inactivo && habilitado);
        final VoidCallback? alTocar = activo
            ? (sustituto ?? dictado.alternar)
            : null;
        final etiqueta = grabando
            ? TextosDictadoLexus.detenerDictado
            : TextosDictadoLexus.dictar;
        final Color fondo;
        final Color icono;
        BorderSide borde = BorderSide.none;
        if (grabando) {
          fondo = ColoresApp.rojoNoVerificado;
          icono = ColoresApp.blanco;
        } else if (activo) {
          fondo = ColoresApp.blanco;
          icono = ColoresApp.azulTurqui;
          borde = const BorderSide(color: ColoresApp.azulTurqui, width: 1.5);
        } else {
          fondo = ColoresApp.grisTexto.withValues(alpha: 0.3);
          icono = EstilosLexus.textoSobreGris;
        }

        return Tooltip(
          message: etiqueta,
          excludeFromSemantics: true,
          child: Semantics(
            button: true,
            enabled: activo,
            label: etiqueta,
            excludeSemantics: true,
            onTap: alTocar,
            child: Material(
              color: fondo,
              shape: CircleBorder(side: borde),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: alTocar,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(
                      grabando ? Icons.stop_rounded : Icons.mic_none_rounded,
                      color: icono,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Línea de estado del dictado, sobre el campo de texto: grabando con cuenta
/// atrás, esperando el permiso o transcribiendo. No ocupa espacio en reposo.
class IndicadorDictadoLexus extends StatelessWidget {
  const IndicadorDictadoLexus({super.key, required this.dictado});

  final ControladorDictadoLexus dictado;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dictado,
      builder: (context, _) {
        switch (dictado.estado) {
          case EstadoDictadoLexus.inactivo:
            return const SizedBox.shrink();
          case EstadoDictadoLexus.grabando:
            return _lineaGrabando();
          case EstadoDictadoLexus.pidiendoPermiso:
            return _lineaEspera(TextosDictadoLexus.pidiendoPermiso);
          case EstadoDictadoLexus.transcribiendo:
            return _lineaEspera(TextosDictadoLexus.transcribiendo);
        }
      },
    );
  }

  TextStyle get _estilo => EstilosLexus.cuerpo(
    tamanio: 14,
    color: ColoresApp.azulTurquiOscuro,
    altura: 1.3,
  );

  Widget _lineaGrabando() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 6),
      // Wrap y no Row: con el texto muy grande el botón pasa a otra línea en
      // lugar de desbordar.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // La cuenta atrás cambia cada segundo: un lector de pantalla solo
          // anuncia que se graba, no cada segundo que pasa.
          Semantics(
            liveRegion: true,
            label: TextosDictadoLexus.grabando,
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PuntoGrabacion(),
                const SizedBox(width: 8),
                Text(TextosDictadoLexus.grabando, style: _estilo),
                const SizedBox(width: 8),
                Text(
                  TextosDictadoLexus.cuentaAtras(dictado.restante),
                  style: _estilo.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: TextosDictadoLexus.cancelarDictado,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.azulTurqui,
                minimumSize: const Size(48, 48),
              ),
              onPressed: dictado.cancelar,
              child: const Text(TextosDictadoLexus.cancelar),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineaEspera(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Semantics(
        liveRegion: true,
        label: texto,
        excludeSemantics: true,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColoresApp.azulTurqui,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(texto, style: _estilo)),
          ],
        ),
      ),
    );
  }
}

/// Punto rojo que late mientras se graba. Con la animación del sistema
/// reducida queda fijo.
class _PuntoGrabacion extends StatefulWidget {
  const _PuntoGrabacion();

  @override
  State<_PuntoGrabacion> createState() => _PuntoGrabacionState();
}

class _PuntoGrabacionState extends State<_PuntoGrabacion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _latido
        ..stop()
        ..value = 1;
    } else if (!_latido.isAnimating) {
      _latido.repeat(reverse: true, min: 0.35, max: 1);
    }
  }

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _latido,
      child: Container(
        key: const ValueKey('punto-grabacion'),
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: ColoresApp.rojoNoVerificado,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
