import 'package:flutter/material.dart';

import '../tema/tema_app.dart';

/// Botón reutilizable de la app, con variante primaria/secundaria y estado de carga.
class BotonPersonalizado extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool esPrimario;
  final bool cargando;

  const BotonPersonalizado({
    super.key,
    required this.texto,
    required this.onPressed,
    this.esPrimario = true,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    final deshabilitado = cargando || onPressed == null;
    final contenido = cargando
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: ColoresApp.blanco),
          )
        : Text(texto);

    if (esPrimario) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: deshabilitado ? null : onPressed,
          child: contenido,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: deshabilitado ? null : onPressed,
        child: cargando
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: ColoresApp.azulTurqui),
              )
            : Text(texto),
      ),
    );
  }
}
