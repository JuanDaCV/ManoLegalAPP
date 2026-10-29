import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../controlador/controlador_perfil_abogado.dart';
import '../../../../modelo/modelo_perfil_abogado.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/campo_texto_personalizado.dart';
import 'bloque_perfil.dart';
import 'editor_perfil.dart';

/// Bloque "Redes sociales" del perfil del abogado: Instagram, Facebook y
/// LinkedIn.
///
/// Los enlaces son los que el abogado guardó y se abren de verdad. En el
/// perfil público solo aparecen las redes configuradas, y si no hay ninguna
/// el bloque entero desaparece. En modo edición se muestran siempre las tres,
/// para que el abogado vea cuáles le faltan.
class SeccionRedesSociales extends StatelessWidget {
  final ModeloPerfilAbogado perfil;
  final bool esEscritorio;
  final bool editable;

  const SeccionRedesSociales({super.key, required this.perfil, required this.esEscritorio, required this.editable});

  void _editar(BuildContext context) {
    final controlador = context.read<ControladorPerfilAbogado>();
    final controladorInstagram = TextEditingController(text: perfil.instagram ?? '');
    final controladorFacebook = TextEditingController(text: perfil.facebook ?? '');
    final controladorLinkedin = TextEditingController(text: perfil.linkedin ?? '');

    mostrarEditorPerfil(
      context,
      esEscritorio: esEscritorio,
      titulo: 'Editar redes sociales',
      contenido: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CampoTextoPersonalizado(
            etiqueta: 'Instagram',
            controlador: controladorInstagram,
            pista: 'https://instagram.com/...',
          ),
          const SizedBox(height: 12),
          CampoTextoPersonalizado(
            etiqueta: 'Facebook',
            controlador: controladorFacebook,
            pista: 'https://facebook.com/...',
          ),
          const SizedBox(height: 12),
          CampoTextoPersonalizado(
            etiqueta: 'LinkedIn',
            controlador: controladorLinkedin,
            pista: 'https://linkedin.com/in/...',
          ),
        ],
      ),
      // Se envía la cadena vacía en lugar de `null` al borrar una red:
      // `copiarCon` usa `??`, así que un `null` conservaría el valor anterior
      // y la red nunca se podría quitar. La cadena vacía sí la borra, y tanto
      // la vista como `tieneAlgunaRed` la tratan como ausencia.
      onGuardar: () async {
        final guardado = await controlador.actualizarRedes(
          instagram: controladorInstagram.text.trim(),
          facebook: controladorFacebook.text.trim(),
          linkedin: controladorLinkedin.text.trim(),
        );
        return guardado ? null : controlador.mensajeError;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final botones = [
      _BotonRedSocial(icono: FontAwesomeIcons.instagram, etiqueta: 'Instagram', enlace: perfil.instagram),
      _BotonRedSocial(icono: FontAwesomeIcons.facebookF, etiqueta: 'Facebook', enlace: perfil.facebook),
      _BotonRedSocial(icono: FontAwesomeIcons.linkedinIn, etiqueta: 'LinkedIn', enlace: perfil.linkedin),
    ];

    // En modo lectura (perfil público) no tiene sentido mostrar botones
    // deshabilitados: solo se muestran las redes que el abogado sí cargó, y
    // si no cargó ninguna, se oculta todo el bloque.
    final botonesAMostrar = editable ? botones : botones.where((boton) => boton.activo).toList();
    if (botonesAMostrar.isEmpty) return const SizedBox.shrink();

    return BloquePerfil(
      titulo: 'Redes sociales',
      icono: Icons.share_outlined,
      onEditar: editable ? () => _editar(context) : null,
      child: Wrap(spacing: 12, runSpacing: 12, children: botonesAMostrar),
    );
  }
}

class _BotonRedSocial extends StatelessWidget {
  final FaIconData icono;
  final String etiqueta;
  final String? enlace;

  const _BotonRedSocial({required this.icono, required this.etiqueta, required this.enlace});

  bool get activo => enlace != null && enlace!.trim().isNotEmpty;

  /// Completa el esquema cuando el abogado guardó solo el dominio o el
  /// usuario. Sin esto, `launchUrl` recibiría una URL relativa y fallaría.
  Uri get _destino {
    final texto = enlace!.trim();
    final completo = texto.startsWith('http://') || texto.startsWith('https://') ? texto : 'https://$texto';
    return Uri.parse(completo);
  }

  Future<void> _abrir(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final abierto = await launchUrl(_destino, mode: LaunchMode.externalApplication);
      if (!abierto) {
        mensajero.showSnackBar(SnackBar(content: Text('No se pudo abrir el enlace de $etiqueta.')));
      }
    } catch (_) {
      mensajero.showSnackBar(SnackBar(content: Text('No se pudo abrir el enlace de $etiqueta.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = activo ? ColoresApp.azulTurqui : ColoresApp.grisTexto.withValues(alpha: 0.5);

    return OutlinedButton.icon(
      // Sin enlace no hay nada que abrir: el botón queda deshabilitado.
      onPressed: activo ? () => _abrir(context) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: activo ? 0.6 : 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: FaIcon(icono, size: 16, color: color),
      label: Text(etiqueta),
    );
  }
}
