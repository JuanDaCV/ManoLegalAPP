import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../modelo/modelo_perfil_abogado.dart';
import '../../../tema/tema_app.dart';
import 'bloque_perfil.dart';

/// Bloque de datos básicos del perfil del abogado: nombre, edad, fecha de
/// nacimiento, especialidad, ubicación y dirección. Es de solo lectura: la
/// edición de ubicación/dirección vive en [SeccionUbicacion].
///
/// [editable] no habilita edición aquí (no hay ningún dato propio del bloque
/// que se edite desde este lugar); se recibe solo por consistencia con el
/// resto de los bloques del perfil.
class SeccionDatosBasicos extends StatelessWidget {
  final ModeloPerfilAbogado perfil;
  final bool esEscritorio;
  final bool editable;

  const SeccionDatosBasicos({super.key, required this.perfil, required this.esEscritorio, required this.editable});

  @override
  Widget build(BuildContext context) {
    // La fecha de nacimiento solo existe cuando el perfil viene del documento
    // privado del abogado. El perfil público no la publica a propósito, así
    // que este bloque tolera su ausencia en lugar de fallar.
    final fecha = perfil.fechaNacimiento;
    final fechaFormateada = fecha == null ? 'No disponible' : DateFormat('dd/MM/yyyy').format(fecha);
    final edad = perfil.edad;

    return BloquePerfil(
      titulo: 'Datos básicos',
      icono: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilaDato(etiqueta: 'Nombre', valor: perfil.nombreCompleto, apilada: !esEscritorio),
          _FilaDato(
            etiqueta: 'Edad',
            valor: edad == null ? 'No disponible' : '$edad años',
            candado: true,
            apilada: !esEscritorio,
          ),
          _FilaDato(etiqueta: 'Fecha de nacimiento', valor: fechaFormateada, apilada: !esEscritorio),
          _FilaDato(etiqueta: 'Especialidad', valor: perfil.especialidad, candado: true, apilada: !esEscritorio),
          _FilaDato(etiqueta: 'Ubicación', valor: perfil.ubicacionGeneral, apilada: !esEscritorio),
          _FilaDato(etiqueta: 'Dirección', valor: perfil.direccion, ultima: true, apilada: !esEscritorio),
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool candado;
  final bool ultima;

  /// En móvil la etiqueta va arriba del valor: con una columna fija de 150 px
  /// para la etiqueta, al valor le quedaría una columna demasiado estrecha.
  final bool apilada;

  const _FilaDato({
    required this.etiqueta,
    required this.valor,
    this.candado = false,
    this.ultima = false,
    this.apilada = false,
  });

  @override
  Widget build(BuildContext context) {
    const estiloEtiqueta = TextStyle(color: ColoresApp.grisTexto, fontSize: 13, fontWeight: FontWeight.w600);
    const estiloValor = TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 15);
    const iconoCandado = Tooltip(
      message: 'Lo gestiona ManoLegal',
      child: Icon(Icons.lock_outline, size: 15, color: ColoresApp.grisTexto),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 14),
      child: apilada
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(etiqueta, style: estiloEtiqueta)),
                    if (candado) ...[const SizedBox(width: 6), iconoCandado],
                  ],
                ),
                const SizedBox(height: 2),
                Text(valor, style: estiloValor),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 150, child: Text(etiqueta, style: estiloEtiqueta)),
                Expanded(child: Text(valor, style: estiloValor)),
                if (candado) iconoCandado,
              ],
            ),
    );
  }
}
