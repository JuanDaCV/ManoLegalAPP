import 'package:flutter/material.dart';

import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import 'contorno_de_foco.dart';
import 'estilos_como_funciona.dart';

/// Dónde está un capítulo respecto al que se está leyendo.
enum EstadoNodoRiel { pasado, activo, futuro }

/// Una fila del riel de capítulos: el nodo numerado, el título y la duración,
/// unidos a las filas vecinas por la línea de tiempo.
///
/// Toda la fila es el botón (mínimo 56 px de alto, 48 si el riel es compacto).
class FilaRiel extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;
  final EstadoNodoRiel estado;
  final bool primero;
  final bool ultimo;
  final bool compacto;
  final VoidCallback alTocar;

  const FilaRiel({
    super.key,
    required this.capitulo,
    required this.estado,
    required this.primero,
    required this.ultimo,
    required this.compacto,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final activo = estado == EstadoNodoRiel.activo;
    final relleno = compacto ? 6.0 : 8.0;
    // El nodo mide 28 y está alineado arriba: su centro queda siempre a la
    // misma altura, y la línea de la línea de tiempo se ata a ese centro.
    final centroNodo = relleno + 14;

    // `excludeSemantics` deja una sola etiqueta limpia en vez de leer por
    // separado el número, el título y la duración; por eso la acción de tocar
    // se declara aquí: sin ella el lector de pantalla no podría activar la fila.
    return Semantics(
      button: true,
      selected: activo,
      label: 'Capítulo ${capitulo.numero}: ${capitulo.titulo}',
      onTap: alTocar,
      excludeSemantics: true,
      child: ContornoDeFoco(
        radio: BorderRadius.circular(12),
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(12),
          hoverColor: ColoresApp.azulTurqui.withValues(alpha: 0.04),
          focusColor: ColoresApp.azulTurqui.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compacto ? 48 : 56),
            child: Stack(
              children: [
                if (!(primero && ultimo))
                  Positioned(
                    left: 8 + 13,
                    top: primero ? centroNodo : 0,
                    bottom: primero || !ultimo ? 0 : null,
                    height: ultimo ? centroNodo : null,
                    width: 2,
                    child: ColoredBox(color: ColoresApp.grisTexto.withValues(alpha: 0.2)),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: relleno),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NodoRiel(numero: capitulo.numero, estado: estado),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                capitulo.titulo,
                                style: TextStyle(
                                  fontSize: compacto ? 13 : 14,
                                  height: 1.3,
                                  fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                                  color: activo
                                      ? ColoresApp.azulTurquiOscuro
                                      : EstilosComoFunciona.textoCuerpoSobrePagina,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                capitulo.duracionTexto,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: EstilosComoFunciona.textoCuerpoSobrePagina,
                                  fontFeatures: EstilosComoFunciona.cifrasTabulares,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculo numerado de la línea de tiempo: el activo lleva aro dorado, los
/// anteriores van rellenos y los siguientes, vacíos.
class NodoRiel extends StatelessWidget {
  final int numero;
  final EstadoNodoRiel estado;

  const NodoRiel({super.key, required this.numero, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (relleno, borde, colorNumero) = switch (estado) {
      EstadoNodoRiel.activo => (
        ColoresApp.azulTurqui,
        Border.all(color: ColoresApp.dorado, width: 2),
        ColoresApp.blanco,
      ),
      EstadoNodoRiel.pasado => (ColoresApp.azulTurqui.withValues(alpha: 0.85), null, ColoresApp.blanco),
      EstadoNodoRiel.futuro => (
        ColoresApp.blanco,
        Border.all(color: ColoresApp.azulTurqui.withValues(alpha: 0.3), width: 1.5),
        ColoresApp.azulTurqui,
      ),
    };
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: relleno, border: borde),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$numero',
          style: TextStyle(
            color: colorNumero,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            fontFeatures: EstilosComoFunciona.cifrasTabulares,
          ),
        ),
      ),
    );
  }
}

/// "Capítulo 3 de 6" con una barrita dorada que avanza.
class ProgresoRiel extends StatelessWidget {
  final int actual;
  final int total;

  const ProgresoRiel({super.key, required this.actual, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capítulo $actual de $total',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: EstilosComoFunciona.textoCuerpoSobrePagina,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: ColoresApp.grisTexto.withValues(alpha: 0.15)),
                  // Sin `begin`, la primera vez aparece ya en su sitio y solo
                  // los cambios siguientes se animan.
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: actual / total),
                    duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 300)),
                    curve: Curves.easeOutCubic,
                    builder: (context, fraccion, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraccion,
                      child: const ColoredBox(color: ColoresApp.dorado),
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
