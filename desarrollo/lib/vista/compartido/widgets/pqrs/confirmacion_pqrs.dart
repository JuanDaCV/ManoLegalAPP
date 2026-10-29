import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../modelo/modelo_pqrs.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/boton_personalizado.dart';
import 'estilos_pqrs.dart';

/// Mientras la Cloud Function asigna el radicado. Normalmente son unos pocos
/// segundos; si tarda más, se avisa sin dejar de esperar.
class EsperaRadicadoPqrs extends StatelessWidget {
  final bool esperaProlongada;
  final String? errorEspera;

  const EsperaRadicadoPqrs({super.key, required this.esperaProlongada, this.errorEspera});

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        children: [
          if (errorEspera == null) ...[
            const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: 20),
            const Text(
              'Registrando tu PQRS…',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: ColoresApp.azulTurquiOscuro),
            ),
            const SizedBox(height: 6),
            const Text(
              'Estamos generando tu número de radicado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
            ),
          ],
          if (esperaProlongada && errorEspera == null) ...[
            const SizedBox(height: 16),
            const Text(
              'Tu PQRS ya quedó registrada, pero el radicado está tardando más de lo normal. '
              'Puedes esperar aquí; también te llegará en el correo de confirmación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13, height: 1.4),
            ),
          ],
          if (errorEspera != null) ...[
            const Icon(Icons.info_outline, color: ColoresApp.azulTurqui, size: 36),
            const SizedBox(height: 12),
            Text(
              errorEspera!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirmación de una PQRS recibida. El radicado que se muestra es el que
/// escribió la Cloud Function en Firestore: el mismo del correo.
class ConfirmacionPqrs extends StatelessWidget {
  final ModeloPqrs pqrs;
  final String? correo;
  final VoidCallback onRadicarOtra;
  final VoidCallback onVolver;

  const ConfirmacionPqrs({
    super.key,
    required this.pqrs,
    this.correo,
    required this.onRadicarOtra,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = pqrs.creadoEn;
    return _Tarjeta(
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: ColoresApp.verdeVerificado, size: 48),
          const SizedBox(height: 14),
          Text(
            'Tu PQRS fue recibida correctamente',
            textAlign: TextAlign.center,
            style: EstilosPqrs.titulo(tamanio: 20),
          ),
          const SizedBox(height: 20),
          const Text('Radicado', style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
          const SizedBox(height: 4),
          SelectableText(
            pqrs.radicado!,
            textAlign: TextAlign.center,
            style: EstilosPqrs.titulo(tamanio: 26, color: ColoresApp.azulTurqui, espaciado: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            [
              'Tipo: ${pqrs.tipo.etiqueta}',
              if (fecha != null) 'Fecha de recepción: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}',
            ].join('\n'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14, height: 1.5),
          ),
          if (correo != null) ...[
            const SizedBox(height: 12),
            Text(
              'Enviaremos la confirmación con este radicado a $correo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Guarda este número para identificar tu solicitud posteriormente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          BotonPersonalizado(texto: 'Radicar otra PQRS', onPressed: onRadicarOtra),
          const SizedBox(height: 10),
          BotonPersonalizado(texto: 'Volver a PQRS', esPrimario: false, onPressed: onVolver),
        ],
      ),
    );
  }
}

/// Contenedor blanco con el mismo borde suave de las tarjetas de la sección.
class _Tarjeta extends StatelessWidget {
  final Widget child;

  const _Tarjeta({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColoresApp.grisTexto.withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }
}
