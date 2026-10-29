import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../modelo/modelo_resena.dart';
import '../../../tema/tema_app.dart';
import 'bloque_perfil.dart';

/// Bloque "Reseñas" del perfil del abogado: siempre de solo lectura,
/// independientemente de [editable] — las reseñas las dejan los clientes, no
/// se editan desde el perfil del abogado.
class SeccionResenas extends StatelessWidget {
  final List<ModeloResena> resenas;
  final double promedio;
  final bool editable;

  const SeccionResenas({super.key, required this.resenas, required this.promedio, required this.editable});

  @override
  Widget build(BuildContext context) {
    return BloquePerfil(
      titulo: 'Reseñas',
      icono: Icons.reviews_outlined,
      esDatoDelSistema: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: ColoresApp.dorado, size: 18),
              const SizedBox(width: 6),
              Text(
                '${promedio.toStringAsFixed(1)} · ${resenas.length} reseñas',
                style: const TextStyle(fontWeight: FontWeight.w700, color: ColoresApp.azulTurquiOscuro, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (resenas.isEmpty)
            const Text('Todavía no tienes reseñas.', style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13))
          else
            for (var i = 0; i < resenas.length; i++) ...[
              _ItemResena(resena: resenas[i]),
              if (i != resenas.length - 1) const Divider(height: 24),
            ],
        ],
      ),
    );
  }
}

class _ItemResena extends StatelessWidget {
  final ModeloResena resena;

  const _ItemResena({required this.resena});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                resena.autor,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColoresApp.azulTurquiOscuro),
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(resena.fecha),
              style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // La calificación de una reseña individual es un entero de 1 a 5,
        // pero este widget también dibuja promedios con media estrella, por
        // eso recibe un decimal.
        _EstrellasResena(calificacion: resena.calificacion.toDouble()),
        const SizedBox(height: 6),
        Text(
          '"${resena.comentario}"',
          style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}

class _EstrellasResena extends StatelessWidget {
  final double calificacion;

  const _EstrellasResena({required this.calificacion});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (indice) {
        final valorEstrella = indice + 1;
        final IconData icono;
        if (calificacion >= valorEstrella) {
          icono = Icons.star;
        } else if (calificacion >= valorEstrella - 0.5) {
          icono = Icons.star_half;
        } else {
          icono = Icons.star_border;
        }
        return Icon(icono, size: 14, color: ColoresApp.dorado);
      }),
    );
  }
}
