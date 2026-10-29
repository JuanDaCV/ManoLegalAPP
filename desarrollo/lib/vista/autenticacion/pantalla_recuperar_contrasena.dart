import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../tema/tema_app.dart';
import '../utilidades/validadores.dart';
import '../widgets_comunes/boton_personalizado.dart';
import '../widgets_comunes/campo_texto_personalizado.dart';
import '../widgets_comunes/plantilla_autenticacion.dart';

/// Permite solicitar el correo de recuperación de contraseña.
class PantallaRecuperarContrasena extends StatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  State<PantallaRecuperarContrasena> createState() => _PantallaRecuperarContrasenaState();
}

class _PantallaRecuperarContrasenaState extends State<PantallaRecuperarContrasena> {
  final _formKey = GlobalKey<FormState>();
  final _correoControlador = TextEditingController();
  bool _correoEnviado = false;

  @override
  void dispose() {
    _correoControlador.dispose();
    super.dispose();
  }

  Future<void> _enviar(ControladorAutenticacion controlador) async {
    // El Form (y su GlobalKey) solo existe montado en el estado formulario:
    // "Reenviar enlace" se dispara desde el estado enviado, donde el correo
    // ya fue validado al enviarlo la primera vez, así que se omite revalidar.
    if (!_correoEnviado && !_formKey.currentState!.validate()) return;
    final ok = await controlador.recuperarContrasena(_correoControlador.text.trim());
    if (!mounted) return;
    if (ok) setState(() => _correoEnviado = true);
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAutenticacion>();

    return PlantillaAutenticacion(
      motivo: MotivoAutenticacion.recuperar,
      titulo: 'Recupera tu contraseña',
      subtitulo: 'Te enviaremos un enlace a tu correo para que puedas crear una nueva.',
      // AnimatedSize + AnimatedSwitcher: además del fade+slide entre los dos
      // estados, la tarjeta cambia de alto suavemente en vez de saltar.
      formulario: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animacion) => FadeTransition(
            opacity: animacion,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animacion),
              child: child,
            ),
          ),
          child: _correoEnviado
              ? _EstadoEnviado(
                  correo: _correoControlador.text.trim(),
                  cargando: controlador.cargando,
                  mensajeError: controlador.mensajeError,
                  onVolver: () => Navigator.of(context).pop(),
                  onReenviar: () => _enviar(controlador),
                )
              : _EstadoFormulario(
                  formKey: _formKey,
                  correoControlador: _correoControlador,
                  cargando: controlador.cargando,
                  mensajeError: controlador.mensajeError,
                  onEnviar: () => _enviar(controlador),
                ),
        ),
      ),
    );
  }
}

/// Estado (a): formulario para pedir el correo de recuperación.
class _EstadoFormulario extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController correoControlador;
  final bool cargando;
  final String? mensajeError;
  final VoidCallback onEnviar;

  const _EstadoFormulario({
    required this.formKey,
    required this.correoControlador,
    required this.cargando,
    required this.mensajeError,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CampoTextoPersonalizado(
            etiqueta: 'Correo',
            controlador: correoControlador,
            validador: validarCorreo,
            tecladoTipo: TextInputType.emailAddress,
          ),
          if (mensajeError != null) ...[
            const SizedBox(height: 12),
            BannerError(mensaje: mensajeError!),
          ],
          const SizedBox(height: 24),
          BotonPersonalizado(texto: 'Enviar enlace', cargando: cargando, onPressed: onEnviar),
        ],
      ),
    );
  }
}

/// Estado (b): confirmación de correo enviado, con opción de reenviar.
class _EstadoEnviado extends StatelessWidget {
  final String correo;
  final bool cargando;
  final String? mensajeError;
  final VoidCallback onVolver;
  final VoidCallback onReenviar;

  const _EstadoEnviado({
    required this.correo,
    required this.cargando,
    required this.mensajeError,
    required this.onVolver,
    required this.onReenviar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColoresApp.verdeVerificado.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read, color: ColoresApp.verdeVerificado, size: 40),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: ColoresApp.azulTurquiOscuro),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 14, height: 1.4),
            children: [
              const TextSpan(text: 'Te enviamos un enlace de recuperación a '),
              TextSpan(
                text: correo,
                style: const TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.azulTurquiOscuro),
              ),
              const TextSpan(text: '. Revisa también tu carpeta de spam.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        if (mensajeError != null) ...[
          const SizedBox(height: 16),
          BannerError(mensaje: mensajeError!),
        ],
        const SizedBox(height: 24),
        BotonPersonalizado(texto: 'Volver a iniciar sesión', onPressed: onVolver),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: cargando ? null : onReenviar,
            child: const Text('Reenviar enlace'),
          ),
        ),
      ],
    );
  }
}
