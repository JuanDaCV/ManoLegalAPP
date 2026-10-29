import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';

/// Sección de ancho completo: fondo (color o widget), margen lateral según el
/// ancho disponible y contenido centrado con ancho máximo.
class SeccionBase extends StatelessWidget {
  const SeccionBase({
    super.key,
    required this.builder,
    this.color,
    this.fondo,
    this.relleno,
    this.escalaRelleno = 1,
  });

  /// Recibe el tamaño de la landing y el ancho útil del contenido.
  final Widget Function(BuildContext, TamanoLanding, double) builder;
  final Color? color;

  /// Widget de fondo que se estira detrás del contenido.
  final Widget? fondo;

  /// Relleno vertical; por defecto el de [EstilosLanding.relleno].
  final double? relleno;

  /// Factor sobre el relleno por defecto. Sirve cuando dos secciones
  /// consecutivas comparten fondo y sus rellenos se sumarían.
  final double escalaRelleno;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final t = EstilosLanding.tamano(restricciones.maxWidth);
        final margen = EstilosLanding.margenLateral(t);
        final maximo = EstilosLanding.anchoMaximo(t);
        final util = (restricciones.maxWidth - margen * 2).clamp(0.0, maximo);
        final vertical = relleno ?? EstilosLanding.relleno(t) * escalaRelleno;
        Widget contenido = Padding(
          padding: EdgeInsets.symmetric(horizontal: margen, vertical: vertical),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maximo),
              child: builder(context, t, util),
            ),
          ),
        );
        if (fondo != null) {
          contenido = Stack(
            children: [
              Positioned.fill(child: fondo!),
              contenido,
            ],
          );
        }
        if (color != null) {
          contenido = ColoredBox(color: color!, child: contenido);
        }
        return SizedBox(width: double.infinity, child: contenido);
      },
    );
  }
}

/// Sobretítulo + título + párrafo opcional de una sección.
class EncabezadoSeccion extends StatelessWidget {
  const EncabezadoSeccion({
    super.key,
    required this.etiqueta,
    required this.titulo,
    required this.tamano,
    this.lead,
    this.sobreAzul = false,
    this.centrado = false,
  });

  final String etiqueta;
  final String titulo;
  final TamanoLanding tamano;
  final String? lead;
  final bool sobreAzul;
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    final alineacion = centrado ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: centrado
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: centrado ? WrapAlignment.center : WrapAlignment.start,
            spacing: 10,
            runSpacing: 4,
            children: [
              const SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColoresApp.dorado,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Text(
                etiqueta,
                textAlign: alineacion,
                style: EstilosLanding.etiqueta(
                  color: sobreAzul ? ColoresApp.dorado : ColoresApp.azulTurqui,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            titulo,
            textAlign: alineacion,
            style: EstilosLanding.titulo(
              tamanio: EstilosLanding.tamanioTituloSeccion(tamano),
              color: sobreAzul
                  ? ColoresApp.blanco
                  : ColoresApp.azulTurquiOscuro,
              alto: 1.15,
            ),
          ),
        ),
        if (lead != null) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              lead!,
              textAlign: alineacion,
              style: EstilosLanding.cuerpo(
                color: sobreAzul
                    ? EstilosLanding.textoSobreAzul
                    : EstilosLanding.textoSuave,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
