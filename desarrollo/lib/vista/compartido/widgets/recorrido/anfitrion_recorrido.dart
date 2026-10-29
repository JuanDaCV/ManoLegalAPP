import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../controlador/controlador_recorrido.dart';
import 'ambito_recorrido.dart';
import 'capa_recorrido.dart';
import 'registro_marcas_recorrido.dart';

/// Envuelve una pantalla para que pueda mostrar su recorrido guiado encima.
///
/// Pone el [AmbitoRecorrido] (para que los `MarcaRecorrido` de abajo se
/// registren) y muestra la [CapaRecorrido] en el `Overlay` de la ruta cuando
/// el [ControladorRecorrido] está visible. Ahí queda por encima de toda la
/// pantalla, incluidas las barras superior e inferior.
///
/// Mientras el recorrido está visible, [child] se excluye del foco y del
/// lector de pantalla: lo que se oye y se alcanza con Tab es solo la tarjeta.
class AnfitrionRecorrido extends StatefulWidget {
  const AnfitrionRecorrido({
    super.key,
    required this.controlador,
    required this.registro,
    required this.child,
  });

  final ControladorRecorrido controlador;
  final RegistroMarcasRecorrido registro;
  final Widget child;

  @override
  State<AnfitrionRecorrido> createState() => _AnfitrionRecorridoState();
}

class _AnfitrionRecorridoState extends State<AnfitrionRecorrido> {
  final OverlayPortalController _portal = OverlayPortalController(
    debugLabel: 'Recorrido guiado',
  );
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_alCambiarControlador);
    if (widget.controlador.visible) _aplicar(widget.controlador.visible);
  }

  @override
  void didUpdateWidget(AnfitrionRecorrido oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      oldWidget.controlador.removeListener(_alCambiarControlador);
      widget.controlador.addListener(_alCambiarControlador);
      _alCambiarControlador();
    }
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_alCambiarControlador);
    super.dispose();
  }

  void _alCambiarControlador() {
    final visible = widget.controlador.visible;
    if (visible == _visible) return;
    _aplicar(visible);
  }

  /// Mostrar u ocultar la capa nunca se hace durante el build: el portal pide
  /// un `setState` al mostrarse y ocultarse, y eso no se puede en pleno build.
  void _aplicar(bool visible) {
    void hacer() {
      if (!mounted || visible != widget.controlador.visible) return;
      setState(() => _visible = visible);
      if (visible) {
        _portal.show();
      } else if (_portal.isShowing) {
        _portal.hide();
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => hacer());
    } else {
      hacer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estos envoltorios están siempre; solo cambian sus booleanos. Así el
    // árbol de la pantalla no se vuelve a montar al empezar o terminar el
    // recorrido.
    return AmbitoRecorrido(
      registro: widget.registro,
      child: OverlayPortal(
        controller: _portal,
        // Con la clave del controlador, cambiar de recorrido (otra sección)
        // crea una capa nueva en lugar de heredar el estado de la anterior:
        // foco, hueco medido y paso vigilado son de un recorrido concreto.
        overlayChildBuilder: (_) => CapaRecorrido(
          key: ObjectKey(widget.controlador),
          controlador: widget.controlador,
          registro: widget.registro,
        ),
        child: ExcludeFocus(
          excluding: _visible,
          child: ExcludeSemantics(excluding: _visible, child: widget.child),
        ),
      ),
    );
  }
}
