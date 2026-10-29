import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../../modelo/modelo_cliente.dart';
import '../utilidades/validadores.dart';
import '../widgets_comunes/boton_personalizado.dart';
import '../widgets_comunes/botones_sociales.dart';
import '../widgets_comunes/campo_texto_personalizado.dart';
import '../widgets_comunes/campos_registro_comunes.dart';
import '../widgets_comunes/plantilla_autenticacion.dart';

/// Formulario de registro para usuarios con rol de cliente.
///
/// Si [datosGoogle] no es nulo, el usuario ya se autenticó con Google desde
/// esta misma pantalla (ver [_continuarConGoogle]): el formulario se
/// autorrellena, el correo queda de solo lectura, no se piden contraseñas y
/// se oculta el botón de Google.
class PantallaRegistroCliente extends StatefulWidget {
  final DatosGoogle? datosGoogle;

  const PantallaRegistroCliente({super.key, this.datosGoogle});

  @override
  State<PantallaRegistroCliente> createState() => _PantallaRegistroClienteState();
}

class _PantallaRegistroClienteState extends State<PantallaRegistroCliente> {
  final _formKey = GlobalKey<FormState>();
  final _nombreControlador = TextEditingController();
  final _apellidoControlador = TextEditingController();
  final _telefonoControlador = TextEditingController();
  final _correoControlador = TextEditingController();
  final _contrasenaControlador = TextEditingController();
  final _confirmacionControlador = TextEditingController();
  DateTime? _fechaNacimiento;

  bool get _esRegistroGoogle => widget.datosGoogle != null;

  @override
  void initState() {
    super.initState();
    final datos = widget.datosGoogle;
    if (datos != null) {
      _nombreControlador.text = datos.nombre;
      _apellidoControlador.text = datos.apellido;
      _correoControlador.text = datos.correo;
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  Future<void> _continuarConGoogle(ControladorAutenticacion controlador) async {
    final resultado = await controlador.autenticarConGoogle();
    if (!mounted) return;

    switch (resultado.estado) {
      case EstadoGoogle.perfilExistente:
        Navigator.of(context).popUntil((r) => r.isFirst);
      case EstadoGoogle.perfilPendiente:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PantallaRegistroCliente(datosGoogle: resultado.datos)),
        );
      case EstadoGoogle.cancelado:
      case EstadoGoogle.error:
        break;
    }
  }

  @override
  void dispose() {
    _nombreControlador.dispose();
    _apellidoControlador.dispose();
    _telefonoControlador.dispose();
    _correoControlador.dispose();
    _contrasenaControlador.dispose();
    _confirmacionControlador.dispose();
    super.dispose();
  }

  Future<void> _registrar(ControladorAutenticacion controlador) async {
    final fechaValida = validarFechaNacimiento(_fechaNacimiento);
    if (fechaValida != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fechaValida)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final cliente = ModeloCliente(
      uid: '',
      nombre: _nombreControlador.text.trim(),
      apellido: _apellidoControlador.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
      telefono: '+57${_telefonoControlador.text.trim()}',
      correo: _correoControlador.text.trim(),
    );

    final ok = _esRegistroGoogle
        ? await controlador.completarRegistroClienteGoogle(cliente)
        : await controlador.registrarCliente(cliente, _contrasenaControlador.text);
    if (ok && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAutenticacion>();

    return PlantillaAutenticacion(
      motivo: MotivoAutenticacion.registroCliente,
      titulo: 'Crea tu cuenta',
      subtitulo: 'Regístrate como cliente para buscar abogados verificados.',
      formulario: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_esRegistroGoogle) ...[
            BotonesSociales.google(onGoogle: () => _continuarConGoogle(controlador)),
            const SizedBox(height: 20),
            const SeparadorTexto(texto: 'o regístrate con tu correo'),
            const SizedBox(height: 20),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CamposDatosPersonales(
                  nombreControlador: _nombreControlador,
                  apellidoControlador: _apellidoControlador,
                  telefonoControlador: _telefonoControlador,
                  fechaNacimiento: _fechaNacimiento,
                  onSeleccionarFecha: _seleccionarFecha,
                ),
                const SizedBox(height: 16),
                CampoTextoPersonalizado(
                  etiqueta: 'Correo',
                  controlador: _correoControlador,
                  validador: validarCorreo,
                  tecladoTipo: TextInputType.emailAddress,
                  soloLectura: _esRegistroGoogle,
                ),
                if (!_esRegistroGoogle) ...[
                  const SizedBox(height: 16),
                  CampoTextoPersonalizado(
                    etiqueta: 'Contraseña',
                    controlador: _contrasenaControlador,
                    validador: validarContrasena,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  CampoTextoPersonalizado(
                    etiqueta: 'Confirmar contraseña',
                    controlador: _confirmacionControlador,
                    validador: (valor) => validarConfirmacionContrasena(_contrasenaControlador.text, valor),
                    obscureText: true,
                  ),
                ],
                if (controlador.mensajeError != null) ...[
                  const SizedBox(height: 12),
                  BannerError(mensaje: controlador.mensajeError!),
                ],
                const SizedBox(height: 24),
                BotonPersonalizado(
                  texto: 'Registrarme',
                  cargando: controlador.cargando,
                  onPressed: () => _registrar(controlador),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
