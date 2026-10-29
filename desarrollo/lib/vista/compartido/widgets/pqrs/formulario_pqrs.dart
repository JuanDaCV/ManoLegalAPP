import 'package:flutter/material.dart';

import '../../../../modelo/modelo_archivo_adjunto.dart';
import '../../../../modelo/modelo_pqrs.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/boton_personalizado.dart';
import '../../../widgets_comunes/campo_texto_personalizado.dart';
import 'iconos_pqrs.dart';
import 'selector_evidencias_pqrs.dart';

/// Formulario para radicar una PQRS: tipo, descripción y evidencias
/// opcionales. Solo recoge y valida los datos; el envío lo hace quien lo usa.
class FormularioPqrs extends StatefulWidget {
  final TipoPqrs? tipoInicial;
  final bool enviando;
  final String? mensajeError;
  final void Function(TipoPqrs tipo, String descripcion, List<ModeloArchivoAdjunto> evidencias) onEnviar;
  final VoidCallback onCancelar;

  const FormularioPqrs({
    super.key,
    this.tipoInicial,
    required this.enviando,
    this.mensajeError,
    required this.onEnviar,
    required this.onCancelar,
  });

  @override
  State<FormularioPqrs> createState() => _FormularioPqrsState();
}

class _FormularioPqrsState extends State<FormularioPqrs> {
  final _claveFormulario = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  late TipoPqrs? _tipo = widget.tipoInicial;
  List<ModeloArchivoAdjunto> _evidencias = const [];

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_claveFormulario.currentState!.validate()) return;
    widget.onEnviar(_tipo!, _descripcion.text, List.of(_evidencias));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _claveFormulario,
      // Mientras se envía, nada se puede cambiar: lo que se envía es
      // exactamente lo que se ve.
      child: AbsorbPointer(
        absorbing: widget.enviando,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormField<TipoPqrs>(
              initialValue: widget.tipoInicial,
              validator: validarTipoPqrs,
              builder: (campo) => _SelectorTipo(
                seleccionado: _tipo,
                error: campo.errorText,
                onSeleccionar: (tipo) {
                  setState(() => _tipo = tipo);
                  campo.didChange(tipo);
                },
              ),
            ),
            const SizedBox(height: 20),
            CampoTextoPersonalizado(
              etiqueta: 'Descripción',
              controlador: _descripcion,
              validador: validarDescripcionPqrs,
              contadorMaximo: longitudMaximaDescripcionPqrs,
              pista: 'Cuéntanos qué ocurrió o qué necesitas.',
            ),
            const SizedBox(height: 12),
            SelectorEvidenciasPqrs(
              evidencias: _evidencias,
              habilitado: !widget.enviando,
              onCambio: (lista) => setState(() => _evidencias = lista),
            ),
            if (widget.mensajeError != null) ...[
              const SizedBox(height: 16),
              _AvisoError(mensaje: widget.mensajeError!),
            ],
            const SizedBox(height: 24),
            BotonPersonalizado(texto: 'Enviar PQRS', cargando: widget.enviando, onPressed: _enviar),
            const SizedBox(height: 10),
            BotonPersonalizado(
              texto: 'Cancelar',
              esPrimario: false,
              onPressed: widget.enviando ? null : widget.onCancelar,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTipo extends StatelessWidget {
  final TipoPqrs? seleccionado;
  final String? error;
  final ValueChanged<TipoPqrs> onSeleccionar;

  const _SelectorTipo({required this.seleccionado, required this.error, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de PQRS',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColoresApp.azulTurquiOscuro),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tipo in TipoPqrs.values)
              ChoiceChip(
                avatar: Icon(
                  iconoTipoPqrs(tipo),
                  size: 18,
                  color: tipo == seleccionado ? ColoresApp.blanco : ColoresApp.azulTurqui,
                ),
                label: Text(tipo.etiqueta),
                selected: tipo == seleccionado,
                showCheckmark: false,
                selectedColor: ColoresApp.azulTurqui,
                labelStyle: TextStyle(
                  color: tipo == seleccionado ? ColoresApp.blanco : ColoresApp.azulTurquiOscuro,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onSeleccionar(tipo),
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: const TextStyle(color: ColoresApp.rojoNoVerificado, fontSize: 12)),
        ],
      ],
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;

  const _AvisoError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: ColoresApp.rojoNoVerificado, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje, style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
