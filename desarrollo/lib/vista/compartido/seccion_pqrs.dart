import 'package:flutter/material.dart';

import '../../controlador/controlador_pqrs.dart';
import '../../modelo/modelo_paso_recorrido.dart';
import '../../modelo/modelo_pqrs.dart';
import '../tema/tema_app.dart';
import '../widgets_comunes/boton_personalizado.dart';
import '../widgets_comunes/tarjeta_cristal.dart';
import 'widgets/pqrs/confirmacion_pqrs.dart';
import 'widgets/pqrs/estilos_pqrs.dart';
import 'widgets/pqrs/formulario_pqrs.dart';
import 'widgets/pqrs/iconos_pqrs.dart';
import 'widgets/recorrido/ambito_recorrido.dart';

class _CategoriaPqrs {
  final TipoPqrs tipo;
  final String titulo;
  final String descripcion;

  const _CategoriaPqrs({required this.tipo, required this.titulo, required this.descripcion});
}

const List<_CategoriaPqrs> _categorias = [
  _CategoriaPqrs(
    tipo: TipoPqrs.peticion,
    titulo: 'Peticiones',
    descripcion: 'Solicita información o haz consultas generales sobre el uso de la plataforma.',
  ),
  _CategoriaPqrs(
    tipo: TipoPqrs.queja,
    titulo: 'Quejas',
    descripcion: 'Cuéntanos una situación puntual con la que no estuviste conforme.',
  ),
  _CategoriaPqrs(
    tipo: TipoPqrs.reclamo,
    titulo: 'Reclamos',
    descripcion: 'Manifiesta una inconformidad relacionada con los servicios de ManoLegal.',
  ),
  _CategoriaPqrs(
    tipo: TipoPqrs.solicitud,
    titulo: 'Solicitudes',
    descripcion: 'Pide una acción concreta relacionada con tu cuenta.',
  ),
];

/// Sección PQRS (Peticiones, Quejas, Reclamos, Solicitudes), compartida por
/// el panel del cliente y el del abogado: presenta las 4 categorías, permite
/// radicar una PQRS y muestra su confirmación con el radicado oficial.
class SeccionPqrs extends StatefulWidget {
  const SeccionPqrs({super.key, this.crearControlador, this.alRequerirCuenta});

  /// Permite a las pruebas inyectar un controlador con servicios falsos.
  @visibleForTesting
  final ControladorPqrs Function()? crearControlador;

  /// Modo visitante (web, sin sesión). Si no es `null`, las categorías y
  /// «Radicar una PQRS» llaman a esto (para pedir una cuenta) en lugar de
  /// abrir el formulario: una PQRS necesita una cuenta a la que llegue el
  /// radicado.
  final VoidCallback? alRequerirCuenta;

  @override
  State<SeccionPqrs> createState() => _SeccionPqrsState();
}

class _SeccionPqrsState extends State<SeccionPqrs> {
  late final ControladorPqrs _controlador = (widget.crearControlador ?? ControladorPqrs.new)();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PQRS', style: EstilosPqrs.titulo()),
                const SizedBox(height: 4),
                const Text(
                  'Peticiones, quejas, reclamos y solicitudes relacionadas con ManoLegal.',
                  style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _contenido(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    final controlador = _controlador;
    switch (controlador.etapa) {
      case EtapaPqrs.inicio:
        final alRequerirCuenta = widget.alRequerirCuenta;
        return _InicioPqrs(
          onRadicar: ([tipo]) => alRequerirCuenta != null ? alRequerirCuenta() : controlador.iniciarNueva(tipo),
        );
      case EtapaPqrs.formulario:
        return _Angosto(
          child: FormularioPqrs(
            tipoInicial: controlador.tipoInicial,
            enviando: controlador.enviando,
            mensajeError: controlador.mensajeError,
            onEnviar: (tipo, descripcion, evidencias) =>
                controlador.enviar(tipo: tipo, descripcion: descripcion, evidencias: evidencias),
            onCancelar: controlador.volverAlInicio,
          ),
        );
      case EtapaPqrs.esperandoRadicado:
        return _Angosto(
          child: EsperaRadicadoPqrs(
            esperaProlongada: controlador.esperaProlongada,
            errorEspera: controlador.errorEspera,
          ),
        );
      case EtapaPqrs.confirmada:
        return _Angosto(
          child: ConfirmacionPqrs(
            pqrs: controlador.pqrs!,
            correo: controlador.correoUsuario,
            onRadicarOtra: () => controlador.iniciarNueva(),
            onVolver: controlador.volverAlInicio,
          ),
        );
    }
  }
}

/// Ancho de lectura cómodo para el formulario y la confirmación en
/// pantallas grandes.
class _Angosto extends StatelessWidget {
  final Widget child;

  const _Angosto({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child),
    );
  }
}

class _InicioPqrs extends StatelessWidget {
  final void Function([TipoPqrs? tipo]) onRadicar;

  const _InicioPqrs({required this.onRadicar});

  @override
  Widget build(BuildContext context) {
    // Categorías, botón y nota llevan marcas para el recorrido guiado de
    // PQRS; sin ámbito de recorrido no agregan nada.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarcaRecorrido(
          id: MarcaRecorridoId.pqrsCategorias,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final categoria in _categorias)
                SizedBox(
                  width: 270,
                  child: _TarjetaCategoria(categoria: categoria, onTap: () => onRadicar(categoria.tipo)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        MarcaRecorrido(
          id: MarcaRecorridoId.pqrsRadicar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: BotonPersonalizado(texto: 'Radicar una PQRS', onPressed: () => onRadicar()),
          ),
        ),
        const SizedBox(height: 20),
        MarcaRecorrido(
          id: MarcaRecorridoId.pqrsNotaRadicado,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColoresApp.dorado.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColoresApp.dorado.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: ColoresApp.azulTurqui),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recibirás tu número de radicado en pantalla y en tu correo.',
                    style: TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13),
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

/// Tarjeta de categoría: la misma de antes, ahora tocable para radicar una
/// PQRS de ese tipo.
class _TarjetaCategoria extends StatelessWidget {
  final _CategoriaPqrs categoria;
  final VoidCallback onTap;

  const _TarjetaCategoria({required this.categoria, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: TarjetaCristal(
          color: ColoresApp.blanco,
          colorBorde: ColoresApp.grisTexto.withValues(alpha: 0.15),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconoTipoPqrs(categoria.tipo), color: ColoresApp.azulTurqui, size: 28),
              const SizedBox(height: 12),
              Text(
                categoria.titulo,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ColoresApp.azulTurquiOscuro),
              ),
              const SizedBox(height: 6),
              Text(
                categoria.descripcion,
                style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Radicar →',
                style: TextStyle(color: ColoresApp.azulTurqui, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
