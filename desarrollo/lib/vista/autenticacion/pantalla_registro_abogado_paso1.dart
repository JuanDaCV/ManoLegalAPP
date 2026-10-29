import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../utilidades/validadores.dart';
import '../widgets_comunes/boton_personalizado.dart';
import '../widgets_comunes/botones_sociales.dart';
import '../widgets_comunes/campo_texto_personalizado.dart';
import '../widgets_comunes/campos_registro_comunes.dart';
import '../widgets_comunes/plantilla_autenticacion.dart';
import 'pantalla_registro_abogado_paso2.dart';

/// Paso 1 del registro de abogado: datos personales (igual que un cliente).
///
/// Si [datosGoogle] no es nulo, el usuario ya se autenticó con Google desde
/// esta misma pantalla (ver [_continuarConGoogle]): el formulario se
/// autorrellena, el correo queda de solo lectura, no se piden contraseñas y
/// se oculta el botón de Google. En cualquier caso, "Continuar" siempre
/// avanza al paso 2: el registro de abogado nunca se completa en el paso 1.
class PantallaRegistroAbogadoPaso1 extends StatefulWidget {
  final DatosGoogle? datosGoogle;

  const PantallaRegistroAbogadoPaso1({super.key, this.datosGoogle});

  @override
  State<PantallaRegistroAbogadoPaso1> createState() => _PantallaRegistroAbogadoPaso1State();
}

class _PantallaRegistroAbogadoPaso1State extends State<PantallaRegistroAbogadoPaso1> {
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
          MaterialPageRoute(builder: (_) => PantallaRegistroAbogadoPaso1(datosGoogle: resultado.datos)),
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

  void _continuar() {
    final fechaValida = validarFechaNacimiento(_fechaNacimiento);
    if (fechaValida != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fechaValida)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaRegistroAbogadoPaso2(
          nombre: _nombreControlador.text.trim(),
          apellido: _apellidoControlador.text.trim(),
          fechaNacimiento: _fechaNacimiento!,
          telefono: '+57${_telefonoControlador.text.trim()}',
          correo: _correoControlador.text.trim(),
          contrasena: _esRegistroGoogle ? null : _contrasenaControlador.text,
          datosGoogle: widget.datosGoogle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAutenticacion>();

    return PlantillaAutenticacion(
      motivo: MotivoAutenticacion.abogadoDatos,
      titulo: 'Regístrate como abogado',
      subtitulo: 'Empecemos con tus datos personales.',
      paso: 1,
      totalPasos: 3,
      formulario: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_esRegistroGoogle) ...[
            // El registro con Google solo agiliza este primer paso: el
            // registro de abogado siempre exige completar el paso 2 (info
            // profesional) y el paso 3 (documentos), así que este botón debe
            // navegar al paso 2 y nunca completar el registro directamente.
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
                const SizedBox(height: 24),
                BotonPersonalizado(texto: 'Continuar', onPressed: _continuar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
