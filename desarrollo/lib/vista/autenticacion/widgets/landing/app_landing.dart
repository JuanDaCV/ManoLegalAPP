import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../tema/tema_app.dart';
import 'botones_landing.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'fondo_landing.dart';
import 'marco_navegador.dart';
import 'marco_telefono.dart';
import 'navegacion_landing.dart';
import 'revelar_al_desplazar.dart';

/// Tarjeta azul con la propuesta Web + Android y capturas reales del panel
/// del cliente y de Lexus.
class AppLanding extends StatelessWidget {
  const AppLanding({super.key, required this.alDescargar});

  final VoidCallback alDescargar;

  @override
  Widget build(BuildContext context) {
    return SeccionBase(
      color: ColoresApp.blanco,
      // La sigue Preguntas, también blanca: medio relleno evita un hueco doble.
      escalaRelleno: 0.5,
      builder: (context, t, util) {
        final esAncho = t == TamanoLanding.ancho || t == TamanoLanding.amplio;
        final relleno = switch (t) {
          TamanoLanding.compacto => 24.0,
          TamanoLanding.medio => 32.0,
          _ => 48.0,
        };
        final texto = _TextoApp(tamano: t, alDescargar: alDescargar);
        final visual = RevelarAlDesplazar(
          retraso: const Duration(milliseconds: 120),
          child: const _VisualApp(),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(EstilosLanding.radioXL),
          child: Stack(
            children: [
              const Positioned.fill(
                child: FondoLanding(centroHalo: Alignment(0.7, 0.2)),
              ),
              Padding(
                padding: EdgeInsets.all(relleno),
                child: esAncho
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: texto),
                          const SizedBox(width: 48),
                          Expanded(flex: 6, child: visual),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [texto, const SizedBox(height: 48), visual],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextoApp extends StatelessWidget {
  const _TextoApp({required this.tamano, required this.alDescargar});

  final TamanoLanding tamano;
  final VoidCallback alDescargar;

  static const _beneficios = [
    'Busca y compara abogados',
    'Contacto por WhatsApp o correo',
    'Lexus y la guía en video',
    'PQRS desde la app',
  ];

  @override
  Widget build(BuildContext context) {
    return RevelarAlDesplazar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoSeccion(
            etiqueta: 'WEB Y MÓVIL',
            titulo: 'ManoLegal en el navegador y en tu Android',
            lead:
                'Usa la misma cuenta desde la Web o instala la app en tu '
                'teléfono Android.',
            tamano: tamano,
            sobreAzul: true,
          ),
          const SizedBox(height: 28),
          for (final b in _beneficios)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle,
                      size: 20,
                      color: ColoresApp.dorado,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b,
                      style: EstilosLanding.cuerpo(
                        tamanio: 16,
                        color: ColoresApp.blanco,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              BotonLanding(
                texto: 'Descargar la app',
                iconoInicial: const FaIcon(FontAwesomeIcons.android, size: 20),
                alPresionar: alDescargar,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ColoresApp.blanco,
                  minimumSize: const Size(48, 48),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => NavegacionLanding.irAInicioSesion(context),
                child: const Text('Usar en la Web'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'La app se instala desde el archivo APK; no está en Google Play. '
            'Aún no hay versión para iPhone: puedes usar la Web.',
            style: EstilosLanding.cuerpo(
              tamanio: 13,
              color: EstilosLanding.textoSobreAzulSuave,
            ),
          ),
        ],
      ),
    );
  }
}

/// Navegador con el panel real y un teléfono que lo solapa en la esquina
/// inferior derecha. Todas las medidas salen del ancho disponible.
class _VisualApp extends StatelessWidget {
  const _VisualApp();

  /// Alto de un [MarcoTelefono] por unidad de ancho (pantalla 540:1200 más
  /// el bisel de 3,5 % por lado).
  static const double _proporcionTelefono = 0.93 * 1200 / 540 + 0.07;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final anchoTelefono = math.min(
          ancho >= 520 ? 150.0 : 120.0,
          ancho * 0.38,
        );
        final altoTelefono = anchoTelefono * _proporcionTelefono;
        final anchoNavegador = ancho - anchoTelefono * 0.4;
        // 34 de barra + 2 de borde + imagen 1200:750.
        final altoNavegador = 36 + anchoNavegador * 750 / 1200;
        final arribaTelefono = math.max(0.0, altoNavegador + 40 - altoTelefono);
        return SizedBox(
          width: ancho,
          height: arribaTelefono + altoTelefono,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: anchoNavegador,
                child: MarcoNavegador(
                  contenido: AspectRatio(
                    aspectRatio: 1200 / 750,
                    child: ImagenCaptura(
                      ruta: 'img/landing/panel_web.webp',
                      ancho: anchoNavegador,
                      etiqueta: 'Captura real: panel del cliente en la Web',
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: arribaTelefono,
                width: anchoTelefono,
                child: MarcoTelefono(
                  ancho: anchoTelefono,
                  pantalla: ImagenCaptura(
                    ruta: 'img/landing/pantalla_lexus.webp',
                    ancho: anchoTelefono,
                    etiqueta: 'Captura real de la app: Lexus',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
