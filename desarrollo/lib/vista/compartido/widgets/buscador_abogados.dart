import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controlador/controlador_busqueda_abogados.dart';
import '../../../controlador/servicio_perfil_publico.dart';
import '../../../modelo/modelo_paso_recorrido.dart';
import '../../../modelo/modelo_resultado_abogado.dart';
import '../../tema/tema_app.dart';
import '../../widgets_comunes/campo_texto_personalizado.dart';
import '../pantalla_perfil_abogado.dart';
import 'panel_filtros.dart';
import 'recorrido/ambito_recorrido.dart';
import 'tarjeta_abogado.dart';

/// Buscador de abogados: título, barra de búsqueda, filtros y resultados.
///
/// Los resultados vienen de la colección real `perfilesPublicosAbogados`. Si
/// no hay abogados publicados, el buscador muestra un estado vacío: nunca
/// rellena la lista con datos de ejemplo.
///
/// El controlador se mantiene como campo del estado en lugar de exponerse por
/// Provider, porque nadie fuera de este widget lo necesita y así el bottom
/// sheet de filtros lo alcanza por cierre léxico, sin plomería extra.
///
/// Sus partes principales llevan un [MarcaRecorrido] para que el recorrido
/// guiado de Inicio (del cliente y del abogado) pueda señalarlas. Sin un
/// recorrido encima las marcas no hacen nada.
class BuscadorAbogados extends StatefulWidget {
  final bool esEscritorio;

  /// Las pruebas de widget lo desactivan: `google_fonts` intenta descargar la
  /// fuente y en las pruebas no hay red. En la aplicación siempre es Plus
  /// Jakarta Sans.
  @visibleForTesting
  static bool usarTipografiaDeMarca = true;

  /// Permite a las pruebas inyectar un controlador con un servicio falso.
  @visibleForTesting
  final ControladorBusquedaAbogados Function()? crearControlador;

  /// Servicio con el que se busca. Si es `null`, el del controlador por
  /// defecto (`perfilesPublicosAbogados`). El visitante web pasa uno que lee
  /// la proyección pública `tarjetasAbogados`, porque sin sesión no puede
  /// leer los perfiles completos.
  final ServicioPerfilPublico? servicioPerfilPublico;

  /// Qué hacer con «Ver perfil». Si es `null`, abre [PantallaPerfilAbogado];
  /// el visitante web lo usa para pedir una cuenta antes de mostrarlo.
  final void Function(ModeloResultadoAbogado abogado)? alVerPerfil;

  const BuscadorAbogados({
    super.key,
    required this.esEscritorio,
    this.crearControlador,
    this.servicioPerfilPublico,
    this.alVerPerfil,
  });

  @override
  State<BuscadorAbogados> createState() => _BuscadorAbogadosState();
}

class _BuscadorAbogadosState extends State<BuscadorAbogados> {
  final _controladorBusqueda = TextEditingController();
  late final ControladorBusquedaAbogados _controlador = (widget.crearControlador ??
      () => ControladorBusquedaAbogados(servicioPerfilPublico: widget.servicioPerfilPublico))();

  @override
  void initState() {
    super.initState();
    _controlador.buscar();
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    _controlador.dispose();
    super.dispose();
  }

  void _ejecutarBusqueda() {
    _controlador.fijarTexto(_controladorBusqueda.text);
    _controlador.buscar();
  }

