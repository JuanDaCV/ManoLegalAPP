import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../configuracion/respuestas_locales_lexus.dart';
import '../../../../controlador/controlador_lexus.dart';
import '../../../../modelo/modelo_mensaje_lexus.dart';
import '../../../tema/tema_app.dart';
import 'abogados_sugeridos_lexus.dart';
import 'estilos_lexus.dart';
import 'mascota_lexus.dart';

const double _alturaMinimaBurbuja = 48;

/// Mensaje de la conversación: burbuja azul a la derecha para la persona y
/// tarjeta blanca con el rostro de Lexus a la izquierda. Debajo de un mensaje
/// de Lexus pueden ir el aviso de urgencia y los abogados sugeridos.
class BurbujaMensajeLexus extends StatelessWidget {
  const BurbujaMensajeLexus({
    super.key,
    required this.mensaje,
    required this.controlador,
    this.animar = true,
  });

  final ModeloMensajeLexus mensaje;
  final ControladorLexus controlador;

  /// Si el mensaje aparece con un fundido corto. Solo se decide al montarse.
  final bool animar;

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.autor == AutorMensajeLexus.usuario;
    return _Aparicion(
      animar: animar,
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final anchoMaximo = math.min(560.0, restricciones.maxWidth * 0.78);
          return esUsuario
              ? _delUsuario(anchoMaximo)
              : _deLexus(anchoMaximo, restricciones.maxWidth);
        },
      ),
    );
  }

  Widget _delUsuario(double anchoMaximo) {
    final fallido = mensaje.estado == EstadoMensajeLexus.fallido;
    return Semantics(
      container: true,
      label: 'Tú',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: anchoMaximo),
            child: Container(
              // La altura mínima mantiene el nodo de texto seleccionable por
              // encima de los 48 dp de un blanco táctil, aun con una línea.
              constraints: const BoxConstraints(
                minHeight: _alturaMinimaBurbuja,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: ColoresApp.azulTurqui,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: SelectableText(
                mensaje.texto,
                style: EstilosLexus.cuerpo(color: ColoresApp.blanco),
              ),
            ),
          ),
          if (fallido) _FilaError(mensaje: mensaje, controlador: controlador),
        ],
      ),
    );
  }

  Widget _deLexus(double anchoMaximo, double anchoDisponible) {
    final area = mensaje.areaSugerida;
    return Semantics(
      container: true,
      label: 'Lexus',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const MascotaLexus(tamanio: 24),
              const SizedBox(width: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: anchoMaximo),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: _alturaMinimaBurbuja,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: EstilosLexus.tarjeta(radio: 18),
                    child: SelectableText(
                      mensaje.texto,
                      style: EstilosLexus.cuerpo(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (mensaje.urgente)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(560, anchoDisponible - 32),
                ),
                child: const _AvisoUrgencia(),
              ),
            ),
          if (area != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(560, anchoDisponible - 32),
                ),
                child: AbogadosSugeridosLexus(
                  controlador: controlador,
                  area: area,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaError extends StatelessWidget {
  const _FilaError({required this.mensaje, required this.controlador});

  final ModeloMensajeLexus mensaje;
  final ControladorLexus controlador;

  @override
  Widget build(BuildContext context) {
    final tipo = mensaje.error;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: ColoresApp.rojoNoVerificado,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              tipo == null
                  ? RespuestasLocalesLexus.respuestaErrorGeneral
                  : RespuestasLocalesLexus.mensajeParaError(tipo),
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: ColoresApp.rojoNoVerificado,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ColoresApp.azulTurqui,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => controlador.reintentar(mensaje.id),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _AvisoUrgencia extends StatelessWidget {
  const _AvisoUrgencia();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: ColoresApp.rojoNoVerificado,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              RespuestasLocalesLexus.avisoUrgencia,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: ColoresApp.azulTurquiOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fundido y ligero deslizamiento de entrada. Si debe animarse se decide una
/// sola vez, al montarse: al volver a desplazar la lista, un mensaje antiguo
/// no se anima de nuevo.
class _Aparicion extends StatefulWidget {
  const _Aparicion({required this.animar, required this.child});

  final bool animar;
  final Widget child;

  @override
  State<_Aparicion> createState() => _AparicionState();
}

class _AparicionState extends State<_Aparicion> {
  late final bool _animar = widget.animar;

  @override
  Widget build(BuildContext context) {
    if (!_animar) return widget.child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: EstilosLexus.duracion(
        context,
        const Duration(milliseconds: 220),
      ),
      curve: Curves.easeOut,
      builder: (context, valor, hijo) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - valor)),
          child: hijo,
        ),
      ),
      child: widget.child,
    );
  }
}
