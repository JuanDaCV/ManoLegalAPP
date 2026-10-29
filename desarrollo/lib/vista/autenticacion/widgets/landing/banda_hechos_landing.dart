import 'package:flutter/material.dart';

import '../../../../modelo/especialidad_abogado.dart';
import '../../../../modelo/ubicacion_cali.dart';
import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';
import 'fila_altura_igual.dart';
import 'revelar_al_desplazar.dart';
import 'tarjeta_landing.dart';
import 'verificacion_landing.dart';

class _Hecho {
  const _Hecho(this.valor, this.titulo, this.detalle);

  final String valor;
  final String titulo;
  final String detalle;
}

/// Cuatro datos del producto calculados desde el código (enums y listas), de
/// modo que nunca se desfasan de lo que la app realmente ofrece.
class BandaHechosLanding extends StatelessWidget {
  const BandaHechosLanding({super.key});

  static List<_Hecho> get _hechos => [
    _Hecho(
      '${EspecialidadAbogado.values.where((e) => e != EspecialidadAbogado.otra).length}',
      'áreas del derecho',
      'y otras especialidades',
    ),
    _Hecho(
      '${UbicacionCali.values.length}',
      'zonas de cobertura',
      'Cali y Jamundí',
    ),
    _Hecho(
      '${documentosObligatorios.length}',
      'documentos obligatorios',
      'revisados antes de verificar',
    ),
    const _Hecho('Web · Android', 'una misma cuenta', 'navegador y app'),
  ];

  @override
  Widget build(BuildContext context) {
    return RevelarAlDesplazar(
      child: TarjetaLanding(
        radio: 24,
        elevable: false,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final ancho = restricciones.maxWidth;
            final items = [
              for (final h in _hechos)
                _ItemHecho(hecho: h, compacto: ancho < 420),
            ];
            if (ancho >= 800) {
              return FilaAlturaIgual(
                children: [
                  for (var i = 0; i < items.length; i++)
                    if (i == 0)
                      items[i]
                    else
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: EstilosLanding.borde),
                          ),
                        ),
                        child: items[i],
                      ),
                ],
              );
            }
            // 2×2 también en teléfonos: apilar las cuatro alargaba demasiado.
            if (ancho >= 260) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: items[0]),
                      Expanded(child: items[1]),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: items[2]),
                      Expanded(child: items[3]),
                    ],
                  ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: EstilosLanding.borde),
                    const SizedBox(height: 20),
                  ],
                  items[i],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemHecho extends StatelessWidget {
  const _ItemHecho({required this.hecho, this.compacto = false});

  final _Hecho hecho;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${hecho.valor} ${hecho.titulo}, ${hecho.detalle}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 2,
              color: ColoresApp.dorado,
              margin: const EdgeInsets.only(bottom: 14),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hecho.valor,
                maxLines: 1,
                style: EstilosLanding.titulo(
                  tamanio: compacto ? 28 : 34,
                  color: ColoresApp.azulTurqui,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hecho.titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compacto ? 13.5 : 15,
                fontWeight: FontWeight.w700,
                color: ColoresApp.azulTurquiOscuro,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hecho.detalle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compacto ? 12.5 : 14,
                color: EstilosLanding.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
