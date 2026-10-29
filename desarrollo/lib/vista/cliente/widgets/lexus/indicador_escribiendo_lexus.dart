import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_lexus.dart';
import 'mascota_lexus.dart';

/// "Lexus está escribiendo": rostro pensativo y tres puntos que laten.
/// Es la única animación sin fin de la sección y solo existe mientras hay una
/// consulta en curso.
class IndicadorEscribiendoLexus extends StatefulWidget {
  const IndicadorEscribiendoLexus({super.key});

  @override
  State<IndicadorEscribiendoLexus> createState() =>
      _IndicadorEscribiendoLexusState();
}

class _IndicadorEscribiendoLexusState extends State<IndicadorEscribiendoLexus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool? _sinMovimiento;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    if (sinMovimiento == _sinMovimiento) return;
    _sinMovimiento = sinMovimiento;
    if (sinMovimiento) {
      _animacion
        ..stop()
        ..value = 0.25;
    } else {
      _animacion.repeat();
    }
  }

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Lexus está escribiendo',
      child: ExcludeSemantics(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const MascotaLexus(
                tamanio: 24,
                estado: EstadoMascotaLexus.pensando,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: EstilosLexus.tarjeta(radio: 18),
                child: AnimatedBuilder(
                  animation: _animacion,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (var i = 0; i < 3; i++) _punto(i)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _punto(int indice) {
    final fase = (_animacion.value - indice * 0.18) * 2 * math.pi;
    final intensidad = (math.sin(fase) + 1) / 2;
    return Padding(
      padding: EdgeInsets.only(right: indice < 2 ? 5 : 0),
      child: Transform.translate(
        offset: Offset(0, -3 * intensidad),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColoresApp.azulTurqui.withValues(
              alpha: 0.35 + 0.5 * intensidad,
            ),
          ),
        ),
      ),
    );
  }
}
