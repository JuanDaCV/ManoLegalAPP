import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import 'contorno_de_foco.dart';
import 'estilos_como_funciona.dart';
import 'fila_riel.dart';

/// Riel lateral de pantalla ancha: la lista de capítulos como una línea de
/// tiempo que se queda fija mientras se recorre la página, marca el capítulo
/// que se está leyendo y permite saltar a cualquiera.
///
/// Es una superficie blanca semitransparente sin `BackdropFilter`: el
/// desenfoque en una capa que se mueve con el desplazamiento es caro y aquí
/// no aporta nada.
class RielCapitulos extends StatelessWidget {
  final List<ModeloCapituloComoFunciona> capitulos;

  /// Índice del capítulo que se está viendo (lo calcula la sección al
  /// desplazarse).
  final ValueListenable<int> capituloVisible;
  final ValueChanged<int> alSeleccionar;

  /// Filas más bajas, para pantallas cortas.
  final bool compacto;

  const RielCapitulos({
    super.key,
    required this.capitulos,
    required this.capituloVisible,
    required this.alSeleccionar,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        color: ColoresApp.blanco.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.blanco),
        boxShadow: [
          BoxShadow(color: ColoresApp.azulTurqui.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      // El `Material` va dentro del contenedor para que los efectos de toque
      // se dibujen sobre su fondo y no debajo.
      child: Material(
        type: MaterialType.transparency,
        child: ValueListenableBuilder<int>(
          valueListenable: capituloVisible,
          builder: (context, activo, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text('CAPÍTULOS', style: EstilosComoFunciona.etiquetaSuperior()),
              ),
              // Si la pantalla es tan baja que los seis capítulos no caben,
              // la lista se desplaza dentro del riel en vez de desbordar.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < capitulos.length; i++)
                        FilaRiel(
                          capitulo: capitulos[i],
                          estado: i == activo
                              ? EstadoNodoRiel.activo
                              : (i < activo ? EstadoNodoRiel.pasado : EstadoNodoRiel.futuro),
                          primero: i == 0,
                          ultimo: i == capitulos.length - 1,
                          compacto: compacto,
                          alTocar: () => alSeleccionar(i),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ProgresoRiel(actual: activo + 1, total: capitulos.length),
            ],
          ),
        ),
      ),
    );
  }
}

/// Índice de pantallas pequeñas y medianas: seis botones circulares con el
/// número de cada capítulo, para saltar sin recorrer toda la página.
class ChipsCapitulos extends StatelessWidget {
  final List<ModeloCapituloComoFunciona> capitulos;
  final ValueChanged<int> alSeleccionar;

  const ChipsCapitulos({super.key, required this.capitulos, required this.alSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ir a un capítulo',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: EstilosComoFunciona.textoCuerpoSobrePagina,
          ),
        ),
        const SizedBox(height: 8),
        // `Wrap`: a 320 px no caben los seis en una fila y los últimos bajan.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < capitulos.length; i++)
              _ChipNumero(capitulo: capitulos[i], alTocar: () => alSeleccionar(i)),
          ],
        ),
      ],
    );
  }
}

class _ChipNumero extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;
  final VoidCallback alTocar;

  const _ChipNumero({required this.capitulo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final etiqueta = 'Ir al capítulo ${capitulo.numero}: ${capitulo.titulo}';
    return Semantics(
      button: true,
      label: etiqueta,
      onTap: alTocar,
      excludeSemantics: true,
      child: Tooltip(
        message: etiqueta,
        child: Material(
          color: ColoresApp.azulTurqui,
          shape: const CircleBorder(side: BorderSide(color: ColoresApp.dorado, width: 1.5)),
          child: ContornoDeFoco(
            forma: BoxShape.circle,
            color: ColoresApp.blanco,
            child: InkWell(
              customBorder: const CircleBorder(),
              hoverColor: ColoresApp.blanco.withValues(alpha: 0.12),
              focusColor: ColoresApp.blanco.withValues(alpha: 0.2),
              splashColor: ColoresApp.blanco.withValues(alpha: 0.16),
              onTap: alTocar,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      capitulo.numeroTexto,
                      style: const TextStyle(
                        color: ColoresApp.blanco,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: EstilosComoFunciona.cifrasTabulares,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
