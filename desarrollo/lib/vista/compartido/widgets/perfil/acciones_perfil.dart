import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../tema/tema_app.dart';

/// Botones de contacto del perfil del abogado: "Contactar por WhatsApp" y
/// "Contactar por correo".
///
/// Ambos usan los datos reales del abogado. Si el dato no existe, el botón
/// queda deshabilitado y se explica por qué, en lugar de abrir una
/// conversación o un correo sin destinatario válido.
class AccionesPerfil extends StatelessWidget {
  final String telefonoContacto;
  final String correoContacto;

  /// Nombre del abogado, usado solo para redactar el cuerpo del correo.
  final String nombreAbogado;

  const AccionesPerfil({
    super.key,
    required this.telefonoContacto,
    required this.correoContacto,
    this.nombreAbogado = '',
  });

  /// Deja solo los dígitos y antepone el indicativo de Colombia cuando falta.
  /// Devuelve `null` si no queda un número utilizable.
  static String? _numeroWhatsapp(String telefono) {
    final digitos = telefono.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return null;
    if (digitos.startsWith('57')) return digitos;
    return '57$digitos';
  }

  Future<void> _abrir(BuildContext context, Uri destino) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final abierto = await launchUrl(destino, mode: LaunchMode.externalApplication);
      if (!abierto) {
        mensajero.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación de contacto.')),
        );
      }
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la aplicación de contacto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numero = _numeroWhatsapp(telefonoContacto);
    final correo = correoContacto.trim();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _BotonAccionContacto(
          icono: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
          etiqueta: 'Contactar por WhatsApp',
          valorContacto: numero == null ? 'Este abogado no publicó un teléfono de contacto.' : telefonoContacto,
          onPresionado: numero == null ? null : () => _abrir(context, Uri.parse('https://wa.me/$numero')),
        ),
        _BotonAccionContacto(
          icono: const Icon(Icons.mail_outline, size: 18),
          etiqueta: 'Contactar por correo',
          valorContacto: correo.isEmpty ? 'Este abogado no publicó un correo de contacto.' : correo,
          onPresionado: correo.isEmpty
              ? null
              : () => _abrir(
                    context,
                    Uri(
                      scheme: 'mailto',
                      path: correo,
                      queryParameters: {
                        'subject': 'Consulta legal desde ManoLegal',
                        'body': nombreAbogado.isEmpty
                            ? 'Hola, vi tu perfil en ManoLegal y quisiera hacerte una consulta.'
                            : 'Hola $nombreAbogado, vi tu perfil en ManoLegal y quisiera hacerte una consulta.',
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}

class _BotonAccionContacto extends StatelessWidget {
  final Widget icono;
  final String etiqueta;
  final String valorContacto;

  /// `null` deshabilita el botón: el dato de contacto no existe.
  final VoidCallback? onPresionado;

  const _BotonAccionContacto({
    required this.icono,
    required this.etiqueta,
    required this.valorContacto,
    required this.onPresionado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onPresionado,
          icon: icono,
          label: Text(etiqueta),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            valorContacto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
