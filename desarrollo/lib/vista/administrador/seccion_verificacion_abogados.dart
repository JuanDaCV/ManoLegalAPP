import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_administrador.dart';
import '../../controlador/filtros_administrador.dart';
import '../../modelo/modelo_abogado.dart';
import '../tema/tema_app.dart';
import 'estilos_administrador.dart';
import 'widgets/tabla_abogados.dart';
import 'widgets/tarjeta_abogado_admin.dart';

/// Listado completo de abogados para su verificación: búsqueda, filtros,
/// tabla en escritorio, tarjetas en pantallas chicas, y paginación.
///
/// La búsqueda y los filtros se aplican en memoria sobre la lista en tiempo
/// real que ya mantiene [ControladorAdministrador]; no lanzan consultas
/// nuevas a Firestore. Ver `filtros_administrador.dart` para el porqué y
/// para el límite de escala de esta decisión.
class SeccionVerificacionAbogados extends StatefulWidget {
  final FiltroEstadoAbogado filtroInicial;

  /// Cambia cada vez que otra sección pide abrir el listado con un filtro
  /// concreto, por ejemplo "Revisar pendientes" desde el Inicio.
  final int versionFiltro;
  final ValueChanged<String> onAbrirDetalle;

  const SeccionVerificacionAbogados({
    super.key,
    required this.filtroInicial,
    required this.versionFiltro,
    required this.onAbrirDetalle,
  });

  @override
  State<SeccionVerificacionAbogados> createState() => _SeccionVerificacionAbogadosState();
}

class _SeccionVerificacionAbogadosState extends State<SeccionVerificacionAbogados> {
  static const int _porPagina = 10;

  final _busqueda = TextEditingController();
  late FiltroEstadoAbogado _estado = widget.filtroInicial;
  EspecialidadAbogado? _especialidad;
  int _pagina = 0;

