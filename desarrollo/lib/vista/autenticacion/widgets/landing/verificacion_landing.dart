import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'cristal_landing.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'fondo_landing.dart';
import 'insignia_verificado_landing.dart';
import 'revelar_al_desplazar.dart';
import 'simbolo_manolegal.dart';
import 'tarjeta_landing.dart';

/// Documentos que todo abogado debe subir y que el administrador revisa.
const documentosObligatorios = [
  'Cédula de ciudadanía',
  'Tarjeta profesional',
  'Certificado de vigencia RNA/SIRNA',
  'Antecedentes disciplinarios',
];

const documentoOpcional = 'Diploma de pregrado';

class _Nodo {
  const _Nodo(this.icono, this.titulo, this.texto);

  final IconData icono;
  final String titulo;
  final String texto;
}

const List<_Nodo> _nodos = [
  _Nodo(
    Icons.how_to_reg_outlined,
    'Registro en tres pasos',
    'Datos personales, información profesional y documentos en PDF.',
  ),
  _Nodo(
    Icons.hourglass_top_outlined,
    'Perfil pendiente',
    'Todo perfil nace sin verificar y no lleva insignia mientras tanto.',
  ),
  _Nodo(
    Icons.admin_panel_settings_outlined,
    'Revisión del administrador',
    'Abre cada documento y cuenta con accesos a fuentes oficiales para '
        'contrastar la información.',
  ),
  _Nodo(
    Icons.verified_outlined,
    'Insignia «Verificado»',
    'Si la revisión es satisfactoria, el perfil la muestra. El administrador '
        'también puede retirarla.',
  ),
];

/// Cómo se verifica un abogado: ruta de cuatro nodos y qué se revisa.
class VerificacionLanding extends StatelessWidget {
  const VerificacionLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return SeccionBase(
      fondo: const FondoLanding(centroHalo: Alignment(-0.7, 0.1)),
      builder: (context, t, util) {
        final esAncho = t == TamanoLanding.ancho || t == TamanoLanding.amplio;
        final encabezado = RevelarAlDesplazar(
          child: EncabezadoSeccion(
            etiqueta: 'VERIFICACIÓN',
            titulo:
                'Un perfil verificado pasó por una revisión, no solo por un '
                'formulario',
            lead:
                'Cada abogado que se registra sube su documentación. Un '
                'administrador de ManoLegal la revisa en el módulo '
                'administrativo antes de otorgar la insignia.',
            tamano: t,
            sobreAzul: true,
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (esAncho)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: encabezado),
                  const SizedBox(width: 48),
                  const _Emblema(),
                ],
              )
            else
              encabezado,
            const SizedBox(height: 64),
            esAncho ? const _RutaHorizontal() : const _RutaVertical(),
            const SizedBox(height: 64),
            if (esAncho)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PanelDocumentos()),
                  SizedBox(width: 24),
                  Expanded(child: _PanelBuscador()),
                ],
              )
            else
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PanelDocumentos(),
                  SizedBox(height: 24),
                  _PanelBuscador(),
                ],
              ),
            const SizedBox(height: 32),
            const RevelarAlDesplazar(child: _NotaHonestidad()),
          ],
        );
      },
    );
  }
}

class _Emblema extends StatelessWidget {
  const _Emblema();

  @override
  Widget build(BuildContext context) {
    Widget aro(double d, double alfa) => SizedBox(
      width: d,
      height: d,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ColoresApp.dorado.withValues(alpha: alfa),
            width: 1.2,
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            aro(220, 0.14),
            aro(164, 0.26),
            const SimboloManoLegal(tamanio: 96),
          ],
        ),
      ),
    );
  }
}

class _CirculoNodo extends StatelessWidget {
  const _CirculoNodo(this.icono);

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 56,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColoresApp.azulTurqui,
            border: Border.all(color: ColoresApp.dorado, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: ColoresApp.dorado.withValues(alpha: 0.25),
                blurRadius: 18,
              ),
            ],
          ),
          child: Icon(icono, color: ColoresApp.blanco, size: 26),
        ),
      ),
    );
  }
}

class _TextoNodo extends StatelessWidget {
  const _TextoNodo({required this.nodo, required this.alineacion});

