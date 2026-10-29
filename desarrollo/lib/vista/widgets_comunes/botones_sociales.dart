import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../tema/tema_app.dart';

/// Variante visual interna de [BotonesSociales].
enum _VarianteBotonesSociales { fila, google }

/// Botones de autenticación con proveedores externos (Google, Facebook, GitHub).
///
/// Facebook y GitHub siguen siendo solo de presentación: muestran un aviso
/// de "Próximamente disponible" al presionarlos. Google ya está cableado a
/// través de [onGoogle] (ver `ControladorAutenticacion.autenticarConGoogle`
/// y `ServicioGoogle`); si no se provee, cae también al aviso. El registro
/// de abogado sigue pasando obligatoriamente por el paso 2 y el paso 3 de
/// documentación, por lo que el botón de Google del paso 1 navega al paso 2
/// y nunca completa el registro directamente.
class BotonesSociales extends StatelessWidget {
  final _VarianteBotonesSociales _variante;
  final VoidCallback? onGoogle;

  /// Variante para el login: separador "o continúa con" y tres botones
  /// cuadrados (Google, Facebook, GitHub).
  const BotonesSociales.fila({super.key, this.onGoogle}) : _variante = _VarianteBotonesSociales.fila;

  /// Variante para registro: un botón ancho completo "Continuar con Google".
  const BotonesSociales.google({super.key, this.onGoogle}) : _variante = _VarianteBotonesSociales.google;

  void _mostrarProximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente disponible')),
    );
  }

  void _alPresionarGoogle(BuildContext context) {
    if (onGoogle != null) {
      onGoogle!();
    } else {
      _mostrarProximamente(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _variante == _VarianteBotonesSociales.fila ? _construirFila(context) : _construirGoogle(context);
  }

  Widget _construirFila(BuildContext context) {
    final colorLinea = ColoresApp.grisTexto.withValues(alpha: 0.3);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: colorLinea)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('o continúa con', style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
            ),
            Expanded(child: Divider(color: colorLinea)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BotonSocialCuadrado(
              etiqueta: 'Continuar con Google',
              icono: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437)),
              onTap: () => _alPresionarGoogle(context),
            ),
            const SizedBox(width: 16),
            _BotonSocialCuadrado(
              etiqueta: 'Continuar con Facebook',
              icono: const FaIcon(FontAwesomeIcons.facebookF, color: Color(0xFF1877F2)),
              onTap: () => _mostrarProximamente(context),
            ),
            const SizedBox(width: 16),
            _BotonSocialCuadrado(
              etiqueta: 'Continuar con GitHub',
              icono: const FaIcon(FontAwesomeIcons.github, color: Color(0xFF181717)),
              onTap: () => _mostrarProximamente(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirGoogle(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: ColoresApp.grisTexto.withValues(alpha: 0.3)),
        ),
        onPressed: () => _alPresionarGoogle(context),
        icon: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437), size: 18),
        label: const Text('Continuar con Google'),
      ),
    );
  }
}

/// Botón cuadrado de 56x56 con un ícono de marca, usado en [BotonesSociales.fila].
class _BotonSocialCuadrado extends StatelessWidget {
  final String etiqueta;
  final Widget icono;
  final VoidCallback onTap;

  const _BotonSocialCuadrado({required this.etiqueta, required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: etiqueta,
      child: Semantics(
        button: true,
        label: etiqueta,
        child: Material(
          color: ColoresApp.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: ColoresApp.grisTexto.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 56, height: 56, child: Center(child: icono)),
          ),
        ),
      ),
    );
  }
}