  void _abrirFiltrosMovil() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (contextSheet) {
        return ListenableBuilder(
          listenable: _controlador,
          builder: (contextSheet, _) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(contextSheet).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: ColoresApp.grisTexto.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      _construirPanelFiltros(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static TextStyle _estiloTitulo() {
    const base = TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: ColoresApp.azulTurquiOscuro);
    return BuscadorAbogados.usarTipografiaDeMarca ? GoogleFonts.plusJakartaSans(textStyle: base) : base;
  }

  /// Solo la primera tarjeta lleva marcas: el recorrido guiado explica una
  /// tarjeta, no todas.
  Widget _construirTarjeta(ModeloResultadoAbogado abogado, {required bool esPrimera}) {
    final tarjeta = TarjetaAbogado(
      abogado: abogado,
      esEscritorio: widget.esEscritorio,
      marcarParaRecorrido: esPrimera,
      onVerPerfil: () {
        final alVerPerfil = widget.alVerPerfil;
        if (alVerPerfil != null) {
          alVerPerfil(abogado);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PantallaPerfilAbogado(uid: abogado.uid)),
        );
      },
    );
    return esPrimera ? MarcaRecorrido(id: MarcaRecorridoId.tarjeta, child: tarjeta) : tarjeta;
  }

  PanelFiltros _construirPanelFiltros() {
    return PanelFiltros(
      especialidadesSeleccionadas: _controlador.especialidades,
      onEspecialidadesSeleccionadasChanged: _controlador.fijarEspecialidades,
      ubicacionesSeleccionadas: _controlador.ubicaciones,
      onUbicacionesSeleccionadasChanged: _controlador.fijarUbicaciones,
      calificacionMinima: _controlador.calificacionMinima,
      onCalificacionMinimaChanged: _controlador.fijarCalificacionMinima,
      soloVerificados: _controlador.soloVerificados,
      onSoloVerificadosChanged: _controlador.fijarSoloVerificados,
      onLimpiarFiltros: _controlador.limpiarFiltros,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, _) {
        final encabezado = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buscar abogados',
              style: _estiloTitulo(),
            ),
            const SizedBox(height: 4),
            const Text(
              'Filtra por especialidad, ubicación y calificación para encontrar al abogado que necesitas.',
              style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
            ),
            const SizedBox(height: 16),
            MarcaRecorrido(
              id: MarcaRecorridoId.buscador,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CampoTextoPersonalizado(
                      etiqueta: 'Búsqueda',
                      controlador: _controladorBusqueda,
                      pista: 'Busca por nombre, especialidad o ubicación...',
                      onEnviado: (_) => _ejecutarBusqueda(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _ejecutarBusqueda,
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('Buscar'),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.esEscritorio) ...[
              const SizedBox(height: 12),
              MarcaRecorrido(
                id: MarcaRecorridoId.filtros,
                child: OutlinedButton.icon(
                  onPressed: _abrirFiltrosMovil,
                  icon: const Icon(Icons.tune),
                  label: const Text('Filtros'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_controlador.estado == EstadoBusqueda.conResultados)
              Text(
                '${_controlador.resultados.length} resultados encontrados',
                style: const TextStyle(fontWeight: FontWeight.w600, color: ColoresApp.azulTurquiOscuro),
              ),
            const SizedBox(height: 12),
          ],
        );

        final cuerpo = _construirCuerpo();

        if (!widget.esEscritorio) {
          return Column(children: [encabezado, cuerpo]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarcaRecorrido(
              id: MarcaRecorridoId.filtros,
              child: SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ColoresApp.blanco,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ColoresApp.grisTexto.withValues(alpha: 0.15)),
                  ),
                  child: _construirPanelFiltros(),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: Column(children: [encabezado, cuerpo])),
          ],
        );
      },
    );
  }

  Widget _construirCuerpo() {
    switch (_controlador.estado) {
      case EstadoBusqueda.inicial:
      case EstadoBusqueda.cargando:
        // El recorrido guiado espera a que esta marca desaparezca antes de
        // decidir si hay tarjetas que señalar.
        return const MarcaRecorrido(
          id: MarcaRecorridoId.cargandoResultados,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        );

      case EstadoBusqueda.error:
        return _EstadoVacio(
          icono: Icons.cloud_off,
          titulo: 'No se pudo cargar la búsqueda',
          detalle: _controlador.mensajeError ?? '',
          onReintentar: _controlador.buscar,
        );

      case EstadoBusqueda.vacio:
        return const _EstadoVacio(
          icono: Icons.search_off,
          titulo: 'No hay abogados disponibles',
          detalle: 'Prueba quitando algunos filtros o desactivando "Solo abogados verificados".',
        );

      case EstadoBusqueda.conResultados:
        return Column(
          children: [
            for (final (indice, abogado) in _controlador.resultados.indexed) ...[
              _construirTarjeta(abogado, esPrimera: indice == 0),
              const SizedBox(height: 12),
            ],
          ],
        );
    }
  }
}

/// Estado sin resultados o con error, con el mismo aspecto en ambos casos.
class _EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback? onReintentar;

  const _EstadoVacio({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.grisTexto.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icono, size: 40, color: ColoresApp.grisTexto),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ColoresApp.azulTurquiOscuro),
          ),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
            ),
          ],
          if (onReintentar != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}
