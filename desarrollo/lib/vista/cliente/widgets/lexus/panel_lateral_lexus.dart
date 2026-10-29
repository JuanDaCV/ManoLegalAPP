import 'package:flutter/material.dart';

import '../../../../configuracion/respuestas_locales_lexus.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/fondo_juridico.dart';
import '../../../widgets_comunes/tarjeta_cristal.dart';
import 'estilos_lexus.dart';
import 'mascota_lexus.dart';

const List<String> _queHace = [
  'Escuchar tu situación y hacerte preguntas.',
  'Identificar el área jurídica probable.',
  'Darte orientación general.',
  'Mostrarte abogados reales de ManoLegal.',
];

const List<String> _queNoHace = [
  'No es abogado ni da asesoría profesional.',
  'No conoce tu caso más allá de lo que cuentas.',
  'No muestra tu conversación a abogados ni al administrador de la app.',
];

/// Columna informativa de las pantallas anchas: qué hace y qué no hace
/// Lexus, para fijar expectativas antes de escribir.
class PanelLateralLexus extends StatelessWidget {
  const PanelLateralLexus({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned.fill(
                child: FondoJuridico(intensidadIcono: 0.06),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TarjetaCristal(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: MascotaLexus(
                          tamanio: 120,
                          estado: EstadoMascotaLexus.atento,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Lexus',
                            style: EstilosLexus.titulo(
                              tamanio: 24,
                              color: ColoresApp.blanco,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Asistente jurídico de ManoLegal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: ColoresApp.blanco.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _ListaPanel(
                        titulo: 'Qué puede hacer Lexus',
                        elementos: _queHace,
                      ),
                      const SizedBox(height: 18),
                      const _ListaPanel(
                        titulo: 'Lo que Lexus no hace',
                        elementos: _queNoHace,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: 15,
                color: EstilosLexus.textoSobreGris,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  RespuestasLocalesLexus.avisoPrivacidad,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: EstilosLexus.textoSobreGris,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListaPanel extends StatelessWidget {
  const _ListaPanel({required this.titulo, required this.elementos});

  final String titulo;
  final List<String> elementos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: EstilosLexus.titulo(tamanio: 14.5, color: ColoresApp.blanco),
        ),
        const SizedBox(height: 8),
        for (final elemento in elementos)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColoresApp.dorado,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    elemento,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: ColoresApp.blanco.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