  final _Nodo nodo;
  final TextAlign alineacion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alineacion == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nodo.titulo,
          textAlign: alineacion,
          style: EstilosLanding.titulo(
            tamanio: 19,
            color: ColoresApp.blanco,
            alto: 1.25,
            espaciado: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nodo.texto,
          textAlign: alineacion,
          style: EstilosLanding.cuerpo(
            tamanio: 15,
            color: EstilosLanding.textoSobreAzul,
          ),
        ),
      ],
    );
  }
}

class _RutaHorizontal extends StatelessWidget {
  const _RutaHorizontal();

  @override
  Widget build(BuildContext context) {
    Widget tramo(bool visible) => Expanded(
      child: visible
          ? const ColoredBox(
              color: EstilosLanding.doradoSuave,
              child: SizedBox(height: 1.5),
            )
          : const SizedBox.shrink(),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _nodos.length; i++)
          Expanded(
            child: RevelarAlDesplazar(
              retraso: Duration(milliseconds: 80 * i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      tramo(i > 0),
                      _CirculoNodo(_nodos[i].icono),
                      tramo(i < _nodos.length - 1),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _TextoNodo(
                      nodo: _nodos[i],
                      alineacion: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RutaVertical extends StatelessWidget {
  const _RutaVertical();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // El texto define el alto (como mínimo el del círculo) y el carril se
        // estira con `Positioned`, sin medir intrínsecos (ver
        // `FilaAlturaIgual`).
        for (var i = 0; i < _nodos.length; i++)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 56,
                child: Column(
                  children: [
                    _CirculoNodo(_nodos[i].icono),
                    if (i < _nodos.length - 1)
                      const Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 1.5,
                            child: ColoredBox(
                              color: EstilosLanding.doradoSuave,
                              child: SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: 56,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 76,
                    top: 4,
                    bottom: i == _nodos.length - 1 ? 0 : 32,
                  ),
                  child: RevelarAlDesplazar(
                    child: _TextoNodo(
                      nodo: _nodos[i],
                      alineacion: TextAlign.start,
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

class _PanelDocumentos extends StatelessWidget {
  const _PanelDocumentos();

  Widget _fila(String texto, {bool opcional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              opcional ? Icons.add_circle_outline : Icons.check_circle,
              size: 20,
              color: opcional
                  ? EstilosLanding.textoSobreAzulSuave
                  : ColoresApp.dorado,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              opcional ? '$texto (opcional)' : texto,
              style: EstilosLanding.cuerpo(
                tamanio: 16,
                color: opcional
                    ? EstilosLanding.textoSobreAzulSuave
                    : ColoresApp.blanco,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RevelarAlDesplazar(
      child: CristalLanding(
        radio: 20,
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Documentos que se revisan',
                  style: EstilosLanding.titulo(
                    tamanio: 20,
                    color: ColoresApp.blanco,
                    espaciado: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              for (final d in documentosObligatorios) _fila(d),
              _fila(documentoOpcional, opcional: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelBuscador extends StatelessWidget {
  const _PanelBuscador();

  Widget _barra(double factor) => SizedBox(
    height: 10,
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

  @override
  Widget build(BuildContext context) {
    return RevelarAlDesplazar(
      retraso: const Duration(milliseconds: 80),
      child: TarjetaLanding(
        elevable: false,
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Así lo ves en el buscador',
                  style: EstilosLanding.titulo(tamanio: 20, espaciado: 0),
                ),
              ),
              const SizedBox(height: 20),
              ExcludeSemantics(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _barra(0.7),
                          const SizedBox(height: 8),
                          _barra(0.45),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const InsigniaVerificadoLanding(),
              const SizedBox(height: 16),
              Text(
                'El buscador muestra por defecto solo perfiles verificados.',
                style: EstilosLanding.cuerpo(
                  tamanio: 14,
                  color: EstilosLanding.textoSuave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotaHonestidad extends StatelessWidget {
  const _NotaHonestidad();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 20,
          color: EstilosLanding.textoSobreAzulSuave,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'La verificación es una revisión documental del equipo de '
            'ManoLegal. No es una recomendación ni garantiza resultados.',
            style: EstilosLanding.cuerpo(
              tamanio: 14,
              color: EstilosLanding.textoSobreAzulSuave,
            ),
          ),
        ),
      ],
    );
  }
}
