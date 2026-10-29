import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/tema_app.dart';
import 'tarjeta_cristal.dart';

/// Íconos que se alternan en la tarjeta de vidrio, después del del motivo.
const List<IconData> _iconosCiclo = [Icons.balance, Icons.gavel, Icons.menu_book];

/// Tiempo que cada ícono queda a la vista, incluido su fundido de salida.
const Duration _periodoPorIcono = Duration(milliseconds: 3500);

/// Parte final del periodo de cada ícono que ocupa el fundido al siguiente.
const double _fraccionFundido = 0.18;

/// Panel de marca del inicio de sesión web de escritorio: ocupa la columna
/// izquierda a toda altura, con el degradado azul de ManoLegal, la marca, una
/// frase corta y una tarjeta de vidrio cuyo ícono cambia con un fundido
/// sutil (balanza, mazo, libro).
///
/// La animación la mueve un [AnimationController] sincronizado con la
/// pantalla: no usa temporizadores, se detiene sola cuando otra ruta tapa el
/// inicio de sesión y va dentro de un [RepaintBoundary] para no repintar el
/// formulario. Con la animación del sistema reducida, el ícono queda fijo.
class PanelMarcaAccesoWeb extends StatefulWidget {
  /// Ícono y frase del motivo de la pantalla (ver `PlantillaAutenticacion`).
  final IconData icono;
  final String frase;

  const PanelMarcaAccesoWeb({super.key, required this.icono, required this.frase});

  @override
  State<PanelMarcaAccesoWeb> createState() => _PanelMarcaAccesoWebState();
}

class _PanelMarcaAccesoWebState extends State<PanelMarcaAccesoWeb> with SingleTickerProviderStateMixin {
  /// El del motivo primero, para que el estado fijo coincida con la frase.
  late final List<IconData> _iconos = [
    widget.icono,
    for (final icono in _iconosCiclo)
      if (icono != widget.icono) icono,
  ];

  late final AnimationController _ciclo = AnimationController(
    vsync: this,
    duration: _periodoPorIcono * _iconos.length,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ciclo
        ..stop()
        ..value = 0;
    } else if (!_ciclo.isAnimating) {
      _ciclo.repeat();
    }
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresApp.azulTurquiOscuro, ColoresApp.azulTurqui, ColoresApp.azulProfundo],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned(top: -90, right: -70, child: _Orbe(diametro: 280)),
          const Positioned(bottom: -110, left: -90, child: _Orbe(diametro: 300)),
          // Desplazable solo si la ventana es muy baja; si no, el contenido
          // ocupa toda la altura y la tarjeta queda centrada.
          LayoutBuilder(
            builder: (context, restricciones) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: restricciones.maxHeight),
                child: IntrinsicHeight(child: _contenido()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.balance, color: ColoresApp.blanco, size: 26),
              const SizedBox(width: 10),
              Text(
                'ManoLegal',
                style: GoogleFonts.plusJakartaSans(
                  color: ColoresApp.blanco,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 32),
          Center(
            child: RepaintBoundary(
              child: TarjetaCristal(
                borderRadius: 32,
                padding: const EdgeInsets.all(28),
                child: SizedBox.square(
                  dimension: 168,
                  child: AnimatedBuilder(animation: _ciclo, builder: (context, _) => _iconoAnimado()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Spacer(),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: ColoresApp.dorado, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text(
            widget.frase,
            style: GoogleFonts.plusJakartaSans(
              color: ColoresApp.blanco,
              fontWeight: FontWeight.w800,
              fontSize: 30,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Abogados verificados en Cali, a un clic.',
            style: TextStyle(color: ColoresApp.blanco.withValues(alpha: 0.85), fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// El ícono actual y, durante el fundido, el siguiente encima. Al final
  /// de cada periodo el actual se desvanece y se encoge apenas mientras el
  /// siguiente aparece y crece hasta su tamaño.
  Widget _iconoAnimado() {
    final posicion = _ciclo.value * _iconos.length;
    final indice = posicion.floor() % _iconos.length;
    final fase = posicion - posicion.floor();
    const inicioFundido = 1 - _fraccionFundido;
    final avance = fase <= inicioFundido
        ? 0.0
        : Curves.easeInOut.transform(((fase - inicioFundido) / _fraccionFundido).clamp(0.0, 1.0));

    Widget icono(IconData datos, double opacidad, double escala) {
      return Opacity(
        opacity: opacidad,
        child: Transform.scale(
          scale: escala,
          child: Icon(datos, size: 150, color: ColoresApp.blanco.withValues(alpha: 0.92)),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        icono(_iconos[indice], 1 - avance, 1 - 0.08 * avance),
        if (avance > 0) icono(_iconos[(indice + 1) % _iconos.length], avance, 0.92 + 0.08 * avance),
      ],
    );
  }
}

/// Resplandor circular decorativo, el mismo de la plantilla de autenticación
/// (que es privado allí).
class _Orbe extends StatelessWidget {
  final double diametro;

  const _Orbe({required this.diametro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ColoresApp.azulBrillante.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
