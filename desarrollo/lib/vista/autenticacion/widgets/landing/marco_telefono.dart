import 'dart:async';

import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';

/// Marco de teléfono realista. La pantalla mantiene la proporción 540:1200 de
/// las capturas reales.
class MarcoTelefono extends StatelessWidget {
  const MarcoTelefono({super.key, required this.ancho, required this.pantalla});

  final double ancho;
  final Widget pantalla;

  @override
  Widget build(BuildContext context) {
    final bisel = ancho * 0.035;
    final radio = ancho * 0.14;
    return SizedBox(
      width: ancho,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Botones laterales: asoman 2 px fuera del cuerpo.
          Positioned(
            left: -2,
            top: ancho * 0.45,
            child: _BotonLateral(alto: ancho * 0.16),
          ),
          Positioned(
            left: -2,
            top: ancho * 0.68,
            child: _BotonLateral(alto: ancho * 0.16),
          ),
          Positioned(
            right: -2,
            top: ancho * 0.58,
            child: _BotonLateral(alto: ancho * 0.24),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(radio),
              border: Border.all(color: const Color(0x24FFFFFF), width: 1.5),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x73000000),
                  blurRadius: 60,
                  offset: Offset(0, 30),
                ),
                BoxShadow(
                  color: ColoresApp.dorado.withValues(alpha: 0.15),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(bisel),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(radio - bisel),
                    child: AspectRatio(
                      aspectRatio: 540 / 1200,
                      child: pantalla,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: bisel * 0.8),
                    child: Container(
                      width: ancho * 0.16,
                      height: ancho * 0.034,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(ancho),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonLateral extends StatelessWidget {
  const _BotonLateral({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: alto,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2640),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Una captura real de la app.
class CapturaApp {
  const CapturaApp(this.ruta, this.nombre);

  final String ruta;
  final String nombre;
}

const List<CapturaApp> capturasApp = [
  CapturaApp('img/landing/pantalla_inicio.webp', 'Inicio'),
  CapturaApp('img/landing/pantalla_lexus.webp', 'Lexus'),
  CapturaApp('img/landing/pantalla_como_funciona.webp', 'Cómo funciona'),
];

/// Imagen de una captura real, decodificada al tamaño en que se muestra.
class ImagenCaptura extends StatelessWidget {
  const ImagenCaptura({
    super.key,
    required this.ruta,
    required this.ancho,
    required this.etiqueta,
  });

  final String ruta;
  final double ancho;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      ruta,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      cacheWidth: (ancho * dpr).round(),
      semanticLabel: etiqueta,
      errorBuilder: (_, _, _) => const ColoredBox(color: ColoresApp.azulTurqui),
    );
  }
}

/// Teléfono que alterna las capturas reales cada 5 s mientras está a la
/// vista. La rotación se detiene al pasar el puntero, al tener el foco dentro
/// o tras elegir una captura, y no existe con "reducir movimiento".
class PantallasTelefono extends StatefulWidget {
  const PantallasTelefono({
    super.key,
    required this.capturas,
    required this.ancho,
  });

  final List<CapturaApp> capturas;
  final double ancho;

  @override
  State<PantallasTelefono> createState() => _PantallasTelefonoState();
}

class _PantallasTelefonoState extends State<PantallasTelefono> {
  Timer? _temporizador;
  int _indice = 0;
  bool _encima = false;
  bool _conFoco = false;
  bool _elegida = false;
  bool _precargadas = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _temporizador?.cancel();
      _temporizador = null;
    } else {
      _temporizador ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) => _avanzar(),
      );
      _precargarSiguientes();
    }
  }

  /// Decodifica las demás capturas después del primer cuadro, con la misma
  /// clave de caché que usa [ImagenCaptura]. Así el primer cambio del
  /// carrusel no tiene que decodificar una imagen en medio de la transición,
  /// que en equipos lentos se notaba como un tirón.
  void _precargarSiguientes() {
    if (_precargadas) return;
    _precargadas = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ancho = (_anchoPantalla * MediaQuery.devicePixelRatioOf(context)).round();
      for (final captura in widget.capturas.skip(1)) {
        precacheImage(
          ResizeImage(AssetImage(captura.ruta), width: ancho),
          context,
          // Si falla, la imagen ya muestra su propio respaldo al dibujarse.
          onError: (_, _) {},
        );
      }
    });
  }

  /// Ancho de la pantalla interior, para decodificar la imagen a ese tamaño.
  double get _anchoPantalla => widget.ancho * (1 - 0.07);

  void _avanzar() {
    if (!mounted || _encima || _conFoco || _elegida || !_estaALaVista()) {
      return;
    }
    setState(() => _indice = (_indice + 1) % widget.capturas.length);
  }

  /// Si el teléfono asoma en la ventana. Fuera de ella la rotación no avanza:
  /// sin `setState` no hay cuadros que dibujar, y al volver a verse sigue en
  /// el siguiente turno de 5 s.
  bool _estaALaVista() {
    if (!TickerMode.getValuesNotifier(context).value.enabled) return false;
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.attached || !caja.hasSize) return false;
    final arriba = caja.localToGlobal(Offset.zero).dy;
    return arriba < MediaQuery.sizeOf(context).height &&
        arriba + caja.size.height > 0;
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capturas = widget.capturas;
    final actual = capturas[_indice];
    final anchoPantalla = _anchoPantalla;
    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (valor) => _conFoco = valor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MarcoTelefono(
              ancho: widget.ancho,
              pantalla: AnimatedSwitcher(
                duration: EstilosLanding.duracion(context, 600),
                child: ImagenCaptura(
                  key: ValueKey(actual.ruta),
                  ruta: actual.ruta,
                  ancho: anchoPantalla,
                  etiqueta: 'Captura real de la app: ${actual.nombre}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < capturas.length; i++)
                  _PuntoCaptura(
                    nombre: capturas[i].nombre,
                    activo: i == _indice,
                    alTocar: () => setState(() {
                      _indice = i;
                      _elegida = true;
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PuntoCaptura extends StatelessWidget {
  const _PuntoCaptura({
    required this.nombre,
    required this.activo,
    required this.alTocar,
  });

  final String nombre;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      label: 'Mostrar captura: $nombre',
      excludeSemantics: true,
      onTap: alTocar,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: alTocar,
            radius: 24,
            child: Center(
              child: AnimatedContainer(
                duration: EstilosLanding.duracion(context, 250),
                width: activo ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: activo
                      ? ColoresApp.blanco
                      : ColoresApp.blanco.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
