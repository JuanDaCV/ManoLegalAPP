import 'package:flutter/material.dart';

import '../../../../modelo/modelo_capitulo_como_funciona.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/fondo_juridico.dart';
import '../../../widgets_comunes/tarjeta_cristal.dart';
import 'contorno_de_foco.dart';
import 'estilos_como_funciona.dart';
import 'medidas_como_funciona.dart';

/// Lo que el usuario aprende en cada capítulo, dicho en pocas palabras, para
/// la tarjeta "Qué vas a aprender" del encabezado de escritorio.
const List<String> _resumenesDeCapitulos = [
  'Qué es ManoLegal y qué puedes hacer',
  'Encontrar abogados desde el Inicio',
  'Comparar perfiles y elegir con criterio',
  'Qué indica la insignia «Verificado»',
  'Contactar por WhatsApp o por correo',
  'Qué revisar antes de contactar y cómo usar PQRS',
];

/// Bloque de entrada de la guía: sobre fondo azul turquí, el título, una
/// frase que explica de qué trata y cuánto dura. En pantalla ancha suma el
/// botón para empezar y la lista de lo que se aprende, con cada línea
/// enlazada a su capítulo.
class EncabezadoComoFunciona extends StatelessWidget {
  final MedidasComoFunciona medidas;

  /// Se llama con el índice (desde 0) del capítulo elegido.
  final ValueChanged<int> alIrACapitulo;

  const EncabezadoComoFunciona({super.key, required this.medidas, required this.alIrACapitulo});

  @override
  Widget build(BuildContext context) {
    final ancho = medidas.modo == ModoComoFunciona.ancho;
    final relleno = switch (medidas.modo) {
      ModoComoFunciona.ancho => const EdgeInsets.symmetric(horizontal: 48, vertical: 44),
      ModoComoFunciona.medio => const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      ModoComoFunciona.compacto => const EdgeInsets.all(20),
    };

    return _EntradaSuave(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ancho ? 28 : 24),
        child: Stack(
          children: [
            const Positioned.fill(child: FondoJuridico(intensidadIcono: 0.05)),
            Padding(
              padding: relleno,
              child: ancho
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _TextoEncabezado(medidas: medidas, alEmpezar: () => alIrACapitulo(0)),
                        ),
                        const SizedBox(width: 48),
                        SizedBox(width: 380, child: _TarjetaAprendizaje(alIrACapitulo: alIrACapitulo)),
                      ],
                    )
                  : _TextoEncabezado(medidas: medidas),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aparición suave la primera vez que se ve la sección (fundido y un pequeño
/// desplazamiento hacia arriba). Con el movimiento reducido en el sistema,
/// aparece de golpe.
class _EntradaSuave extends StatelessWidget {
  final Widget child;

  const _EntradaSuave({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: EstilosComoFunciona.duracion(context, const Duration(milliseconds: 450)),
      curve: Curves.easeOutCubic,
      builder: (context, valor, hijo) => Opacity(
        opacity: valor,
        child: Transform.translate(offset: Offset(0, 8 * (1 - valor)), child: hijo),
      ),
      child: child,
    );
  }
}

class _TextoEncabezado extends StatelessWidget {
  final MedidasComoFunciona medidas;

  /// Si se pasa, se muestra el botón "Empezar por el capítulo 1" (solo en
  /// pantalla ancha, donde hay espacio para él).
  final VoidCallback? alEmpezar;

  const _TextoEncabezado({required this.medidas, this.alEmpezar});

  @override
  Widget build(BuildContext context) {
    final minutos = (duracionTotalComoFunciona.inSeconds / 60).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(color: ColoresApp.dorado, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),
        Text('GUÍA EN VIDEO', style: EstilosComoFunciona.etiquetaSuperior(color: ColoresApp.dorado)),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            'Cómo funciona ManoLegal',
            style: EstilosComoFunciona.titulo(
              tamanio: medidas.tamTituloEncabezado,
              color: ColoresApp.blanco,
              altura: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: medidas.anchoMaxLead),
          child: Text(
            'Seis videos breves para conocer la plataforma: qué es, cómo encontrar y elegir un abogado, '
            'qué significa la verificación, cómo contactarlo y qué tener en cuenta como cliente.',
            style: TextStyle(
              color: ColoresApp.blanco.withValues(alpha: 0.85),
              fontSize: medidas.tamLeadEncabezado,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${capitulosComoFunciona.length} videos · unos $minutos minutos',
          style: TextStyle(
            color: ColoresApp.blanco.withValues(alpha: 0.7),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (alEmpezar != null) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: alEmpezar,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Empezar por el capítulo 1'),
            style: FilledButton.styleFrom(
              backgroundColor: ColoresApp.blanco,
              foregroundColor: ColoresApp.azulTurqui,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              // Parte del estilo del tema para conservar su tipografía: un
              // `TextStyle` suelto reemplazaría la del botón por la del sistema.
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta de vidrio con la lista de lo que se aprende; cada fila lleva al
/// capítulo correspondiente.
class _TarjetaAprendizaje extends StatelessWidget {
  final ValueChanged<int> alIrACapitulo;

  const _TarjetaAprendizaje({required this.alIrACapitulo});

  @override
  Widget build(BuildContext context) {
    return TarjetaCristal(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text('QUÉ VAS A APRENDER', style: EstilosComoFunciona.etiquetaSuperior(color: ColoresApp.dorado)),
          ),
          // Dentro del cristal, para que el efecto de toque se dibuje sobre él.
          Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (var i = 0; i < capitulosComoFunciona.length; i++)
                  _FilaAprendizaje(
                    capitulo: capitulosComoFunciona[i],
                    resumen: _resumenesDeCapitulos[i],
                    alTocar: () => alIrACapitulo(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaAprendizaje extends StatelessWidget {
  final ModeloCapituloComoFunciona capitulo;
  final String resumen;
  final VoidCallback alTocar;

  const _FilaAprendizaje({required this.capitulo, required this.resumen, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ir al capítulo ${capitulo.numero}: ${capitulo.titulo}',
      onTap: alTocar,
      excludeSemantics: true,
      child: ContornoDeFoco(
        radio: BorderRadius.circular(12),
        color: ColoresApp.blanco,
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(12),
          hoverColor: ColoresApp.blanco.withValues(alpha: 0.08),
          focusColor: ColoresApp.blanco.withValues(alpha: 0.14),
          splashColor: ColoresApp.blanco.withValues(alpha: 0.1),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      capitulo.numeroTexto,
                      style: const TextStyle(
                        color: ColoresApp.dorado,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: EstilosComoFunciona.cifrasTabulares,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      resumen,
                      style: const TextStyle(
                        color: ColoresApp.blanco,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    capitulo.duracionTexto,
                    style: TextStyle(
                      color: ColoresApp.blanco.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontFeatures: EstilosComoFunciona.cifrasTabulares,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
