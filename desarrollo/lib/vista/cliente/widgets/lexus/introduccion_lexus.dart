import 'package:flutter/material.dart';

import '../../../../configuracion/respuestas_locales_lexus.dart';
import '../../../../controlador/controlador_lexus.dart';
import '../../../../modelo/modelo_paso_recorrido.dart';
import '../../../compartido/widgets/recorrido/ambito_recorrido.dart';
import '../../../tema/tema_app.dart';
import 'estilos_lexus.dart';
import 'mascota_lexus.dart';

const List<String> _sugerencias = [
  'Tengo un problema con mi empleador',
  'Quiero entender un tema de familia',
  '¿Cómo contacto a un abogado en ManoLegal?',
];

/// Estado vacío del chat: saludo de Lexus y tres frases para empezar. No
/// bloquea nada: la persona puede escribir de inmediato, y las frases solo
/// llenan el campo sin enviarlo.
class IntroduccionLexus extends StatefulWidget {
  const IntroduccionLexus({
    super.key,
    required this.controlador,
    required this.alElegirSugerencia,
    this.compacto = true,
  });

  final ControladorLexus controlador;
  final ValueChanged<String> alElegirSugerencia;
  final bool compacto;

  @override
  State<IntroduccionLexus> createState() => _IntroduccionLexusState();
}

class _IntroduccionLexusState extends State<IntroduccionLexus> {
  /// Se decide al montarse: marcarla como vista no debe cortar la animación
  /// en curso, y una vez vista se muestra de golpe.
  late final bool _animar = !widget.controlador.introduccionVista;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controlador.marcarIntroduccionVista(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tamanioMascota = widget.compacto ? 96.0 : 120.0;
    final duracion = _animar
        ? EstilosLexus.duracion(context, const Duration(milliseconds: 600))
        : Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: _animar ? 0 : 1, end: 1),
            duration: duracion,
            curve: Curves.easeOutCubic,
            builder: (context, valor, hijo) => Opacity(
              opacity: valor,
              child: Transform.scale(scale: 0.85 + 0.15 * valor, child: hijo),
            ),
            child: MascotaLexus(
              tamanio: tamanioMascota,
              estado: EstadoMascotaLexus.atento,
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              RespuestasLocalesLexus.introduccionTitulo,
              textAlign: TextAlign.center,
              style: EstilosLexus.titulo(tamanio: widget.compacto ? 24 : 28),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              RespuestasLocalesLexus.introduccionTexto,
              textAlign: TextAlign.center,
              style: EstilosLexus.cuerpo(color: EstilosLexus.textoSobreGris),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            RespuestasLocalesLexus.introduccionInvitacion,
            textAlign: TextAlign.center,
            style: EstilosLexus.cuerpo().copyWith(
              fontWeight: FontWeight.w700,
              color: ColoresApp.azulTurqui,
            ),
          ),
          const SizedBox(height: 16),
          // El recorrido guiado de Lexus señala las sugerencias; sin ámbito de
          // recorrido la marca no agrega nada.
          MarcaRecorrido(
            id: MarcaRecorridoId.lexusSugerencias,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final frase in _sugerencias)
                  ActionChip(
                    label: Text(frase),
                    labelStyle: const TextStyle(
                      fontSize: 13.5,
                      color: ColoresApp.azulTurquiOscuro,
                    ),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    backgroundColor: ColoresApp.blanco,
                    side: BorderSide(
                      color: ColoresApp.azulTurqui.withValues(alpha: 0.25),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onPressed: () => widget.alElegirSugerencia(frase),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
