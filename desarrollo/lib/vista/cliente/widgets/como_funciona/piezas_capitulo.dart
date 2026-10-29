import 'package:flutter/material.dart';

import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import 'estilos_como_funciona.dart';

/// Círculo azul turquí con el número del capítulo (tarjetas).
class InsigniaNumeroCapitulo extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;

  const InsigniaNumeroCapitulo({super.key, required this.capitulo});

  @override
  Widget build(BuildContext context) {
    // El número ya está en la etiqueta "CAPÍTULO 03 · 0:48" que la acompaña.
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: ColoresApp.azulTurqui, shape: BoxShape.circle),
        child: Text(
          capitulo.numeroTexto,
          style: const TextStyle(
            color: ColoresApp.blanco,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            fontFeatures: EstilosComoFunciona.cifrasTabulares,
          ),
        ),
      ),
    );
  }
}

/// Rótulo "CAPÍTULO 03 · 0:48" sobre el título.
class EtiquetaCapitulo extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;

  const EtiquetaCapitulo({super.key, required this.capitulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      'CAPÍTULO ${capitulo.numeroTexto} · ${capitulo.duracionTexto}',
      // Leído tal cual, "03 · 0:48" no se entiende: se dice con palabras.
      semanticsLabel: 'Capítulo ${capitulo.numero}. Duración: ${capitulo.duracionHablada}.',
      style: EstilosComoFunciona.etiquetaSuperior(),
    );
  }
}

/// Título de un capítulo, marcado como encabezado para los lectores de
/// pantalla (permite saltar de capítulo en capítulo).
class TituloCapitulo extends StatelessWidget {
  final String texto;
  final double tamanio;

  const TituloCapitulo({super.key, required this.texto, required this.tamanio});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(texto, style: EstilosComoFunciona.titulo(tamanio: tamanio, altura: 1.2)),
    );
  }
}

/// Los tres temas del capítulo como píldoras (tarjetas).
class PildorasTemas extends StatelessWidget {
  final List<String> temas;

  const PildorasTemas({super.key, required this.temas});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tema in temas)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColoresApp.azulTurqui.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tema,
              style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// Los tres temas con un punto dorado delante (escenas de pantalla ancha).
class TemasConPunto extends StatelessWidget {
  final List<String> temas;

  const TemasConPunto({super.key, required this.temas});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        for (final tema in temas)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: ColoresApp.dorado, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  tema,
                  style: const TextStyle(
                    color: ColoresApp.azulTurquiOscuro,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Número enorme y casi transparente detrás del título, de adorno. En la
/// escena ancha se superpone al encabezado del capítulo.
class NumeralFantasma extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;
  final double tamanio;

  const NumeralFantasma({super.key, required this.capitulo, required this.tamanio});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        capitulo.numeroTexto,
        softWrap: false,
        style: EstilosComoFunciona.titulo(
          tamanio: tamanio,
          color: ColoresApp.azulTurqui.withValues(alpha: 0.07),
          altura: 1,
        ),
      ),
    );
  }
}
