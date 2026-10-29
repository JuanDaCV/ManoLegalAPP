import 'package:flutter/material.dart';

import '../../../../controlador/controlador_lexus.dart';
import '../../../../modelo/modelo_paso_recorrido.dart';
import '../../../compartido/widgets/recorrido/ambito_recorrido.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/fondo_juridico.dart';
import 'estilos_lexus.dart';
import 'mascota_lexus.dart';

/// Pide confirmación y, si la persona acepta, archiva la conversación actual
/// (queda guardada en su cuenta) y empieza una nueva.
Future<void> confirmarNuevaConversacionLexus(
  BuildContext context,
  ControladorLexus controlador,
) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: const Text('¿Iniciar una nueva conversación?'),
      content: const Text(
        'Lexus empezará de cero, sin el contexto de esta conversación. '
        'La actual queda archivada en tu cuenta.',
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
          onPressed: () => Navigator.of(contexto).pop(true),
          child: const Text('Nueva conversación'),
        ),
      ],
    ),
  );
  if (confirmado == true) controlador.nuevaConversacion();
}

/// Cabecera compacta del chat: rostro, nombre, aviso de que es una IA y la
/// acción de empezar de nuevo.
///
/// Con [sobreAzul] va como banda azul turquí con texto blanco (móvil y
/// tableta); si no, es la franja superior blanca de la tarjeta de escritorio.
class EncabezadoLexus extends StatelessWidget {
  const EncabezadoLexus({
    super.key,
    required this.controlador,
    required this.sobreAzul,
  });

  final ControladorLexus controlador;
  final bool sobreAzul;

  @override
  Widget build(BuildContext context) {
    final colorTitulo = sobreAzul
        ? ColoresApp.blanco
        : ColoresApp.azulTurquiOscuro;
    final colorSubtitulo = sobreAzul
        ? ColoresApp.blanco.withValues(alpha: 0.88)
        : EstilosLexus.textoCuerpo;

    final contenido = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final estrecho = restricciones.maxWidth < 420;
          return Row(
            children: [
              MascotaLexus(tamanio: 40, estado: EstadoMascotaLexus.atento),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Lexus',
                        style: EstilosLexus.titulo(
                          tamanio: 18,
                          color: colorTitulo,
                        ),
                      ),
                    ),
                    Text(
                      'Asistente jurídico de ManoLegal · IA',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: colorSubtitulo,
                      ),
                    ),
                  ],
                ),
              ),
              // El recorrido guiado de Lexus señala esta acción; sin ámbito
              // de recorrido la marca no agrega nada.
              MarcaRecorrido(
                id: MarcaRecorridoId.lexusNuevaConversacion,
                child: ListenableBuilder(
                  listenable: controlador,
                  builder: (context, _) =>
                      _accionNueva(context, estrecho: estrecho),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!sobreAzul) return contenido;
    return Container(
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            const Positioned.fill(child: FondoJuridico(intensidadIcono: 0.06)),
            contenido,
          ],
        ),
      ),
    );
  }

  Widget _accionNueva(BuildContext context, {required bool estrecho}) {
    final onPressed = controlador.hayConversacion
        ? () => confirmarNuevaConversacionLexus(context, controlador)
        : null;
    final color = sobreAzul ? ColoresApp.blanco : ColoresApp.azulTurqui;
    final colorInactivo = sobreAzul
        ? ColoresApp.blanco.withValues(alpha: 0.4)
        : ColoresApp.grisTexto.withValues(alpha: 0.5);

    if (estrecho) {
      return IconButton(
        tooltip: 'Nueva conversación',
        onPressed: onPressed,
        icon: const Icon(Icons.add_comment_outlined),
        color: color,
        disabledColor: colorInactivo,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_comment_outlined, size: 20),
      label: const Text('Nueva conversación'),
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: colorInactivo,
        minimumSize: const Size(48, 48),
      ),
    );
  }
}
