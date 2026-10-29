import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../modelo/modelo_paso_recorrido.dart';
import '../../../tema/tema_app.dart';
import 'estilos_recorrido.dart';

/// Tarjeta blanca que explica un paso del recorrido y ofrece sus acciones.
///
/// Solo muestra lo que recibe: no conoce el controlador. El texto, el número
/// de paso y los callbacks los resuelve quien la usa (`CapaRecorrido`).
///
/// La cabecera y los botones quedan fijos y solo el texto se desplaza cuando
/// no cabe (teléfonos bajos, texto agrandado): así los botones nunca quedan
/// escondidos dentro de la tarjeta. Su alto mínimo intrínseco es el de la
/// cabecera, unas líneas de texto y los botones: con ese dato
/// `DisposicionTarjetaRecorrido` elige dónde ponerla.
class TarjetaPasoRecorrido extends StatefulWidget {
  const TarjetaPasoRecorrido({
    super.key,
    required this.paso,
    required this.descripcion,
    required this.numeroDePaso,
    required this.totalPasos,
    required this.preparando,
    required this.puedeRetroceder,
    required this.alSiguiente,
    required this.alAnterior,
    required this.alSaltar,
    required this.alCerrar,
    required this.focoPrincipal,
  });

  final ModeloPasoRecorrido paso;

  /// Texto ya resuelto para el layout y la presencia de la marca.
  final String descripcion;

  /// Posición entre los pasos que señalan algo (desde 1). `null` en la
  /// bienvenida y el cierre.
  final int? numeroDePaso;
  final int totalPasos;

  /// Mientras se resuelven los pasos, «Comenzar» muestra un indicador y no
  /// responde.
  final bool preparando;
  final bool puedeRetroceder;

  /// «Comenzar» en la bienvenida y el cierre; «Siguiente» en los demás.
  final VoidCallback alSiguiente;
  final VoidCallback alAnterior;
  final VoidCallback alSaltar;
  final VoidCallback alCerrar;

  /// Nodo de foco del botón principal: la capa lo enfoca al mostrar cada paso
  /// para que Enter avance y el lector de pantalla empiece por aquí.
  final FocusNode focoPrincipal;

  @override
  State<TarjetaPasoRecorrido> createState() => _TarjetaPasoRecorridoState();
}

class _TarjetaPasoRecorridoState extends State<TarjetaPasoRecorrido> {
  /// Líneas de texto que la tarjeta muestra como mínimo junto a los botones.
  static const _lineasMinimas = 4;

  /// Desplazamiento propio del texto: la barra queda visible si hay más
  /// texto del que se ve, para que se note que se puede desplazar.
  final ScrollController _desplazamiento = ScrollController();

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paso = widget.paso;
    final numero = widget.numeroDePaso;
    final esResaltado = paso.tipo == TipoPasoRecorrido.resaltado;
    final cuerpo = EstilosRecorrido.cuerpo();
    final altoLinea =
        MediaQuery.textScalerOf(context).scale(cuerpo.fontSize!) *
        cuerpo.height!;

