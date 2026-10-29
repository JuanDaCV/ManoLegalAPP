import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_como_funciona.dart';

/// Disco de "reproducir" que va sobre la portada de un capítulo.
///
/// No es el botón en sí: todo el recuadro de la portada responde al toque.
/// Este disco solo muestra el estado: crece un poco al pasar el cursor, dibuja
/// un doble aro (blanco y azul) cuando la portada tiene el foco del teclado y
/// cambia la flecha por un indicador mientras el video carga.
class BotonReproducir extends StatelessWidget {
  final bool compacto;
  final bool cargando;

  /// El cursor está sobre la portada.
  final bool resaltado;

  /// La portada tiene el foco del teclado.
  final bool enfocado;

  const BotonReproducir({
    super.key,
    this.compacto = false,
    this.cargando = false,
    this.resaltado = false,
    this.enfocado = false,
  });

  @override
  Widget build(BuildContext context) {
    final diametro = compacto ? 56.0 : 64.0;
    final disco = Container(
      width: diametro,
      height: diametro,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColoresApp.azulTurqui.withValues(alpha: 0.94),
        border: Border.all(color: ColoresApp.dorado, width: 2),
        boxShadow: [BoxShadow(color: ColoresApp.blanco.withValues(alpha: 0.18), blurRadius: 24, spreadRadius: 2)],
      ),
      child: cargando
          ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: ColoresApp.blanco),
            )
          : const Icon(Icons.play_arrow_rounded, size: 34, color: ColoresApp.blanco),
    );

    // El aro del foco es de dos tonos para verse sobre cualquier portada,
    // clara u oscura: un anillo azul pegado al disco y otro blanco afuera.
    return AnimatedScale(
      scale: resaltado ? 1.06 : 1,
      duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 150)),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: enfocado ? ColoresApp.blanco : Colors.transparent, width: 3),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: enfocado ? ColoresApp.azulTurquiOscuro : Colors.transparent, width: 2),
          ),
          child: disco,
        ),
      ),
    );
  }
}

/// Etiqueta con la duración del video, en la esquina de la portada.
///
/// Es redundante para los lectores de pantalla: el botón de reproducir ya
/// anuncia la duración en su etiqueta.
class PildoraDuracion extends StatelessWidget {
  final String texto;

  const PildoraDuracion({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ColoresApp.azulTurquiOscuro.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: ColoresApp.blanco,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            fontFeatures: EstilosComoFunciona.cifrasTabulares,
          ),
        ),
      ),
    );
  }
}
