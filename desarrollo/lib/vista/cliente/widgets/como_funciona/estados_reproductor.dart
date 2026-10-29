import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import 'boton_reproducir.dart';
import 'portada_capitulo.dart';

/// Portada de un capítulo que todavía no se reproduce (o que se está
/// cargando): el recuadro completo es el botón de reproducir.
///
/// Un blanco táctil de ese tamaño es más fácil de acertar que un disco de 64
/// píxeles, y se mantiene igual mientras carga para que el foco del teclado
/// no se pierda en medio del gesto.
class PortadaInteractiva extends StatefulWidget {
  final ModeloCapituloComoFunciona capitulo;
  final bool cargando;
  final FocusNode foco;
  final VoidCallback alActivar;

  const PortadaInteractiva({
    super.key,
    required this.capitulo,
    required this.cargando,
    required this.foco,
    required this.alActivar,
  });

  @override
  State<PortadaInteractiva> createState() => _PortadaInteractivaState();
}

class _PortadaInteractivaState extends State<PortadaInteractiva> {
  bool _encima = false;
  bool _enfocada = false;

  @override
  Widget build(BuildContext context) {
    final cargando = widget.cargando;
    return Semantics(
      button: !cargando,
      liveRegion: cargando,
      label: cargando ? 'Cargando video…' : widget.capitulo.etiquetaReproducir,
      onTap: cargando ? null : widget.alActivar,
      excludeSemantics: true,
      child: Tooltip(
        message: cargando ? '' : 'Reproducir video',
        waitDuration: const Duration(milliseconds: 600),
        child: FocusableActionDetector(
          focusNode: widget.foco,
          mouseCursor: cargando ? SystemMouseCursors.progress : SystemMouseCursors.click,
          // El resaltado de foco solo se pide para el teclado: un toque con el
          // ratón no debe dibujar el aro.
          onShowHoverHighlight: (valor) => setState(() => _encima = valor),
          onShowFocusHighlight: (valor) => setState(() => _enfocada = valor),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.alActivar();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.alActivar,
            child: LayoutBuilder(
              builder: (context, restricciones) => Stack(
                fit: StackFit.expand,
                children: [
                  PortadaCapitulo(capitulo: widget.capitulo),
                  Center(
                    child: BotonReproducir(
                      compacto: restricciones.maxWidth < 420,
                      cargando: cargando,
                      resaltado: _encima && !cargando,
                      enfocado: _enfocada,
                    ),
                  ),
                  Positioned(left: 12, bottom: 12, child: PildoraDuracion(texto: widget.capitulo.duracionTexto)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Portada oscurecida con el aviso de que el video no cargó y el botón para
/// intentarlo de nuevo.
class EstadoErrorVideo extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;
  final VoidCallback alReintentar;

  const EstadoErrorVideo({super.key, required this.capitulo, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PortadaCapitulo(capitulo: capitulo, oscurecida: true),
        Center(
          // Con texto muy grande o recuadros pequeños, el aviso se reduce en
          // vez de desbordar.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_rounded, color: ColoresApp.blanco, size: 32),
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: const Text(
                      'No se pudo cargar el video.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColoresApp.blanco, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: alReintentar,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColoresApp.blanco,
                      foregroundColor: ColoresApp.azulTurqui,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
