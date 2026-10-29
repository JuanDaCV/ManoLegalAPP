import 'package:flutter/material.dart';

import '../../../cliente/widgets/lexus/mascota_lexus.dart';
import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'navegacion_landing.dart';
import 'revelar_al_desplazar.dart';

/// Presenta a Lexus, el asistente de orientación inicial. Acepta una
/// `GlobalKey` para que "No sé qué área necesito" pueda desplazarse hasta aquí.
class LexusLanding extends StatelessWidget {
  const LexusLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return SeccionBase(
      color: ColoresApp.grisClaro,
      fondo: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.75, -0.4),
            radius: 0.9,
            colors: [Color(0x1AC9A227), Color(0x00C9A227)],
          ),
        ),
      ),
      builder: (context, t, util) {
        final esAncho = t == TamanoLanding.ancho || t == TamanoLanding.amplio;
        final mascota = _MascotaEnMedallon(grande: esAncho);
        final texto = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: esAncho
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            EncabezadoSeccion(
              etiqueta: 'ASISTENTE',
              titulo: '¿No sabes qué tipo de abogado necesitas?',
              lead:
                  'Lexus, el asistente de orientación inicial de ManoLegal, '
                  'te hace preguntas, identifica el área probable de tu caso '
                  'y puede mostrarte abogados verificados de esa '
                  'especialidad.',
              tamano: t,
              centrado: !esAncho,
            ),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ColoresApp.blanco,
                  borderRadius: BorderRadius.circular(EstilosLanding.radioM),
                  border: Border.all(color: EstilosLanding.borde),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: EstilosLanding.textoSuave,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lexus es un sistema de inteligencia artificial: no '
                          'es un abogado, puede equivocarse y no reemplaza la '
                          'asesoría profesional. Disponible para clientes con '
                          'cuenta.',
                          style: EstilosLanding.cuerpo(tamanio: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.azulTurqui,
                minimumSize: const Size(48, 48),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => NavegacionLanding.irAInicioSesion(context),
              child: const Text('Ingresar para usar Lexus'),
            ),
          ],
        );
        return RevelarAlDesplazar(
          child: esAncho
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    mascota,
                    const SizedBox(width: 64),
                    Expanded(child: texto),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [mascota, const SizedBox(height: 32), texto],
                ),
        );
      },
    );
  }
}

class _MascotaEnMedallon extends StatelessWidget {
  const _MascotaEnMedallon({required this.grande});

  final bool grande;

  @override
  Widget build(BuildContext context) {
    final mascota = grande ? 112.0 : 88.0;
    final medallon = mascota + 56;
    return SizedBox(
      width: medallon,
      height: medallon,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColoresApp.blanco,
          shape: BoxShape.circle,
          border: Border.all(color: ColoresApp.dorado, width: 2),
          boxShadow: EstilosLanding.sombraTarjeta,
        ),
        child: Center(
          child: MascotaLexus(
            tamanio: mascota,
            estado: EstadoMascotaLexus.atento,
            etiquetaSemantica: 'Lexus, el asistente de orientación inicial',
          ),
        ),
      ),
    );
  }
}
