import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controlador/controlador_perfil_abogado.dart';
import '../../../../modelo/modelo_experiencia_profesional.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/campo_texto_personalizado.dart';
import 'bloque_perfil.dart';
import 'editor_perfil.dart';

/// Bloque "Experiencia" del perfil del abogado: línea de tiempo de ítems de
/// experiencia profesional. Si [editable], permite agregar, editar y
/// eliminar ítems.
class SeccionExperiencia extends StatelessWidget {
  final List<ModeloExperienciaProfesional> experiencia;
  final bool esEscritorio;
  final bool editable;

  const SeccionExperiencia({
    super.key,
    required this.experiencia,
    required this.esEscritorio,
    required this.editable,
  });

  void _abrirFormulario(BuildContext context, {ModeloExperienciaProfesional? existente}) {
    final controlador = context.read<ControladorPerfilAbogado>();
    final controladorTitulo = TextEditingController(text: existente?.titulo ?? '');
    final controladorDetalle = TextEditingController(text: existente?.detalle ?? '');
    final controladorAnio = TextEditingController(text: existente?.anio ?? '');

    mostrarEditorPerfil(
      context,
      esEscritorio: esEscritorio,
      titulo: existente == null ? 'Agregar experiencia' : 'Editar experiencia',
      contenido: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CampoTextoPersonalizado(etiqueta: 'Título', controlador: controladorTitulo, pista: 'Ej. Especialización en Derecho Civil'),
          const SizedBox(height: 12),
          CampoTextoPersonalizado(etiqueta: 'Detalle (opcional)', controlador: controladorDetalle, pista: 'Ej. Universidad Icesi'),
          const SizedBox(height: 12),
          CampoTextoPersonalizado(etiqueta: 'Año (opcional)', controlador: controladorAnio, pista: 'Ej. 2020'),
        ],
      ),
      onGuardar: () async {
        final titulo = controladorTitulo.text.trim();
        if (titulo.isEmpty) return 'El título de la experiencia no puede quedar vacío.';
        final nuevaExperiencia = ModeloExperienciaProfesional(
          id: existente?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          titulo: titulo,
          detalle: controladorDetalle.text.trim().isEmpty ? null : controladorDetalle.text.trim(),
          anio: controladorAnio.text.trim().isEmpty ? null : controladorAnio.text.trim(),
        );
        final guardado = existente == null
            ? await controlador.agregarExperiencia(nuevaExperiencia)
            : await controlador.editarExperiencia(nuevaExperiencia);
        return guardado ? null : controlador.mensajeError;
      },
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, ModeloExperienciaProfesional experiencia) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar experiencia'),
        content: Text('¿Deseas eliminar "${experiencia.titulo}" de tu experiencia?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contextDialogo).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColoresApp.rojoNoVerificado),
            onPressed: () => Navigator.of(contextDialogo).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final controlador = context.read<ControladorPerfilAbogado>();
    final mensajero = ScaffoldMessenger.of(context);
    final eliminado = await controlador.eliminarExperiencia(experiencia.id);
    mensajero.showSnackBar(
      SnackBar(
        content: Text(eliminado ? 'Experiencia eliminada.' : controlador.mensajeError ?? 'No se pudo eliminar.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BloquePerfil(
      titulo: 'Experiencia',
      icono: Icons.timeline_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < experiencia.length; i++)
            _ItemExperiencia(
              experiencia: experiencia[i],
              esUltimo: i == experiencia.length - 1,
              editable: editable,
              onEditar: () => _abrirFormulario(context, existente: experiencia[i]),
              onEliminar: () => _confirmarEliminar(context, experiencia[i]),
            ),
          if (experiencia.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Todavía no has agregado experiencia.', style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
            ),
          if (editable) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _abrirFormulario(context),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Agregar experiencia'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemExperiencia extends StatelessWidget {
  final ModeloExperienciaProfesional experiencia;
  final bool esUltimo;
  final bool editable;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ItemExperiencia({
    required this.experiencia,
    required this.esUltimo,
    required this.editable,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final detalleYAnio = [
      if (experiencia.detalle != null) experiencia.detalle!,
      if (experiencia.anio != null) experiencia.anio!,
    ].join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: ColoresApp.dorado, shape: BoxShape.circle),
              ),
              if (!esUltimo) Expanded(child: Container(width: 1.5, color: ColoresApp.grisTexto.withValues(alpha: 0.25))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experiencia.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ColoresApp.azulTurquiOscuro),
                        ),
                        if (detalleYAnio.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(detalleYAnio, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                  if (editable) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: ColoresApp.grisTexto),
                      tooltip: 'Editar',
                      onPressed: onEditar,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: ColoresApp.rojoNoVerificado),
                      tooltip: 'Eliminar',
                      onPressed: onEliminar,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
