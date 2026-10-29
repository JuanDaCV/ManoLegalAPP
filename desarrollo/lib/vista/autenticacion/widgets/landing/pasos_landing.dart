import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'botones_landing.dart';
import 'caja_icono.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'fila_altura_igual.dart';
import 'navegacion_landing.dart';
import 'revelar_al_desplazar.dart';
import 'tarjeta_landing.dart';

class _Paso {
  const _Paso(this.numero, this.icono, this.titulo, this.texto);

  final String numero;
  final IconData icono;
  final String titulo;
  final String texto;
}

const List<_Paso> _pasos = [
  _Paso(
    '01',
    Icons.person_add_alt_1_outlined,
    'Ingresa o crea tu cuenta',
    'Regístrate como cliente con tu correo o con tu cuenta de Google.',
  ),
  _Paso(
    '02',
    Icons.manage_search,
    'Busca por especialidad y zona',
    'Filtra por área del derecho, zona de Cali y calificación.',
  ),
  _Paso(
    '03',
    Icons.fact_check_outlined,
    'Revisa el perfil',
    'Experiencia, tarifa de referencia si la publica, reseñas de otros '
        'clientes e insignia de verificación.',
  ),
  _Paso(
    '04',
    Icons.forum_outlined,
    'Contacta directo',
    'Escríbele por WhatsApp o correo desde su perfil. El acuerdo es entre tú '
        'y el abogado.',
  ),
];

/// Los cuatro pasos para encontrar un abogado.
class PasosLanding extends StatelessWidget {
  const PasosLanding({super.key, required this.alIrALexus});

  final VoidCallback alIrALexus;

  @override
  Widget build(BuildContext context) {
    return SeccionBase(
      color: ColoresApp.blanco,
      builder: (context, t, util) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RevelarAlDesplazar(
              child: EncabezadoSeccion(
                etiqueta: 'CÓMO FUNCIONA',
                titulo: 'Del problema al abogado indicado, en cuatro pasos',
                lead: 'Sin intermediarios: tú eliges, tú contactas.',
                tamano: t,
                centrado: true,
              ),
            ),
            const SizedBox(height: 56),
            switch (t) {
              TamanoLanding.compacto => const _LineaDeTiempo(),
              TamanoLanding.medio => const _CuadriculaPasos(),
              _ => const _FilaPasos(),
            },
            const SizedBox(height: 48),
            RevelarAlDesplazar(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  BotonLanding(
                    texto: 'Encontrar abogado',
                    estilo: EstiloBotonLanding.oscuro,
                    alPresionar: () =>
                        NavegacionLanding.irAExplorar(context),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: ColoresApp.azulTurqui,
                      minimumSize: const Size(48, 48),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: alIrALexus,
                    child: const Text('No sé qué área necesito'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

TextStyle get _estiloNumero => EstilosLanding.titulo(
  tamanio: 28,
  color: EstilosLanding.doradoTexto,
  espaciado: 0,
);

class _ContenidoPaso extends StatelessWidget {
  const _ContenidoPaso({required this.paso, this.conNumero = false});

  final _Paso paso;
  final bool conNumero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CajaIcono(icono: paso.icono),
            if (conNumero) Text(paso.numero, style: _estiloNumero),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          paso.titulo,
          style: EstilosLanding.titulo(tamanio: 19, alto: 1.25, espaciado: 0),
        ),
        const SizedBox(height: 8),
        Text(
          paso.texto,
          style: EstilosLanding.cuerpo(
            tamanio: 15,
            color: EstilosLanding.textoSuave,
          ),
        ),
      ],
    );
  }
}

/// Escritorio: números unidos por un filete dorado y cuatro tarjetas.
class _FilaPasos extends StatelessWidget {
  const _FilaPasos();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < _pasos.length; i++) ...[
              if (i > 0) const SizedBox(width: 24),
              Expanded(
                child: Row(
                  children: [
                    Text(_pasos[i].numero, style: _estiloNumero),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ColoredBox(
                        color: EstilosLanding.doradoSuave,
                        child: const SizedBox(height: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        FilaAlturaIgual(
          espacio: 24,
          children: [
            for (var i = 0; i < _pasos.length; i++)
              RevelarAlDesplazar(
                retraso: Duration(milliseconds: 80 * i),
                child: TarjetaLanding(
                  padding: const EdgeInsets.all(24),
                  child: _ContenidoPaso(paso: _pasos[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CuadriculaPasos extends StatelessWidget {
  const _CuadriculaPasos();

  Widget _fila(int a, int b) {
    return FilaAlturaIgual(
      espacio: 24,
      children: [
        for (final i in [a, b])
          RevelarAlDesplazar(
            retraso: Duration(milliseconds: 80 * (i % 2)),
            child: TarjetaLanding(
              child: _ContenidoPaso(paso: _pasos[i], conNumero: true),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_fila(0, 1), const SizedBox(height: 24), _fila(2, 3)],
    );
  }
}

/// Móvil: línea de tiempo vertical con filete dorado a la izquierda.
class _LineaDeTiempo extends StatelessWidget {
  const _LineaDeTiempo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // La tarjeta define el alto y el tramo se estira con `Positioned`,
        // sin medir intrínsecos (ver `FilaAlturaIgual`).
        for (var i = 0; i < _pasos.length; i++)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _TramoLinea(
                  primero: i == 0,
                  ultimo: i == _pasos.length - 1,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    bottom: i == _pasos.length - 1 ? 0 : 20,
                  ),
                  child: RevelarAlDesplazar(
                    child: TarjetaLanding(
                      padding: const EdgeInsets.all(20),
                      child: _ContenidoPaso(paso: _pasos[i], conNumero: true),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TramoLinea extends StatelessWidget {
  const _TramoLinea({required this.primero, required this.ultimo});

  final bool primero;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    const centroPunto = 34.0;
    return ExcludeSemantics(
      child: SizedBox(
        width: 14,
        child: Stack(
          children: [
            Positioned(
              left: 6.25,
              width: 1.5,
              top: primero ? centroPunto : 0,
              height: ultimo ? centroPunto : null,
              bottom: ultimo ? null : 0,
              child: const ColoredBox(color: EstilosLanding.doradoSuave),
            ),
            const Positioned(
              top: centroPunto - 5,
              left: 2,
              child: SizedBox(
                width: 10,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColoresApp.dorado,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
