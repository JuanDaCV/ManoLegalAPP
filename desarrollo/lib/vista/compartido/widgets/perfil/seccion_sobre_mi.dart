import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controlador/controlador_perfil_abogado.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/campo_texto_personalizado.dart';
import 'bloque_perfil.dart';
import 'editor_perfil.dart';

/// Límite generoso para el texto de "Sobre mí" del perfil del abogado. Es un
/// texto libre más amplio que el usado en el registro (allí el límite es de
/// ~300 caracteres).
const int _limiteCaracteresSobreMi = 1500;

/// Bloque "Sobre mí" del perfil del abogado: texto libre, editable cuando
/// [editable] es `true`.
class SeccionSobreMi extends StatelessWidget {
  final String sobreMi;
  final bool esEscritorio;
  final bool editable;

  const SeccionSobreMi({super.key, required this.sobreMi, required this.esEscritorio, required this.editable});

  void _editar(BuildContext context) {
    final controlador = context.read<ControladorPerfilAbogado>();
    final controladorTexto = TextEditingController(text: sobreMi);

    mostrarEditorPerfil(
      context,
      esEscritorio: esEscritorio,
      titulo: 'Editar sobre mí',
      contenido: CampoTextoPersonalizado(
        etiqueta: 'Sobre mí',
        controlador: controladorTexto,
        contadorMaximo: _limiteCaracteresSobreMi,
        pista: 'Cuéntales a los clientes sobre tu experiencia y tu forma de trabajar...',
      ),
      onGuardar: () async {
        final guardado = await controlador.actualizarSobreMi(controladorTexto.text.trim());
        return guardado ? null : controlador.mensajeError;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BloquePerfil(
      titulo: 'Sobre mí',
      icono: Icons.info_outline,
      onEditar: editable ? () => _editar(context) : null,
      child: Text(
        sobreMi,
        style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14, height: 1.5),
      ),
    );
  }
}
