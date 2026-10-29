import 'package:flutter/material.dart';

import 'estilos_landing.dart';

/// Ventana de navegador con barra superior; recorta [contenido] a sus bordes.
class MarcoNavegador extends StatelessWidget {
  const MarcoNavegador({super.key, required this.contenido});

  final Widget contenido;

  static const Color _barra = Color(0xFF111A2B);

  @override
  Widget build(BuildContext context) {
    final borde = BorderRadius.circular(14);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borde,
        color: _barra,
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 48,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borde,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const _BarraNavegador(), contenido],
        ),
      ),
    );
  }
}

class _BarraNavegador extends StatelessWidget {
  const _BarraNavegador();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final conPildora = restricciones.maxWidth >= 240;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const _Punto(Color(0xFFB85450)),
                const _Punto(Color(0xFFC9A04A)),
                const _Punto(Color(0xFF5E9A61)),
                if (conPildora) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 3,
                          ),
                          child: Text(
                            'ManoLegal · Panel del cliente',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: EstilosLanding.textoSobreAzul,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Equilibra los tres puntos para que la píldora quede centrada.
                  const SizedBox(width: 48),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: SizedBox(
        width: 10,
        height: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