  @override
  void didUpdateWidget(SeccionVerificacionAbogados anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.versionFiltro != widget.versionFiltro) {
      _estado = widget.filtroInicial;
      _pagina = 0;
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  bool get _hayFiltros => _busqueda.text.trim().isNotEmpty || _estado != FiltroEstadoAbogado.todos || _especialidad != null;

  void _limpiarFiltros() {
    setState(() {
      _busqueda.clear();
      _estado = FiltroEstadoAbogado.todos;
      _especialidad = null;
      _pagina = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAdministrador>();
    final resumen = calcularResumen(controlador.abogados);
    final filtrados = ordenarParaRevision(
      filtrarAbogados(controlador.abogados, texto: _busqueda.text, estado: _estado, especialidad: _especialidad),
    );
    final totalPaginas = math.max(1, (filtrados.length / _porPagina).ceil());
    // Si la lista se achica en tiempo real, la página actual se ajusta sola.
    final pagina = math.min(_pagina, totalPaginas - 1);
    final visibles = filtrados.skip(pagina * _porPagina).take(_porPagina).toList();

    return LayoutBuilder(
      builder: (context, restricciones) {
        final horizontal = restricciones.maxWidth >= 600 ? 32.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Verificación de abogados', style: EstilosAdmin.titulo(tamanio: 26)),
                  const SizedBox(height: 6),
                  const Text(
                    'Revisa la documentación, confírmala en las fuentes oficiales y administra el estado de '
                    'verificación de cada abogado.',
                    style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  _BarraFiltros(
                    busqueda: _busqueda,
                    estado: _estado,
                    especialidad: _especialidad,
                    resumen: resumen,
                    hayFiltros: _hayFiltros,
                    onBuscar: () => setState(() => _pagina = 0),
                    onEstado: (estado) => setState(() {
                      _estado = estado;
                      _pagina = 0;
                    }),
                    onEspecialidad: (especialidad) => setState(() {
                      _especialidad = especialidad;
                      _pagina = 0;
                    }),
                    onLimpiar: _limpiarFiltros,
                  ),
                  const SizedBox(height: 16),
                  _cuerpo(controlador, filtrados, visibles, pagina, totalPaginas),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cuerpo(
    ControladorAdministrador controlador,
    List<ModeloAbogado> filtrados,
    List<ModeloAbogado> visibles,
    int pagina,
    int totalPaginas,
  ) {
    final error = controlador.errorLista;
    if (error != null) {
      return _EstadoLista(
        icono: Icons.cloud_off_rounded,
        titulo: 'No se pudo cargar la lista de abogados',
        detalle: error,
        textoAccion: 'Reintentar',
        onAccion: controlador.reintentarEscucha,
      );
    }
    if (controlador.cargandoAbogados) {
      return const _EstadoLista(cargando: true, titulo: 'Cargando abogados…');
    }
    if (controlador.abogados.isEmpty) {
      return const _EstadoLista(
        icono: Icons.person_search_outlined,
        titulo: 'Todavía no hay abogados registrados',
        detalle: 'Cuando un abogado complete su registro, aparecerá aquí para su revisión.',
      );
    }
    if (filtrados.isEmpty) {
      return _EstadoLista(
        icono: Icons.search_off_rounded,
        titulo: 'Ningún abogado coincide con la búsqueda',
        detalle: 'Prueba con otro término o quita algunos filtros.',
        textoAccion: 'Limpiar filtros',
        onAccion: _limpiarFiltros,
      );
    }

    final desde = pagina * _porPagina + 1;
    final hasta = desde + visibles.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, restricciones) {
            final ancho = restricciones.maxWidth;
            if (ancho >= EstilosAdmin.anchoMinimoTabla) {
              return TablaAbogados(
                abogados: visibles,
                onVerDetalle: (abogado) => widget.onAbrirDetalle(abogado.uid),
              );
            }
            const separacion = 16.0;
            final columnas = ancho >= 600 ? 2 : 1;
            final anchoTarjeta = (ancho - separacion * (columnas - 1)) / columnas;
            return Wrap(
              spacing: separacion,
              runSpacing: separacion,
              children: [
                for (final abogado in visibles)
                  SizedBox(
                    width: anchoTarjeta,
                    child: TarjetaAbogadoAdmin(
                      abogado: abogado,
                      onVerDetalle: () => widget.onAbrirDetalle(abogado.uid),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            Text(
              'Mostrando $desde–$hasta de ${filtrados.length} '
              '${filtrados.length == 1 ? 'abogado' : 'abogados'}',
              style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
            ),
            if (totalPaginas > 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: pagina > 0 ? () => setState(() => _pagina = pagina - 1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    'Página ${pagina + 1} de $totalPaginas',
                    style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: pagina < totalPaginas - 1 ? () => setState(() => _pagina = pagina + 1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  final TextEditingController busqueda;
  final FiltroEstadoAbogado estado;
  final EspecialidadAbogado? especialidad;
  final ResumenVerificacion resumen;
  final bool hayFiltros;
  final VoidCallback onBuscar;
  final ValueChanged<FiltroEstadoAbogado> onEstado;
  final ValueChanged<EspecialidadAbogado?> onEspecialidad;
  final VoidCallback onLimpiar;

  const _BarraFiltros({
    required this.busqueda,
    required this.estado,
    required this.especialidad,
    required this.resumen,
    required this.hayFiltros,
    required this.onBuscar,
    required this.onEstado,
    required this.onEspecialidad,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde(Color color, double ancho) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: ancho),
        );

    // Pendientes antes que verificados: son los que requieren acción.
    final opcionesEstado = [
      (FiltroEstadoAbogado.todos, 'Todos', resumen.total),
      (FiltroEstadoAbogado.pendientes, 'Pendientes', resumen.pendientes),
      (FiltroEstadoAbogado.verificados, 'Verificados', resumen.verificados),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EstilosAdmin.tarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: busqueda,
            onChanged: (_) => onBuscar(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, apellido, correo, UID o especialidad',
              hintStyle: const TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: ColoresApp.grisTexto),
              suffixIcon: busqueda.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        busqueda.clear();
                        onBuscar();
                      },
                    ),
              filled: true,
              fillColor: ColoresApp.grisClaro,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: borde(Colors.transparent, 1),
              enabledBorder: borde(Colors.transparent, 1),
              focusedBorder: borde(ColoresApp.azulTurqui, 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (valor, etiqueta, cantidad) in opcionesEstado)
                ChoiceChip(
                  label: Text('$etiqueta ($cantidad)'),
                  selected: estado == valor,
                  onSelected: (_) => onEstado(valor),
                  showCheckmark: false,
                  selectedColor: ColoresApp.azulTurqui,
                  backgroundColor: ColoresApp.blanco,
                  side: BorderSide(color: estado == valor ? ColoresApp.azulTurqui : EstilosAdmin.bordeSuave),
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(
                    color: estado == valor ? ColoresApp.blanco : ColoresApp.azulTurquiOscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              // Ancho acotado y `isExpanded`: en un móvil angosto el texto de la
              // opción se recorta en lugar de desbordar el selector.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: ColoresApp.blanco,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: especialidad == null ? EstilosAdmin.bordeSuave : ColoresApp.azulTurqui),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EspecialidadAbogado?>(
                      value: especialidad,
                      isDense: true,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.expand_more_rounded, color: ColoresApp.grisTexto),
                      style: const TextStyle(
                        color: ColoresApp.azulTurquiOscuro,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: onEspecialidad,
                      items: [
                        const DropdownMenuItem<EspecialidadAbogado?>(
                          value: null,
                          child: Text('Todas las especialidades', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        for (final valor in EspecialidadAbogado.values)
                          DropdownMenuItem<EspecialidadAbogado?>(
                            value: valor,
                            child: Text(valor.textoLegible, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hayFiltros)
                TextButton.icon(
                  onPressed: onLimpiar,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpiar filtros'),
                  style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoLista extends StatelessWidget {
  final IconData? icono;
  final bool cargando;
  final String titulo;
  final String? detalle;
  final String? textoAccion;
  final VoidCallback? onAccion;

  const _EstadoLista({
    this.icono,
    this.cargando = false,
    required this.titulo,
    this.detalle,
    this.textoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: EstilosAdmin.tarjeta,
      child: Column(
        children: [
          if (cargando)
            const CircularProgressIndicator()
          else if (icono != null)
            Icon(icono, size: 42, color: ColoresApp.grisTexto),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 6),
            Text(
              detalle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13.5, height: 1.4),
            ),
          ],
          if (textoAccion != null && onAccion != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAccion,
              style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
              child: Text(textoAccion!),
            ),
          ],
        ],
      ),
    );
  }
}
