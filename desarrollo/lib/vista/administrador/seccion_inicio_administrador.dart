import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_administrador.dart';
import '../../controlador/filtros_administrador.dart';
import '../../modelo/modelo_abogado.dart';
import '../../modelo/modelo_perfil_abogado.dart';
import '../tema/tema_app.dart';
import 'estilos_administrador.dart';
import 'widgets/grafico_dona_verificacion.dart';
import 'widgets/tarjeta_metrica.dart';

/// Inicio del administrador: métricas, gráfico de verificación y la cola de
/// abogados pendientes.
///
/// Todo sale del stream en tiempo real de [ControladorAdministrador]: las
/// cifras cambian solas cuando cambia Firestore. No hay porcentajes ni
/// variaciones inventadas: solo lo que se puede calcular con los datos.
class SeccionInicioAdministrador extends StatelessWidget {
  final VoidCallback onRevisarPendientes;
  final ValueChanged<String> onAbrirDetalle;

  const SeccionInicioAdministrador({super.key, required this.onRevisarPendientes, required this.onAbrirDetalle});

  /// Cantidad de pendientes que muestra la cola del Inicio. El resto se ve
  /// en el listado completo.
  static const int _limiteCola = 5;

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAdministrador>();
    final error = controlador.errorLista;
    final datosListos = !controlador.cargandoAbogados && error == null;
    final resumen = calcularResumen(controlador.abogados);
    final pendientes = ordenarParaRevision(controlador.abogados.where((a) => !estaVerificado(a)).toList());

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final horizontal = ancho >= 600 ? 32.0 : 16.0;
        final enFila = ancho >= 1100;
        final anchoTarjeta = enFila ? (ancho - 2 * horizontal - 20) / 2 : ancho - 2 * horizontal;

