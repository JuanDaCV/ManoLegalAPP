import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../modelo/modelo_resultado_abogado.dart';
import '../../../compartido/widgets/tarjeta_abogado.dart';
import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'insignia_verificado_landing.dart';
import 'navegacion_landing.dart';
import 'revelar_al_desplazar.dart';
import 'tarjeta_landing.dart';

const List<(String, String)> _explicaciones = [
  (
    'Especialidad y zona',
    'El área del derecho y la zona de Cali donde atiende.',
  ),
  (
    'Insignia de verificación',
    'Aparece cuando un administrador revisó sus documentos.',
  ),
  (
    'Reseñas de clientes',
    'La calificación se calcula con las reseñas que dejan otros clientes.',
  ),
  ('Tarifa de referencia', 'Si el abogado la publica, ves desde cuánto cobra.'),
  (
    'Contacto directo',
    'WhatsApp o correo, según los datos que el abogado publique.',
  ),
];

/// Sección "Perfiles". Quien no ha ingresado no puede leer datos de abogados
/// (las reglas de Firestore exigen sesión), así que hoy muestra una
/// ILUSTRACIÓN rotulada. Si en el futuro se entregan [abogadosReales], los
/// muestra con la tarjeta real.
class PerfilIlustrativoLanding extends StatelessWidget {
  const PerfilIlustrativoLanding({super.key, this.abogadosReales = const []});

  final List<ModeloResultadoAbogado> abogadosReales;

  @override
  Widget build(BuildContext context) {
    return SeccionBase(
      color: ColoresApp.blanco,
      builder: (context, t, util) {
        final esAncho = t == TamanoLanding.ancho || t == TamanoLanding.amplio;
        final encabezado = RevelarAlDesplazar(
          child: EncabezadoSeccion(
            etiqueta: 'PERFILES',
            titulo: 'Así conoces a un abogado antes de contactarlo',
            tamano: t,
            centrado: true,
          ),
        );
        if (abogadosReales.isNotEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              encabezado,
              const SizedBox(height: 48),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  for (final abogado in abogadosReales)
                    SizedBox(
                      width: util < 420 ? util : 420,
                      child: TarjetaAbogado(
                        abogado: abogado,
                        esEscritorio: false,
                        onVerPerfil: () =>
                            NavegacionLanding.irAInicioSesion(context),
                      ),
                    ),
                ],
              ),
            ],
          );
        }

        const tarjeta = _TarjetaIlustrativa();
        const lista = _ListaExplicativa();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            encabezado,
            const SizedBox(height: 56),
            if (esAncho)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 480),
                        child: tarjeta,
                      ),
                    ),
                  ),
                  SizedBox(width: 64),
                  Expanded(flex: 6, child: lista),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: tarjeta,
                  ),
                  const SizedBox(height: 40),
                  lista,
                ],
              ),
            const SizedBox(height: 40),
            const _NotaIlustracion(),
          ],
        );
      },
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador(this.numero);

  final int numero;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ColoresApp.dorado,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$numero',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: ColoresApp.azulTurquiOscuro,
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaIlustrativa extends StatelessWidget {
  const _TarjetaIlustrativa();

  Widget _barra(double factor) => SizedBox(
    height: 12,
    child: FractionallySizedBox(
      widthFactor: factor,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
  );

  Widget _chip(String texto) => DecoratedBox(
    decoration: BoxDecoration(
      color: ColoresApp.grisClaro,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: EstilosLanding.borde),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ColoresApp.azulTurqui,
        ),
      ),
    ),
  );

  Widget _botonDeshabilitado(Widget icono, String texto) => OutlinedButton(
    onPressed: null,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [icono, const SizedBox(width: 8), Text(texto)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return TarjetaLanding(
      elevable: false,
      radio: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColoresApp.azulTurqui.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: EstilosLanding.doradoSuave),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  'Ilustración',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.azulTurqui,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _barra(0.75),
                          const SizedBox(height: 10),
                          _barra(0.45),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip('Especialidad'),
                    _chip('Zona de Cali'),
                    const _Marcador(1),
                  ],
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [InsigniaVerificadoLanding(), _Marcador(2)],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 5; i++)
                          const Icon(
                            Icons.star_border,
                            size: 18,
                            color: ColoresApp.dorado,
                          ),
                      ],
                    ),
                    const Text(
                      'Reseñas de clientes',
                      style: TextStyle(
                        fontSize: 13,
                        color: EstilosLanding.textoSuave,
                      ),
                    ),
                    const _Marcador(3),
                  ],
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Tarifa de referencia',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColoresApp.azulTurquiOscuro,
                      ),
                    ),
                    _Marcador(4),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _botonDeshabilitado(
                      const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                      'WhatsApp',
                    ),
                    _botonDeshabilitado(
                      const Icon(Icons.mail_outline, size: 18),
                      'Correo',
                    ),
                    const _Marcador(5),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaExplicativa extends StatelessWidget {
  const _ListaExplicativa();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _explicaciones.length; i++)
          RevelarAlDesplazar(
            retraso: Duration(milliseconds: 60 * i),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: i == _explicaciones.length - 1 ? 0 : 24,
              ),
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: _Marcador(i + 1),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _explicaciones[i].$1,
                            style: EstilosLanding.titulo(
                              tamanio: 18,
                              alto: 1.3,
                              espaciado: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _explicaciones[i].$2,
                            style: EstilosLanding.cuerpo(
                              tamanio: 15,
                              color: EstilosLanding.textoSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotaIlustracion extends StatelessWidget {
  const _NotaIlustracion();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: EstilosLanding.textoSuave,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Ilustración. Los perfiles reales se consultan al ingresar a '
            'ManoLegal.',
            style: EstilosLanding.cuerpo(
              tamanio: 13,
              color: EstilosLanding.textoSuave,
            ),
          ),
        ),
      ],
    );
  }
}
