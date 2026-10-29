import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../cliente/widgets/lexus/mascota_lexus.dart';
import '../../../tema/tema_app.dart';
import 'banda_hechos_landing.dart';
import 'barra_landing.dart';
import 'botones_landing.dart';
import 'cristal_landing.dart';
import 'estilos_landing.dart';
import 'fondo_landing.dart';
import 'insignia_verificado_landing.dart';
import 'marco_telefono.dart';
import 'navegacion_landing.dart';
import 'revelar_al_desplazar.dart';

/// Portada: fondo azul marino, propuesta de valor, llamadas a la acción y un
/// teléfono con capturas reales. La banda de datos cruza el borde inferior.
class HeroLanding extends StatelessWidget {
  const HeroLanding({super.key, required this.alDescargar});

  final VoidCallback alDescargar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final t = EstilosLanding.tamano(ancho);
        final esAncho = ancho >= 1024;
        final compacto = t == TamanoLanding.compacto;
        final margen = EstilosLanding.margenLateral(t);
        final arriba =
            BarraLanding.altoPara(t) +
            switch (t) {
              TamanoLanding.compacto => 40.0,
              TamanoLanding.medio => 64.0,
              _ => 80.0,
            };
        final texto = _ColumnaTexto(
          tamano: t,
          ancho: ancho,
          centrado: !esAncho,
          alDescargar: alDescargar,
        );
        final anchoTelefono = switch (t) {
          TamanoLanding.compacto => 220.0,
          TamanoLanding.medio => 260.0,
          _ => 290.0,
        };
        final visual = _VisualHero(
          anchoTelefono: anchoTelefono,
          conChips: !compacto,
        );
        return Stack(
          children: [
            Positioned.fill(
              bottom: 64,
              child: FondoLanding(
                curvaInferior: compacto ? 28 : 56,
                centroHalo: esAncho
                    ? const Alignment(0.55, -0.1)
                    : const Alignment(0, 0.35),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: margen),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: EstilosLanding.anchoMaximo(t),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: arriba, bottom: 56),
                        child: esAncho
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: 6, child: texto),
                                  const SizedBox(width: 32),
                                  Expanded(flex: 5, child: visual),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  texto,
                                  SizedBox(height: compacto ? 48 : 64),
                                  visual,
                                ],
                              ),
                      ),
                      const BandaHechosLanding(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColumnaTexto extends StatelessWidget {
  const _ColumnaTexto({
    required this.tamano,
    required this.ancho,
    required this.centrado,
    required this.alDescargar,
  });

  final TamanoLanding tamano;
  final double ancho;
  final bool centrado;
  final VoidCallback alDescargar;

  @override
  Widget build(BuildContext context) {
    final alineacion = centrado ? TextAlign.center : TextAlign.start;
    final eje = centrado ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final wrapAlineacion = centrado
        ? WrapAlignment.center
        : WrapAlignment.start;
    final tituloEstilo = EstilosLanding.titulo(
      tamanio: EstilosLanding.tamanioTituloHero(tamano, ancho),
      color: ColoresApp.blanco,
      alto: 1.08,
      espaciado: -1,
    );
    final compacto = tamano == TamanoLanding.compacto;

    return RevelarAlDesplazar(
      child: Column(
        crossAxisAlignment: eje,
        mainAxisSize: MainAxisSize.min,
        children: [
          CristalLanding(
            radio: 999,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Abogados en Cali con verificación documental',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: ColoresApp.blanco.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Semantics(
            header: true,
            container: true,
            label: 'Justicia accesible, verificada.',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: eje,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Justicia accesible,',
                    textAlign: alineacion,
                    style: tituloEstilo,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: centrado
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PalabraSubrayada(
                          texto: 'verificada',
                          estilo: tituloEstilo,
                        ),
                        Text('.', style: tituloEstilo),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Busca abogados por especialidad y zona, revisa su perfil y '
              'contáctalos directamente por WhatsApp o correo. Los perfiles '
              'verificados pasaron por la revisión de un administrador de '
              'ManoLegal.',
              textAlign: alineacion,
              style: EstilosLanding.cuerpo(
                tamanio: compacto ? 17 : 18,
                color: EstilosLanding.textoSobreAzul,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: wrapAlineacion,
            spacing: 12,
            runSpacing: 12,
            children: [
              BotonLanding(
                texto: 'Encontrar abogado',
                iconoFinal: Icons.arrow_forward,
                alPresionar: () => NavegacionLanding.irAExplorar(context),
              ),
              BotonLanding(
                texto: 'Descargar la app',
                estilo: EstiloBotonLanding.contornoClaro,
                iconoInicial: const FaIcon(FontAwesomeIcons.android, size: 20),
                alPresionar: alDescargar,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: wrapAlineacion,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '¿Eres nuevo? ',
                style: TextStyle(
                  fontSize: 15,
                  color: ColoresApp.blanco.withValues(alpha: 0.8),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ColoresApp.blanco,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: ColoresApp.dorado,
                  ),
                ),
                onPressed: () => NavegacionLanding.irARegistro(context),
                child: const Text('Crea tu cuenta'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: wrapAlineacion,
            spacing: 24,
            runSpacing: 10,
            children: const [
              _PuntoConfianza('Revisión documental por un administrador'),
              _PuntoConfianza('Contacto directo con el abogado'),
              _PuntoConfianza('Disponible en la Web y en Android'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PuntoConfianza extends StatelessWidget {
  const _PuntoConfianza(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 18, color: ColoresApp.dorado),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: EstilosLanding.textoSobreAzulSuave,
            ),
          ),
        ),
      ],
    );
  }
}

/// Palabra con un subrayado dorado trazado a mano (curva cuadrática).
class _PalabraSubrayada extends StatelessWidget {
  const _PalabraSubrayada({required this.texto, required this.estilo});

  final String texto;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _PintorSubrayado(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(texto, style: estilo),
      ),
    );
  }
}

class _PintorSubrayado extends CustomPainter {
  const _PintorSubrayado();

  @override
  void paint(Canvas canvas, Size size) {
    final ruta = Path()
      ..moveTo(0, size.height - 5)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height - 11,
        size.width,
        size.height - 4,
      );
    canvas.drawPath(
      ruta,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = ColoresApp.dorado,
    );
  }

  @override
  bool shouldRepaint(_PintorSubrayado anterior) => false;
}

class _VisualHero extends StatelessWidget {
  const _VisualHero({required this.anchoTelefono, required this.conChips});

  final double anchoTelefono;
  final bool conChips;

  @override
  Widget build(BuildContext context) {
    return RevelarAlDesplazar(
      retraso: const Duration(milliseconds: 120),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final disponible = restricciones.maxWidth;
          final ancho = math.min(
            disponible.isFinite ? disponible : anchoTelefono,
            anchoTelefono + (conChips ? 150 : 0),
          );
          final altoTelefono =
              (anchoTelefono * 0.93) * 1200 / 540 + anchoTelefono * 0.07;
          return Center(
            child: SizedBox(
              width: ancho,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: PantallasTelefono(
                      capturas: capturasApp,
                      ancho: math.min(anchoTelefono, ancho),
                    ),
                  ),
                  if (conChips) ...[
                    Positioned(
                      left: 0,
                      top: altoTelefono * 0.10,
                      child: _limitarTexto(const _ChipPerfil()),
                    ),
                    Positioned(
                      right: 0,
                      top: altoTelefono * 0.45,
                      child: _limitarTexto(const _ChipLexus()),
                    ),
                    Positioned(
                      left: 0,
                      top: altoTelefono * 0.78,
                      child: _limitarTexto(const _ChipContacto()),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

const TextStyle _estiloChipTitulo = TextStyle(
  fontSize: 13.5,
  fontWeight: FontWeight.w700,
  color: ColoresApp.blanco,
);
const TextStyle _estiloChipSub = TextStyle(
  fontSize: 12,
  color: EstilosLanding.textoSobreAzul,
);

class _ChipPerfil extends StatelessWidget {
  const _ChipPerfil();

  @override
  Widget build(BuildContext context) {
    // Tarjeta blanca sólida, como una pieza real de la interfaz: la insignia
    // verde solo conserva su contraste sobre blanco.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColoresApp.blanco,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x47000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const InsigniaVerificadoLanding(),
              Text(
                'Perfil revisado',
                style: _estiloChipSub.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColoresApp.azulTurquiOscuro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipLexus extends StatelessWidget {
  const _ChipLexus();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: CristalLanding(
        oscuro: true,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotaLexus(tamanio: 30),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lexus', style: _estiloChipTitulo),
                  Text('Orientación inicial con IA', style: _estiloChipSub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipContacto extends StatelessWidget {
  const _ChipContacto();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: CristalLanding(
        oscuro: true,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.whatsapp,
              size: 18,
              color: ColoresApp.blanco,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.mail_outline, size: 18, color: ColoresApp.blanco),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Contacto directo', style: _estiloChipTitulo),
                  Text('WhatsApp o correo', style: _estiloChipSub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las burbujas son decorativas y de ancho acotado: se limita su escala de
/// texto para que no desborden con el texto del sistema muy ampliado.
Widget _limitarTexto(Widget chip) =>
    MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2, child: chip);