    return DecoratedBox(
      decoration: EstilosRecorrido.tarjeta(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EstilosRecorrido.radio),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: _Cabecera(
                paso: paso,
                numeroDePaso: numero,
                totalPasos: widget.totalPasos,
                alCerrar: widget.alCerrar,
              ),
            ),
            Flexible(
              child: _AltoMinimoDesplazable(
                // El relleno superior del texto más unas líneas.
                alto: 8 + _lineasMinimas * altoLinea,
                child: Scrollbar(
                  controller: _desplazamiento,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _desplazamiento,
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FileteDorado(),
                        const SizedBox(height: 10),
                        Semantics(
                          header: true,
                          child: Text(
                            paso.titulo,
                            style: EstilosRecorrido.titulo(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(widget.descripcion),
                        ),
                        if (esResaltado && numero != null) ...[
                          const SizedBox(height: 14),
                          _PuntosProgreso(
                            actual: numero,
                            total: widget.totalPasos,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _Acciones(
                paso: paso,
                preparando: widget.preparando,
                puedeRetroceder: widget.puedeRetroceder,
                alSiguiente: widget.alSiguiente,
                alAnterior: widget.alAnterior,
                alSaltar: widget.alSaltar,
                focoPrincipal: widget.focoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que se desplaza no necesita su alto completo para leerse: su alto mínimo
/// intrínseco es [alto] (unas líneas) y no el de todo el texto. El alto real
/// no cambia; solo lo que la tarjeta informa al colocarse.
class _AltoMinimoDesplazable extends SingleChildRenderObjectWidget {
  const _AltoMinimoDesplazable({required this.alto, super.child});

  final double alto;

  @override
  _RenderAltoMinimoDesplazable createRenderObject(BuildContext context) {
    return _RenderAltoMinimoDesplazable(alto);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAltoMinimoDesplazable renderObject,
  ) {
    renderObject.alto = alto;
  }
}

class _RenderAltoMinimoDesplazable extends RenderProxyBox {
  _RenderAltoMinimoDesplazable(this._alto);

  double _alto;
  set alto(double valor) {
    if (valor == _alto) return;
    _alto = valor;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return math.min(super.computeMinIntrinsicHeight(width), _alto);
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.paso,
    required this.numeroDePaso,
    required this.totalPasos,
    required this.alCerrar,
  });

  final ModeloPasoRecorrido paso;
  final int? numeroDePaso;
  final int totalPasos;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final numero = numeroDePaso;
    final Widget izquierda;
    if (paso.tipo == TipoPasoRecorrido.resaltado && numero != null) {
      izquierda = Expanded(
        // El lector de pantalla lee la frase natural en lugar de las
        // mayúsculas separadas.
        child: Semantics(
          label: 'Paso $numero de $totalPasos',
          excludeSemantics: true,
          child: Text(
            'PASO $numero DE $totalPasos',
            style: EstilosRecorrido.etiqueta(),
          ),
        ),
      );
    } else {
      final icono = paso.tipo == TipoPasoRecorrido.cierre
          ? Icons.task_alt
          : Icons.balance;
      izquierda = Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: _InsigniaIcono(icono: icono),
        ),
      );
    }

    return Row(
      children: [
        izquierda,
        IconButton(
          onPressed: alCerrar,
          tooltip: 'Cerrar recorrido',
          icon: const Icon(Icons.close),
          color: ColoresApp.azulTurqui,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }
}

/// Ícono decorativo de la bienvenida y el cierre.
class _InsigniaIcono extends StatelessWidget {
  const _InsigniaIcono({required this.icono});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ColoresApp.azulTurqui,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColoresApp.dorado, width: 1.5),
        ),
        child: Icon(icono, color: ColoresApp.blanco, size: 24),
      ),
    );
  }
}

class _FileteDorado extends StatelessWidget {
  const _FileteDorado();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: ColoresApp.dorado,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Puntos de avance. Son decorativos: el «Paso X de N» ya lo dice con texto.
/// El punto actual es más ancho para no depender solo del color.
class _PuntosProgreso extends StatelessWidget {
  const _PuntosProgreso({required this.actual, required this.total});

  final int actual;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 1; i <= total; i++)
            Container(
              width: i == actual ? 20 : 8,
              height: 8,
              margin: EdgeInsets.only(right: i < total ? 6 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == actual
                    ? ColoresApp.azulTurqui
                    : ColoresApp.grisTexto.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  const _Acciones({
    required this.paso,
    required this.preparando,
    required this.puedeRetroceder,
    required this.alSiguiente,
    required this.alAnterior,
    required this.alSaltar,
    required this.focoPrincipal,
  });

  final ModeloPasoRecorrido paso;
  final bool preparando;
  final bool puedeRetroceder;
  final VoidCallback alSiguiente;
  final VoidCallback alAnterior;
  final VoidCallback alSaltar;
  final FocusNode focoPrincipal;

  static const _tamanioMinimo = Size(48, 48);
  static const _relleno = EdgeInsets.symmetric(horizontal: 18);
  static const _texto = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final esBienvenida = paso.tipo == TipoPasoRecorrido.bienvenida;
    final esCierre = paso.tipo == TipoPasoRecorrido.cierre;

    final saltar = TextButton(
      onPressed: alSaltar,
      style: TextButton.styleFrom(
        foregroundColor: ColoresApp.azulTurqui,
        minimumSize: _tamanioMinimo,
        padding: _relleno,
        textStyle: _texto,
      ),
      child: const Text('Saltar tutorial'),
    );
    final anterior = OutlinedButton(
      onPressed: alAnterior,
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.azulTurqui,
        side: const BorderSide(color: ColoresApp.azulTurqui, width: 1.5),
        minimumSize: _tamanioMinimo,
        padding: _relleno,
        textStyle: _texto,
        shape: const StadiumBorder(),
      ),
      child: const Text('Anterior'),
    );
    final principal = ElevatedButton(
      focusNode: focoPrincipal,
      onPressed: preparando ? null : alSiguiente,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.azulTurqui,
        foregroundColor: ColoresApp.blanco,
        // Mientras carga se ve igual que activo: gris con un indicador blanco
        // no se leería.
        disabledBackgroundColor: ColoresApp.azulTurqui,
        disabledForegroundColor: ColoresApp.blanco,
        minimumSize: _tamanioMinimo,
        padding: _relleno,
        textStyle: _texto,
        shape: const StadiumBorder(),
      ),
      child: preparando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ColoresApp.blanco,
                semanticsLabel: 'Preparando el recorrido',
              ),
            )
          : Text(esBienvenida || esCierre ? 'Comenzar' : 'Siguiente'),
    );

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!esCierre) saltar,
        if (puedeRetroceder) anterior,
        principal,
      ],
    );
  }
}
