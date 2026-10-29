import 'package:flutter/material.dart';

import '../tema/tema_app.dart';
import '../utilidades/validadores.dart';
import 'campo_texto_personalizado.dart';

/// Separador "o ... con" (línea + texto + línea), usado en las pantallas de
/// registro que ofrecen continuar con un proveedor externo antes del formulario.
class SeparadorTexto extends StatelessWidget {
  final String texto;

  const SeparadorTexto({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final colorLinea = ColoresApp.grisTexto.withValues(alpha: 0.3);
    return Row(
      children: [
        Expanded(child: Divider(color: colorLinea)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(texto, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
        ),
        Expanded(child: Divider(color: colorLinea)),
      ],
    );
  }
}

/// Campos de datos personales comunes al registro de cliente y al paso 1 del
/// registro de abogado: nombre, apellido, fecha de nacimiento y celular
/// colombiano. Agrupa solo presentación; la validación sigue viviendo en
/// [validadores.dart] y el estado en la pantalla que la usa.
class CamposDatosPersonales extends StatelessWidget {
  final TextEditingController nombreControlador;
  final TextEditingController apellidoControlador;
  final TextEditingController telefonoControlador;
  final DateTime? fechaNacimiento;
  final VoidCallback onSeleccionarFecha;

  const CamposDatosPersonales({
    super.key,
    required this.nombreControlador,
    required this.apellidoControlador,
    required this.telefonoControlador,
    required this.fechaNacimiento,
    required this.onSeleccionarFecha,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = fechaNacimiento;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTextoPersonalizado(
          etiqueta: 'Nombre',
          controlador: nombreControlador,
          validador: validarCampoRequerido,
        ),
        const SizedBox(height: 16),
        CampoTextoPersonalizado(
          etiqueta: 'Apellido',
          controlador: apellidoControlador,
          validador: validarCampoRequerido,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            fecha == null ? 'Fecha de nacimiento' : 'Nacimiento: ${fecha.day}/${fecha.month}/${fecha.year}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: onSeleccionarFecha,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Padding(padding: EdgeInsets.only(right: 8), child: Text('+57')),
            Expanded(
              child: CampoTextoPersonalizado(
                etiqueta: 'Celular',
                controlador: telefonoControlador,
                validador: validarTelefonoColombiano,
                tecladoTipo: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
