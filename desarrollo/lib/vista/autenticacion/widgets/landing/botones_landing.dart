import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

enum EstiloBotonLanding {
  /// Relleno blanco, texto azul: sobre fondos azul marino.
  claro,

  /// Relleno azul turquí, texto blanco: sobre fondos claros.
  oscuro,

  /// Contorno blanco translúcido: acción secundaria sobre azul marino.
  contornoClaro,
}

/// Botón tipo píldora de la landing. El texto puede partirse en varias líneas
/// para que nunca desborde con pantallas estrechas o texto ampliado.
class BotonLanding extends StatelessWidget {
  const BotonLanding({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.estilo = EstiloBotonLanding.claro,
    this.iconoInicial,
    this.iconoFinal,
    this.alto = 56,
  });

  final String texto;
  final VoidCallback alPresionar;
  final EstiloBotonLanding estilo;
  final Widget? iconoInicial;
  final IconData? iconoFinal;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final contenido = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconoInicial != null) ...[iconoInicial!, const SizedBox(width: 10)],
        Flexible(child: Text(texto, textAlign: TextAlign.center)),
        if (iconoFinal != null) ...[
          const SizedBox(width: 8),
          Icon(iconoFinal, size: 20),
        ],
      ],
    );
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    const padding = EdgeInsets.symmetric(horizontal: 28, vertical: 12);
    final tamanoMinimo = Size(0, alto);

    if (estilo == EstiloBotonLanding.contornoClaro) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresApp.blanco,
          side: BorderSide(color: ColoresApp.blanco.withValues(alpha: 0.35)),
          minimumSize: tamanoMinimo,
          padding: padding,
          textStyle: textStyle,
          shape: const StadiumBorder(),
        ),
        onPressed: alPresionar,
        child: contenido,
      );
    }
    final claro = estilo == EstiloBotonLanding.claro;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: claro ? ColoresApp.blanco : ColoresApp.azulTurqui,
        foregroundColor: claro ? ColoresApp.azulTurqui : ColoresApp.blanco,
        minimumSize: tamanoMinimo,
        padding: padding,
        textStyle: textStyle,
        elevation: claro ? 0 : 2,
        shape: const StadiumBorder(),
      ),
      onPressed: alPresionar,
      child: contenido,
    );
  }
}
