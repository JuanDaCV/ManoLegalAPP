import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';

/// Símbolo de marca de la landing.
///
/// Este es el único punto donde, en el futuro, se reemplazará el símbolo
/// estático por uno animado o en 3D: el resto de la landing solo usa este
/// widget.
class SimboloManoLegal extends StatelessWidget {
  const SimboloManoLegal({super.key, this.tamanio = 40, this.conAnillo = true});

  final double tamanio;
  final bool conAnillo;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: tamanio,
        height: tamanio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColoresApp.azulProfundo, ColoresApp.azulTurqui],
            ),
            borderRadius: BorderRadius.circular(tamanio * 0.28),
            border: conAnillo
                ? Border.all(
                    color: ColoresApp.dorado.withValues(alpha: 0.6),
                    width: tamanio >= 64 ? 1.5 : 1,
                  )
                : null,
          ),
          child: Center(
            child: Icon(
              Icons.balance,
              size: tamanio * 0.55,
              color: ColoresApp.blanco,
            ),
          ),
        ),
      ),
    );
  }
}

/// Símbolo + nombre. [mostrarNombre] permite ocultar la palabra en pantallas
/// muy estrechas.
class MarcaLanding extends StatelessWidget {
  const MarcaLanding({
    super.key,
    this.color = ColoresApp.blanco,
    this.mostrarNombre = true,
  });

  final Color color;
  final bool mostrarNombre;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 20,
      color: color,
    );
    return Semantics(
      label: 'ManoLegal',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SimboloManoLegal(tamanio: 32),
            if (mostrarNombre) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'ManoLegal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EstilosLanding.marca(base),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
