import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';
import 'navegacion_landing.dart';
import 'simbolo_manolegal.dart';

enum SeccionLanding { comoFunciona, verificacion, especialidades, app }

extension SeccionLandingTexto on SeccionLanding {
  String get etiqueta => switch (this) {
    SeccionLanding.comoFunciona => 'Cómo funciona',
    SeccionLanding.verificacion => 'Verificación',
    SeccionLanding.especialidades => 'Especialidades',
    SeccionLanding.app => 'La app',
  };
}

/// Barra superior fija: transparente sobre el hero y de cristal oscuro al
/// desplazar.
class BarraLanding extends StatelessWidget {
  const BarraLanding({
    super.key,
    required this.solida,
    required this.alIrA,
    required this.alDescargar,
  });

  final bool solida;
  final void Function(SeccionLanding) alIrA;
  final VoidCallback alDescargar;

  static double altoPara(TamanoLanding t) =>
      t == TamanoLanding.compacto ? 64 : 72;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final t = EstilosLanding.tamano(ancho);
        final esAncho = ancho >= 1024;
        // El margen va fuera del `AnimatedContainer`: si se animara, al
        // redimensionar la ventana la fila quedaría unos milisegundos con el
        // margen anterior y se desbordaría.
        return AnimatedContainer(
          duration: EstilosLanding.duracion(context, 220),
          height: altoPara(t),
          decoration: BoxDecoration(
            color: solida
                // Opaca y sin desenfoque de fondo. Antes era 0,93 con blur: el
                // blur ocultaba lo de abajo, pero había que recalcularlo en cada
                // cuadro de scroll, lo más costoso de la landing en equipos
                // lentos. Sin blur, cualquier transparencia deja ver el texto
                // de debajo, así que va opaca: se ve igual.
                ? EstilosLanding.noche
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: solida
                    ? ColoresApp.blanco.withValues(alpha: 0.08)
                    : Colors.transparent,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: EstilosLanding.margenLateral(t),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: EstilosLanding.anchoMaximo(t),
                ),
                child: esAncho
                    ? _FilaAncha(alIrA: alIrA, alDescargar: alDescargar)
                    : _FilaCompacta(
                        mostrarNombre: ancho >= 340,
                        alIrA: alIrA,
                        alDescargar: alDescargar,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilaAncha extends StatelessWidget {
  const _FilaAncha({required this.alIrA, required this.alDescargar});

  final void Function(SeccionLanding) alIrA;
  final VoidCallback alDescargar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(
          flex: 3,
          child: Align(alignment: Alignment.centerLeft, child: MarcaLanding()),
        ),
        Flexible(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in SeccionLanding.values)
                  _AnclaBarra(texto: s.etiqueta, alTocar: () => alIrA(s)),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: ColoresApp.blanco,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: alDescargar,
                    child: const Text('Descargar app'),
                  ),
                  const SizedBox(width: 8),
                  const BotonIngresarBarra(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaCompacta extends StatelessWidget {
  const _FilaCompacta({
    required this.mostrarNombre,
    required this.alIrA,
    required this.alDescargar,
  });

  final bool mostrarNombre;
  final void Function(SeccionLanding) alIrA;
  final VoidCallback alDescargar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: MarcaLanding(mostrarNombre: mostrarNombre),
          ),
        ),
        const SizedBox(width: 8),
        const BotonIngresarBarra(compacto: true),
        IconButton(
          tooltip: 'Abrir menú',
          color: ColoresApp.blanco,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => _abrirMenu(context),
          icon: const Icon(Icons.menu),
        ),
      ],
    );
  }

  void _abrirMenu(BuildContext contexto) {
    showModalBottomSheet<void>(
      context: contexto,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: ColoresApp.blanco,
      builder: (hoja) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in SeccionLanding.values)
              _OpcionMenu(
                texto: s.etiqueta,
                alTocar: () {
                  Navigator.pop(hoja);
                  alIrA(s);
                },
              ),
            const Divider(height: 24),
            _OpcionMenu(
              texto: 'Crear cuenta',
              alTocar: () {
                Navigator.pop(hoja);
                NavegacionLanding.irARegistro(contexto);
              },
            ),
            _OpcionMenu(
              texto: 'Descargar la app',
              alTocar: () {
                Navigator.pop(hoja);
                alDescargar();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  const _OpcionMenu({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 52,
      title: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: ColoresApp.azulTurquiOscuro,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: EstilosLanding.textoSuave,
      ),
      onTap: alTocar,
    );
  }
}

/// Botón "Ingresar" de la barra: abre el panel del visitante, que se explora
/// sin cuenta. El inicio de sesión sigue disponible desde ese panel y el pie.
class BotonIngresarBarra extends StatelessWidget {
  const BotonIngresarBarra({super.key, this.compacto = false});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.blanco,
        side: const BorderSide(color: ColoresApp.blanco),
        minimumSize: Size(0, compacto ? 40 : 44),
        padding: EdgeInsets.symmetric(horizontal: compacto ? 16 : 24),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      onPressed: () => NavegacionLanding.irAExplorar(context),
      child: const Text('Ingresar', maxLines: 1),
    );
  }
}

class _AnclaBarra extends StatefulWidget {
  const _AnclaBarra({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback alTocar;

  @override
  State<_AnclaBarra> createState() => _AnclaBarraState();
}

class _AnclaBarraState extends State<_AnclaBarra> {
  bool _resaltado = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: _resaltado
            ? ColoresApp.blanco
            : ColoresApp.blanco.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      onHover: (v) => setState(() => _resaltado = v),
      onFocusChange: (v) => setState(() => _resaltado = v),
      onPressed: widget.alTocar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.texto, maxLines: 1),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: EstilosLanding.duracion(context, 160),
            height: 2,
            width: _resaltado ? 24 : 0,
            color: ColoresApp.dorado,
          ),
        ],
      ),
    );
  }
}
