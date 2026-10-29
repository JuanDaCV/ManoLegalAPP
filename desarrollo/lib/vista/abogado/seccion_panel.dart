import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_perfil_abogado.dart';
import '../../modelo/modelo_paso_recorrido.dart';
import '../compartido/widgets/recorrido/ambito_recorrido.dart';
import '../tema/tema_app.dart';
import 'datos_mock_perfil_abogado.dart';
import 'estado_error_perfil.dart';

/// Sección "Panel" del abogado: 6 tarjetas con el desempeño de su perfil.
///
/// Las 3 primeras son datos REALES: el estado de verificación que administra
/// el administrador, la reputación que mantiene la Cloud Function, y la
/// completitud calculada sobre el perfil guardado. Las 3 últimas siguen
/// siendo de demostración y están marcadas como tales, porque dependen de
/// módulos (visitas, solicitudes y contactos) que todavía no existen.
class SeccionPanel extends StatelessWidget {
  final bool esEscritorio;

  const SeccionPanel({super.key, required this.esEscritorio});

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorPerfilAbogado>();
    final perfil = controlador.perfil;

    if (controlador.estado == EstadoPerfilAbogado.cargando || perfil == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
    }
    if (controlador.estado == EstadoPerfilAbogado.error) {
      return EstadoErrorPerfil(controlador: controlador);
    }

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 24, color: ColoresApp.azulTurquiOscuro),
        ),
        const SizedBox(height: 4),
        const Text(
          'Un vistazo rápido al desempeño de tu perfil dentro de ManoLegal.',
          style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _GrillaTarjetas(
          columnas: esEscritorio ? 3 : 2,
          tarjetas: [
            _TarjetaPanel(
              icono: Icons.verified_outlined,
              titulo: 'Estado del perfil',
              // Marca de arranque del recorrido: solo existe con el perfil
              // ya cargado.
              marca: MarcaRecorridoId.panelEstado,
              child: Text(
                perfil.verificado ? 'Verificado' : 'Pendiente',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: perfil.verificado ? ColoresApp.verdeVerificado : ColoresApp.rojoNoVerificado,
                ),
              ),
            ),
            _TarjetaPanel(
              icono: Icons.star_outline,
              titulo: 'Reputación',
              marca: MarcaRecorridoId.panelReputacion,
              // Valor y cantidad en dos líneas: en una sola fila no entran en
              // una tarjeta angosta de móvil.
              // Sin reseñas no se muestra un 0.0: sería indistinguible de una
              // mala calificación cuando en realidad todavía no hay ninguna.
              child: perfil.tieneResenas
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: ColoresApp.dorado, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              perfil.calificacion.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: ColoresApp.azulTurquiOscuro,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perfil.cantidadResenas == 1 ? '1 reseña' : '${perfil.cantidadResenas} reseñas',
                          style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12),
                        ),
                      ],
                    )
                  : const Text(
                      'Sin reseñas',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ColoresApp.grisTexto),
                    ),
            ),
            _TarjetaPanel(
              icono: Icons.donut_large_outlined,
              titulo: 'Completitud del perfil',
              marca: MarcaRecorridoId.panelCompletitud,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(perfil.porcentajeCompletitud * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ColoresApp.azulTurquiOscuro),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: perfil.porcentajeCompletitud,
                      minHeight: 8,
                      backgroundColor: ColoresApp.grisClaro,
                      color: ColoresApp.azulTurqui,
                    ),
                  ),
                ],
              ),
            ),
            _TarjetaPanel(
              icono: Icons.visibility_outlined,
              titulo: 'Visualizaciones del perfil',
              esDemostracion: true,
              // El recorrido señala solo la primera tarjeta de demostración y
              // explica que ninguna muestra cifras reales.
              marca: MarcaRecorridoId.panelDemostracion,
              child: Text(
                '${metricasMockPanelAbogado.visualizaciones}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ColoresApp.azulTurquiOscuro),
              ),
            ),
            _TarjetaPanel(
              icono: Icons.assignment_outlined,
              titulo: 'Solicitudes recibidas',
              esDemostracion: true,
              child: Text(
                '${metricasMockPanelAbogado.solicitudesRecibidas}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ColoresApp.azulTurquiOscuro),
              ),
            ),
            _TarjetaPanel(
              icono: Icons.contact_phone_outlined,
              titulo: 'Contactos',
              esDemostracion: true,
              child: Text(
                '${metricasMockPanelAbogado.contactos}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ColoresApp.azulTurquiOscuro),
              ),
            ),
          ],
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: esEscritorio ? 32 : 16, vertical: 24),
      child: esEscritorio
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: contenido))
          : contenido,
    );
  }
}

/// Grilla cuya altura se ajusta al contenido: cada fila toma la altura de su
/// tarjeta más alta. Reemplaza a un `GridView` con proporción fija, que en
/// pantallas angostas (o con el texto agrandado por accesibilidad) cortaba
/// el contenido de las tarjetas.
class _GrillaTarjetas extends StatelessWidget {
  final int columnas;
  final List<Widget> tarjetas;

  const _GrillaTarjetas({required this.columnas, required this.tarjetas});

  @override
  Widget build(BuildContext context) {
    const espacio = 16.0;
    final filas = <Widget>[];

    for (var inicio = 0; inicio < tarjetas.length; inicio += columnas) {
      final celdas = <Widget>[];
      for (var indice = inicio; indice < inicio + columnas; indice++) {
        if (indice > inicio) celdas.add(const SizedBox(width: espacio));
        // Si la última fila queda incompleta, un hueco vacío conserva el ancho.
        celdas.add(Expanded(child: indice < tarjetas.length ? tarjetas[indice] : const SizedBox.shrink()));
      }
      if (filas.isNotEmpty) filas.add(const SizedBox(height: espacio));
      filas.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: celdas),
      ));
    }

    return Column(children: filas);
  }
}

class _TarjetaPanel extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Widget child;
  final bool esDemostracion;

  /// Marca con la que el recorrido guiado del Panel señala esta tarjeta, si
  /// la señala. Sin ámbito de recorrido no agrega nada.
  final MarcaRecorridoId? marca;

  const _TarjetaPanel({
    required this.icono,
    required this.titulo,
    required this.child,
    this.esDemostracion = false,
    this.marca,
  });

  @override
  Widget build(BuildContext context) {
    final id = marca;
    final tarjeta = _construirTarjeta();
    return id == null ? tarjeta : MarcaRecorrido(id: id, child: tarjeta);
  }

  Widget _construirTarjeta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      // Ícono arriba del título (no al lado): así el título dispone de todo el
      // ancho de la tarjeta y no se corta a mitad de palabra en móvil.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColoresApp.azulTurqui,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ColoresApp.dorado, width: 1.2),
            ),
            child: Icon(icono, color: ColoresApp.blanco, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ColoresApp.grisTexto),
          ),
          const SizedBox(height: 8),
          child,
          // Empuja la leyenda al fondo cuando la fila es más alta que esta tarjeta.
          const Spacer(),
          if (esDemostracion) ...[
            const SizedBox(height: 10),
            const Text(
              'Dato de demostración',
              style: TextStyle(color: ColoresApp.grisTexto, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
