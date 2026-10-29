import 'package:flutter/material.dart';

import '../../tema/tema_app.dart';

/// Avatar de un abogado: foto si hay [fotoUrl], o iniciales sobre azul turquí
/// si no. Siempre cuadrado con esquinas redondeadas y un filete dorado
/// alrededor — NUNCA circular, a diferencia del avatar genérico anterior.
class AvatarAbogado extends StatelessWidget {
  final String iniciales;
  final String? fotoUrl;
  final double tamanio;

  const AvatarAbogado({super.key, required this.iniciales, this.fotoUrl, required this.tamanio});

  @override
  Widget build(BuildContext context) {
    final radioExterno = tamanio * 0.2;
    return Container(
      width: tamanio,
      height: tamanio,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radioExterno),
        border: Border.all(color: ColoresApp.dorado, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radioExterno - 2),
        child: fotoUrl != null
            ? Image.network(
                fotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _Iniciales(iniciales: iniciales, tamanio: tamanio),
              )
            : _Iniciales(iniciales: iniciales, tamanio: tamanio),
      ),
    );
  }
}

class _Iniciales extends StatelessWidget {
  final String iniciales;
  final double tamanio;

  const _Iniciales({required this.iniciales, required this.tamanio});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColoresApp.azulTurqui,
      child: Center(
        child: Text(
          iniciales,
          style: TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: tamanio * 0.32),
        ),
      ),
    );
  }
}
