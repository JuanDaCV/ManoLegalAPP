import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../tema/tema_app.dart';
import 'widgets/landing/app_landing.dart';
import 'widgets/landing/barra_landing.dart';
import 'widgets/landing/dialogo_descarga_app.dart';
import 'widgets/landing/especialidades_landing.dart';
import 'widgets/landing/estilos_landing.dart';
import 'widgets/landing/hero_landing.dart';
import 'widgets/landing/lexus_landing.dart';
import 'widgets/landing/pasos_landing.dart';
import 'widgets/landing/perfil_ilustrativo_landing.dart';
import 'widgets/landing/pie_landing.dart';
import 'widgets/landing/preguntas_landing.dart';
import 'widgets/landing/verificacion_landing.dart';

/// Landing page mostrada en Web cuando no hay sesión activa.
///
/// Cada sección vive en `widgets/landing/`; aquí solo se compone la página,
/// se controla el desplazamiento y se resuelven los anclajes de la barra.
class PantallaLandingWeb extends StatefulWidget {
  const PantallaLandingWeb({super.key});

  @override
  State<PantallaLandingWeb> createState() => _PantallaLandingWebState();
}

class _PantallaLandingWebState extends State<PantallaLandingWeb> {
  final ScrollController _controlador = ScrollController();
  final ValueNotifier<bool> _barraSolida = ValueNotifier<bool>(false);
  final Map<SeccionLanding, GlobalKey> _claves = {
    for (final s in SeccionLanding.values) s: GlobalKey(),
  };
  final GlobalKey _claveLexus = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controlador.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _controlador.removeListener(_alDesplazar);
    _controlador.dispose();
    _barraSolida.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    if (!_controlador.hasClients) return;
    _barraSolida.value = _controlador.offset > 12;
  }

  void _irA(SeccionLanding seccion) => _desplazarA(_claves[seccion]!);

  void _irALexus() => _desplazarA(_claveLexus);

  void _descargar() => mostrarDescargaApp(context);

  /// Lleva el borde superior de la sección justo debajo de la barra fija.
  void _desplazarA(GlobalKey clave) {
    final contexto = clave.currentContext;
    if (contexto == null || !_controlador.hasClients) return;
    final caja = contexto.findRenderObject();
    if (caja is! RenderBox) return;
    final visor = RenderAbstractViewport.maybeOf(caja);
    if (visor == null) return;
    final altoBarra = BarraLanding.altoPara(
      EstilosLanding.tamano(MediaQuery.sizeOf(context).width),
    );
    final alineado = visor.getOffsetToReveal(caja, 0).offset;
    final objetivo = (alineado - altoBarra).clamp(
      0.0,
      _controlador.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.jumpTo(objetivo);
    } else {
      _controlador.animateTo(
        objetivo,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _controlador,
            // Cada sección es una capa propia: al desplazarse, el visor solo
            // recoloca las capas ya pintadas en lugar de volver a pintar toda
            // la página en cada cuadro. Las claves de anclaje siguen en la
            // sección, así que la navegación de la barra no cambia.
            child: Column(
              children: [
                for (final seccion in <Widget>[
                  HeroLanding(alDescargar: _descargar),
                  PasosLanding(
                    key: _claves[SeccionLanding.comoFunciona],
                    alIrALexus: _irALexus,
                  ),
                  VerificacionLanding(
                    key: _claves[SeccionLanding.verificacion],
                  ),
                  EspecialidadesLanding(
                    key: _claves[SeccionLanding.especialidades],
                  ),
                  const PerfilIlustrativoLanding(),
                  LexusLanding(key: _claveLexus),
                  AppLanding(
                    key: _claves[SeccionLanding.app],
                    alDescargar: _descargar,
                  ),
                  const PreguntasLanding(),
                  PieLanding(alIrA: _irA, alDescargar: _descargar),
                ])
                  RepaintBoundary(child: seccion),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _barraSolida,
              builder: (context, solida, _) => BarraLanding(
                solida: solida,
                alIrA: _irA,
                alDescargar: _descargar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
