import 'package:flutter/material.dart';

/// Muestra su hijo con un fundido y un ligero ascenso la primera vez que su
/// borde superior entra en el 90 % del alto de la ventana.
///
/// Con "reducir movimiento" el hijo es visible de inmediato y no se registra
/// ningún oyente. La animación es finita y se libera al terminar.
class RevelarAlDesplazar extends StatefulWidget {
  const RevelarAlDesplazar({
    super.key,
    required this.child,
    this.retraso = Duration.zero,
  });

  final Widget child;
  final Duration retraso;

  @override
  State<RevelarAlDesplazar> createState() => _RevelarAlDesplazarState();
}

class _RevelarAlDesplazarState extends State<RevelarAlDesplazar>
    with SingleTickerProviderStateMixin {
  static const int _duracionMs = 520;
  static const double _desplazamiento = 24;

  late final AnimationController _controlador;
  late final Animation<double> _progreso;
  ScrollPosition? _posicion;
  bool _revelado = false;

  @override
  void initState() {
    super.initState();
    final total = _duracionMs + widget.retraso.inMilliseconds;
    _controlador = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _progreso = CurvedAnimation(
      parent: _controlador,
      curve: Interval(
        widget.retraso.inMilliseconds / total,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_revelado) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _soltarOyente();
      return;
    }
    final nueva = Scrollable.maybeOf(context)?.position;
    if (nueva != _posicion) {
      _soltarOyente();
      _posicion = nueva?..addListener(_comprobar);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _comprobar());
  }

  void _soltarOyente() {
    _posicion?.removeListener(_comprobar);
    _posicion = null;
  }

  void _comprobar() {
    if (!mounted || _revelado) return;
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.attached || !caja.hasSize) return;
    final alto = MediaQuery.sizeOf(context).height;
    final arriba = caja.localToGlobal(Offset.zero).dy;
    // Sin desplazamiento posible (no hay Scrollable o ya se llegó al final),
    // lo que quede por debajo del umbral nunca lo cruzaría: se revela igual.
    final posicion = _posicion;
    final sinMasRecorrido =
        posicion == null ||
        (posicion.hasContentDimensions &&
            posicion.pixels >= posicion.maxScrollExtent - 2);
    if (arriba > alto * 0.9 && !sinMasRecorrido) return;
    _revelado = true;
    _soltarOyente();
    _controlador.forward();
  }

  @override
  void dispose() {
    _soltarOyente();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _progreso,
      child: widget.child,
      builder: (context, hijo) {
        final t = _progreso.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, _desplazamiento * (1 - t)),
            child: hijo,
          ),
        );
      },
    );
  }
}
