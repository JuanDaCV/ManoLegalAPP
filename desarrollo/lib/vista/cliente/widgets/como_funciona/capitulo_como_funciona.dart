import 'package:flutter/material.dart';

import '../../../../controlador/controlador_como_funciona.dart';
import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import 'escenario_video.dart';
import 'estilos_como_funciona.dart';
import 'medidas_como_funciona.dart';
import 'piezas_capitulo.dart';
import 'reproductor_capitulo.dart';

/// Un capítulo de la guía, con la presentación que corresponda al tamaño de
/// la pantalla:
/// - Teléfono y tableta angosta: una tarjeta blanca con el texto arriba y el
///   video pegado a sus bordes (el vertical, centrado con aire alrededor).
/// - Tableta ancha, capítulo vertical: la tarjeta con texto y video lado a
///   lado, porque un video 9:16 apilado ocuparía más que la pantalla.
/// - Escritorio: una escena sin tarjeta, con el título y el texto sobre el
///   video enmarcado en azul turquí.
///
/// Todos los recuadros de video llevan la clave `marco_video_N` y la
/// proporción exacta del video, de modo que el diseño no se mueve al cargar.
class CapituloComoFunciona extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;
  final MedidasComoFunciona medidas;
  final ControladorComoFunciona controlador;
  final FocusNode focoReproducir;

  /// Hacia qué lado se desplaza el contorno dorado del escenario (solo en
  /// pantalla ancha). Alterna entre capítulos.
  final bool contornoALaDerecha;

  const CapituloComoFunciona({
    super.key,
    required this.capitulo,
    required this.medidas,
    required this.controlador,
    required this.focoReproducir,
    required this.contornoALaDerecha,
  });

  @override
  Widget build(BuildContext context) {
    if (medidas.modo == ModoComoFunciona.ancho) {
      return capitulo.esVertical ? _escenaAnchaVertical() : _escenaAnchaHorizontal();
    }
    if (capitulo.esVertical && medidas.verticalAlLado) return _tarjetaConVideoAlLado();
    return _tarjeta();
  }

  Widget _marcoVideo() {
    return AspectRatio(
      key: ValueKey('marco_video_${capitulo.numero}'),
      aspectRatio: capitulo.proporcion,
      child: ReproductorCapitulo(capitulo: capitulo, controlador: controlador, focoReproducir: focoReproducir),
    );
  }

  Widget _escenario(double anchoVideo) {
    return EscenarioVideo(
      capitulo: capitulo,
      controlador: controlador,
      focoReproducir: focoReproducir,
      anchoVideo: anchoVideo,
      contornoALaDerecha: contornoALaDerecha,
    );
  }

  Widget _contenedorTarjeta({required Widget hijo}) {
    // `Container` y no `DecoratedBox`: el borde de la tarjeta debe empujar al
    // contenido hacia adentro, o el video pegado al borde lo taparía.
    return Container(clipBehavior: Clip.antiAlias, decoration: EstilosComoFunciona.tarjeta, child: hijo);
  }

  Widget _textoTarjeta() {
    // En teléfono los tres temas repiten la descripción y suman unos 70 px a
    // cada tarjeta: ahí mandan el título, la descripción y el video. En
    // tableta y escritorio sí se muestran.
    final conTemas = medidas.modo != ModoComoFunciona.compacto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InsigniaNumeroCapitulo(capitulo: capitulo),
            const SizedBox(width: 12),
            Expanded(child: EtiquetaCapitulo(capitulo: capitulo)),
          ],
        ),
        const SizedBox(height: 10),
        TituloCapitulo(texto: capitulo.titulo, tamanio: medidas.tamTituloCapitulo),
        const SizedBox(height: 8),
        // Sobre blanco puro el gris de texto sí cumple el contraste AA. En
        // tableta el largo de línea se limita: el texto queda alineado a la
        // izquierda, bajo el título, en vez de estirarse por toda la tarjeta.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: medidas.anchoMaxDescripcion),
          child: Text(
            capitulo.descripcion,
            style: TextStyle(color: ColoresApp.grisTexto, fontSize: medidas.tamDescripcion, height: 1.5),
          ),
        ),
        if (conTemas) ...[const SizedBox(height: 12), PildorasTemas(temas: capitulo.temas)],
      ],
    );
  }

  Widget _tarjeta() {
    final video = capitulo.esVertical
        ? Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: SizedBox(
                width: medidas.anchoVideoVertical,
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: _marcoVideo()),
              ),
            ),
          )
        : _marcoVideo();
    return _contenedorTarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), child: _textoTarjeta()),
          video,
        ],
      ),
    );
  }

  Widget _tarjetaConVideoAlLado() {
    return _contenedorTarjeta(
      hijo: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _textoTarjeta()),
            const SizedBox(width: 24),
            SizedBox(
              width: medidas.anchoVideoVertical,
              child: ClipRRect(borderRadius: BorderRadius.circular(14), child: _marcoVideo()),
            ),
          ],
        ),
      ),
    );
  }

  /// Descripción y temas de la escena ancha.
  Widget _textoEscena({required double anchoMaximo}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            capitulo.descripcion,
            style: TextStyle(
              color: EstilosComoFunciona.textoCuerpoSobrePagina,
              fontSize: medidas.tamDescripcion,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          TemasConPunto(temas: capitulo.temas),
        ],
      ),
    );
  }

  /// Etiqueta y título, con el numeral enorme detrás.
  Widget _encabezadoEscena({required Widget Function(Widget titulo) alrededor}) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaCapitulo(capitulo: capitulo),
        const SizedBox(height: 10),
        TituloCapitulo(texto: capitulo.titulo, tamanio: medidas.tamTituloCapitulo),
      ],
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -4,
          top: -52,
          child: NumeralFantasma(capitulo: capitulo, tamanio: medidas.tamNumeralFantasma),
        ),
        alrededor(titulo),
      ],
    );
  }

  Widget _escenaAnchaHorizontal() {
    return Padding(
      padding: const EdgeInsets.only(top: 56, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoEscena(
            alrededor: (titulo) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: titulo),
                const SizedBox(width: 40),
                Expanded(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _textoEscena(anchoMaximo: medidas.anchoMaxDescripcion),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _escenario(medidas.anchoVideoHorizontal),
        ],
      ),
    );
  }

  Widget _escenaAnchaVertical() {
    return Padding(
      padding: const EdgeInsets.only(top: 56, bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _encabezadoEscena(
              alrededor: (titulo) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [titulo, const SizedBox(height: 16), _textoEscena(anchoMaximo: 480)],
              ),
            ),
          ),
          const SizedBox(width: 48),
          _escenario(medidas.anchoVideoVertical),
        ],
      ),
    );
  }
}
