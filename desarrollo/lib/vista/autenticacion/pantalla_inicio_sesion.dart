import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../utilidades/validadores.dart';
import '../widgets_comunes/boton_personalizado.dart';
import '../widgets_comunes/botones_sociales.dart';
import '../widgets_comunes/campo_texto_personalizado.dart';
import '../widgets_comunes/campos_registro_comunes.dart';
import '../widgets_comunes/plantilla_autenticacion.dart';
import 'pantalla_recuperar_contrasena.dart';
import 'pantalla_seleccion_rol.dart';

/// Pantalla de inicio de sesión con correo y contraseña.
///
/// En la web solo ofrece Google como proveedor externo, con el diseño de dos
/// paneles de escritorio de [PlantillaAutenticacion]. Facebook y GitHub aún
/// no funcionan, así que allí no se muestran; en Android se conserva la fila
/// de siempre.
class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({super.key, this.esWeb = kIsWeb});

  /// Permite a las pruebas, que no corren en la web, probar su variante web.
  @visibleForTesting
  final bool esWeb;

  @override
  State<PantallaInicioSesion> createState() => _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends State<PantallaInicioSesion> {
  final _formKey = GlobalKey<FormState>();
  final _correoControlador = TextEditingController();
  final _contrasenaControlador = TextEditingController();

  @override
  void dispose() {
    _correoControlador.dispose();
    _contrasenaControlador.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion(ControladorAutenticacion controlador) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await controlador.iniciarSesion(
      _correoControlador.text.trim(),
      _contrasenaControlador.text,
    );
    if (ok && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _iniciarSesionConGoogle(ControladorAutenticacion controlador) async {
    final resultado = await controlador.autenticarConGoogle();
    if (!mounted) return;

    switch (resultado.estado) {
      case EstadoGoogle.perfilExistente:
        Navigator.of(context).popUntil((r) => r.isFirst);
      case EstadoGoogle.perfilPendiente:
        // Se arrastran los datos de Google para que el formulario de registro
        // llegue autorrellenado y no haya que autenticarse una segunda vez.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PantallaSeleccionRol(datosGoogle: resultado.datos),
          ),
        );
      case EstadoGoogle.cancelado:
      case EstadoGoogle.error:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAutenticacion>();

    return PlantillaAutenticacion(
      motivo: MotivoAutenticacion.iniciarSesion,
      disenoWeb: widget.esWeb,
      titulo: 'Bienvenido de nuevo',
      subtitulo: 'Ingresa tus datos para continuar con tu cuenta de ManoLegal.',
      formulario: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoTextoPersonalizado(
              etiqueta: 'Correo',
              controlador: _correoControlador,
              validador: validarCorreo,
              tecladoTipo: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CampoTextoPersonalizado(
              etiqueta: 'Contraseña',
              controlador: _contrasenaControlador,
              validador: validarContrasena,
              obscureText: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaRecuperarContrasena()),
                ),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            if (controlador.mensajeError != null) ...[
              BannerError(mensaje: controlador.mensajeError!),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            if (widget.esWeb) ...[
              // Mismo separador y espacio que trae la fila de móvil.
              const SeparadorTexto(texto: 'o continúa con'),
              const SizedBox(height: 16),
              BotonesSociales.google(onGoogle: () => _iniciarSesionConGoogle(controlador)),
            ] else
              BotonesSociales.fila(onGoogle: () => _iniciarSesionConGoogle(controlador)),
            const SizedBox(height: 20),
            BotonPersonalizado(
              texto: 'Iniciar sesión',
              cargando: controlador.cargando,
              onPressed: () => _iniciarSesion(controlador),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaSeleccionRol()),
                ),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
