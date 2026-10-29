import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controlador/controlador_perfil_publico.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/campo_texto_personalizado.dart';
import 'bloque_perfil.dart';

/// Formulario para que un cliente deje una reseña en el perfil público de un
/// abogado: selector de calificación (1 a 5 estrellas) y comentario.
///
/// La reseña se guarda de verdad en
/// `perfilesPublicosAbogados/{abogadoUid}/resenas/{clienteUid}`. Como el
/// identificador del documento es el propio cliente, publicar por segunda vez
/// reemplaza la reseña anterior en lugar de duplicarla, y por eso el
/// formulario se muestra precargado cuando ya existe una.
class FormularioNuevaResena extends StatefulWidget {
  const FormularioNuevaResena({super.key});

  @override
  State<FormularioNuevaResena> createState() => _FormularioNuevaResenaState();
}

class _FormularioNuevaResenaState extends State<FormularioNuevaResena> {
  int _calificacionSeleccionada = 0;
  final _controladorComentario = TextEditingController();
  bool _enviando = false;

  /// Identificador de la reseña ya precargada, para no volver a precargar el
  /// formulario mientras el usuario lo está editando.
  String? _resenaPrecargada;

  @override
  void dispose() {
    _controladorComentario.dispose();
    super.dispose();
  }

  bool get _puedeEnviar =>
      !_enviando && _calificacionSeleccionada > 0 && _controladorComentario.text.trim().isNotEmpty;

  Future<void> _publicar() async {
    final controlador = context.read<ControladorPerfilPublico>();
    final mensajero = ScaffoldMessenger.of(context);

    setState(() => _enviando = true);
    final error = await controlador.publicarResena(
      calificacion: _calificacionSeleccionada,
      comentario: _controladorComentario.text,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    if (error != null) {
      mensajero.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    mensajero.showSnackBar(
      const SnackBar(content: Text('Tu reseña se publicó correctamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorPerfilPublico>();

    // Un abogado no puede reseñarse a sí mismo, y sin sesión no hay autor.
    if (!controlador.puedeResenar) return const SizedBox.shrink();

    final miResena = controlador.miResena;
    final yaResenado = miResena != null;

    // Precarga la reseña existente una sola vez, para que el usuario pueda
    // corregirla sin volver a escribirla desde cero.
    if (yaResenado && _resenaPrecargada != miResena.clienteUid) {
      _resenaPrecargada = miResena.clienteUid;
      _calificacionSeleccionada = miResena.calificacion;
      _controladorComentario.text = miResena.comentario;
    }

    return BloquePerfil(
      titulo: yaResenado ? 'Tu reseña' : 'Deja tu reseña',
      icono: Icons.rate_review_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (yaResenado) ...[
            const Text(
              'Ya dejaste una reseña en este perfil. Si la publicas de nuevo, reemplazará la anterior.',
              style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],
          const Text('Calificación', style: TextStyle(fontWeight: FontWeight.w600, color: ColoresApp.grisTexto, fontSize: 13)),
          const SizedBox(height: 6),
          _SelectorEstrellas(
            calificacionSeleccionada: _calificacionSeleccionada,
            onSeleccionar: (valor) => setState(() => _calificacionSeleccionada = valor),
          ),
          const SizedBox(height: 16),
          CampoTextoPersonalizado(
            etiqueta: 'Comentario',
            controlador: _controladorComentario,
            contadorMaximo: 500,
            pista: 'Cuéntanos cómo fue tu experiencia con este abogado...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _puedeEnviar ? _publicar : null,
              child: _enviando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ColoresApp.blanco),
                    )
                  : Text(yaResenado ? 'Actualizar reseña' : 'Publicar reseña'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de 5 estrellas tocables para elegir una calificación de 1 a 5.
class _SelectorEstrellas extends StatelessWidget {
  final int calificacionSeleccionada;
  final ValueChanged<int> onSeleccionar;

  const _SelectorEstrellas({required this.calificacionSeleccionada, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (indice) {
        final valorEstrella = indice + 1;
        final llena = valorEstrella <= calificacionSeleccionada;
        return IconButton(
          onPressed: () => onSeleccionar(valorEstrella),
          icon: Icon(llena ? Icons.star : Icons.star_border, color: ColoresApp.dorado, size: 28),
          tooltip: '$valorEstrella estrella${valorEstrella == 1 ? '' : 's'}',
          visualDensity: VisualDensity.compact,
        );
      }),
    );
  }
}