        final tarjetaDona = _TarjetaDona(
          resumen: resumen,
          cargando: controlador.cargandoAbogados,
          conError: error != null,
          leyendaAbajo: anchoTarjeta - 40 < 460,
        );
        final tarjetaPendientes = _TarjetaPendientes(
          pendientes: pendientes,
          limite: _limiteCola,
          cargando: controlador.cargandoAbogados,
          conError: error != null,
          onVerTodos: onRevisarPendientes,
          onRevisar: onAbrirDetalle,
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Franja(
                horizontal: horizontal,
                metricasApiladas: ancho < 760,
                resumen: datosListos ? resumen : null,
                onRevisarPendientes: onRevisarPendientes,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      _AvisoError(mensaje: error, onReintentar: controlador.reintentarEscucha),
                      const SizedBox(height: 20),
                    ],
                    if (enFila)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: tarjetaDona),
                          const SizedBox(width: 20),
                          Expanded(child: tarjetaPendientes),
                        ],
                      )
                    else ...[
                      tarjetaDona,
                      const SizedBox(height: 20),
                      tarjetaPendientes,
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Franja superior en azul turquí con las tres métricas en vidrio.
class _Franja extends StatelessWidget {
  final double horizontal;
  final bool metricasApiladas;

  /// `null` mientras los datos cargan o si hubo un error.
  final ResumenVerificacion? resumen;
  final VoidCallback onRevisarPendientes;

  const _Franja({
    required this.horizontal,
    required this.metricasApiladas,
    required this.resumen,
    required this.onRevisarPendientes,
  });

  @override
  Widget build(BuildContext context) {
    final datos = resumen;
    final (porcentajeVerificados, _) = datos?.porcentajes ?? (0, 0);

    final metricas = [
      TarjetaMetrica(
        icono: Icons.groups_2_outlined,
        titulo: 'Total de abogados',
        valor: datos?.total,
        descripcion: 'Registrados en ManoLegal',
        colorAcento: ColoresApp.blanco,
      ),
      TarjetaMetrica(
        icono: Icons.verified_outlined,
        titulo: 'Abogados verificados',
        valor: datos?.verificados,
        descripcion: datos == null || datos.total == 0
            ? 'Aún no hay abogados registrados'
            : '$porcentajeVerificados% del total',
        colorAcento: EstilosAdmin.verdeSobreOscuro,
        progreso: datos == null || datos.total == 0 ? null : datos.proporcionVerificados,
      ),
      TarjetaMetrica(
        icono: Icons.pending_actions_outlined,
        titulo: 'Abogados no verificados',
        valor: datos?.pendientes,
        descripcion: 'Pendientes de revisión administrativa',
        colorAcento: ColoresApp.dorado,
        textoAccion: datos != null && datos.pendientes > 0 ? 'Revisar pendientes' : null,
        onAccion: onRevisarPendientes,
      ),
    ];

    final encabezado = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(color: ColoresApp.dorado, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 14),
        Text(
          'Panel de administración',
          style: EstilosAdmin.titulo(tamanio: metricasApiladas ? 24 : 28, color: ColoresApp.blanco),
        ),
        const SizedBox(height: 6),
        const Text(
          'Estado de la verificación de abogados en ManoLegal, al día con Firestore.',
          style: TextStyle(color: EstilosAdmin.textoSecundarioSobreOscuro, fontSize: 14, height: 1.4),
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(gradient: EstilosAdmin.degradadoMarca),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned(top: -90, right: -40, child: _Orbe(diametro: 260)),
          const Positioned(bottom: -130, left: 120, child: _Orbe(diametro: 240)),
          Positioned(
            right: 24,
            bottom: -34,
            child: Transform.rotate(
              angle: -0.35,
              child: Icon(Icons.gavel, size: 200, color: Colors.white.withValues(alpha: 0.04)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (metricasApiladas) ...[
                  encabezado,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerLeft, child: _PildoraEstado(conectado: datos != null)),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: encabezado),
                      const SizedBox(width: 16),
                      _PildoraEstado(conectado: datos != null),
                    ],
                  ),
                const SizedBox(height: 24),
                if (metricasApiladas)
                  for (var indice = 0; indice < metricas.length; indice++) ...[
                    if (indice > 0) const SizedBox(height: 12),
                    metricas[indice],
                  ]
                else
                  // IntrinsicHeight iguala la altura de las tres tarjetas. Es
                  // seguro aquí: ninguna tarjeta contiene un LayoutBuilder.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: metricas[0]),
                        const SizedBox(width: 16),
                        Expanded(child: metricas[1]),
                        const SizedBox(width: 16),
                        Expanded(child: metricas[2]),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PildoraEstado extends StatelessWidget {
  final bool conectado;

  const _PildoraEstado({required this.conectado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ColoresApp.superficieCristal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.bordeCristal),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: conectado ? EstilosAdmin.verdeSobreOscuro : ColoresApp.dorado,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              conectado ? 'Datos en tiempo real' : 'Conectando con Firestore…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: EstilosAdmin.textoSobreOscuro, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orbe extends StatelessWidget {
  final double diametro;

  const _Orbe({required this.diametro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [ColoresApp.azulBrillante.withValues(alpha: 0.22), Colors.transparent]),
      ),
    );
  }
}

class _TarjetaDona extends StatelessWidget {
  final ResumenVerificacion resumen;
  final bool cargando;
  final bool conError;
  final bool leyendaAbajo;

  const _TarjetaDona({
    required this.resumen,
    required this.cargando,
    required this.conError,
    required this.leyendaAbajo,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    if (cargando) {
      contenido = const SizedBox(height: 188, child: Center(child: CircularProgressIndicator()));
    } else if (conError) {
      contenido = const SizedBox(
        height: 120,
        child: Center(
          child: Text('Sin datos disponibles por el error de carga.', style: TextStyle(color: ColoresApp.grisTexto)),
        ),
      );
    } else {
      contenido = GraficoDonaVerificacion(resumen: resumen, leyendaAbajo: leyendaAbajo);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EstilosAdmin.tarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Estado de verificación', style: EstilosAdmin.titulo(tamanio: 18)),
          const SizedBox(height: 4),
          const Text(
            'Proporción de abogados verificados y pendientes',
            style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
          ),
          const SizedBox(height: 22),
          contenido,
        ],
      ),
    );
  }
}

class _TarjetaPendientes extends StatelessWidget {
  final List<ModeloAbogado> pendientes;
  final int limite;
  final bool cargando;
  final bool conError;
  final VoidCallback onVerTodos;
  final ValueChanged<String> onRevisar;

  const _TarjetaPendientes({
    required this.pendientes,
    required this.limite,
    required this.cargando,
    required this.conError,
    required this.onVerTodos,
    required this.onRevisar,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    if (cargando) {
      contenido = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (conError) {
      contenido = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Sin datos disponibles por el error de carga.', style: TextStyle(color: ColoresApp.grisTexto)),
      );
    } else if (pendientes.isEmpty) {
      contenido = const _SinPendientes();
    } else {
      final visibles = pendientes.take(limite).toList();
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var indice = 0; indice < visibles.length; indice++) ...[
            if (indice > 0) const Divider(height: 1, color: EstilosAdmin.bordeSuave),
            _FilaPendiente(abogado: visibles[indice], onRevisar: () => onRevisar(visibles[indice].uid)),
          ],
          if (pendientes.length > limite)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                pendientes.length - limite == 1
                    ? 'Y 1 abogado pendiente más.'
                    : 'Y ${pendientes.length - limite} abogados pendientes más.',
                style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EstilosAdmin.tarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pendientes de verificación', style: EstilosAdmin.titulo(tamanio: 18)),
                    const SizedBox(height: 4),
                    const Text(
                      'Abogados que esperan la revisión de sus documentos',
                      style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!cargando && pendientes.isNotEmpty)
                TextButton(
                  onPressed: onVerTodos,
                  style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
                  child: const Text('Ver todos'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          contenido,
        ],
      ),
    );
  }
}

class _FilaPendiente extends StatelessWidget {
  final ModeloAbogado abogado;
  final VoidCallback onRevisar;

  const _FilaPendiente({required this.abogado, required this.onRevisar});

  @override
  Widget build(BuildContext context) {
    final documentacion = estadoDocumentacion(abogado);
    final iniciales = ModeloPerfilAbogado.desdeAbogadoPrivado(abogado).iniciales;

    return InkWell(
      onTap: onRevisar,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: ColoresApp.azulTurqui.withValues(alpha: 0.08),
              child: Text(
                iniciales,
                style: const TextStyle(color: ColoresApp.azulTurqui, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${abogado.nombre} ${abogado.apellido}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${abogado.especialidad.textoLegible} · Documentos '
                    '${documentacion.obligatoriosCargados}/${EstadoDocumentacion.obligatoriosTotal}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onRevisar,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                side: BorderSide(color: ColoresApp.azulTurqui.withValues(alpha: 0.4)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('Revisar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinPendientes extends StatelessWidget {
  const _SinPendientes();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: ColoresApp.verdeVerificado, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No hay abogados pendientes',
                  style: TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'Todas las solicitudes de verificación están al día.',
                  style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _AvisoError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EstilosAdmin.tarjeta.copyWith(
        border: Border.all(color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: ColoresApp.rojoNoVerificado),
          Text(mensaje, style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13.5)),
          TextButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
          ),
        ],
      ),
    );
  }
}
