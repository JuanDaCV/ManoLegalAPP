import 'package:flutter/material.dart';

import '../../../controlador/filtros_administrador.dart';
import '../../../modelo/modelo_abogado.dart';
import '../../tema/tema_app.dart';
import '../estilos_administrador.dart';
import 'boton_copiar.dart';
import 'chip_estado_verificacion.dart';

/// Versión en tarjeta de una fila de la tabla, para tablets y móviles.
/// Muestra los mismos datos que la tabla, apilados, con el botón de detalle
/// a lo ancho para que sea fácil de tocar.
class TarjetaAbogadoAdmin extends StatelessWidget {
  final ModeloAbogado abogado;
  final VoidCallback onVerDetalle;

  const TarjetaAbogadoAdmin({super.key, required this.abogado, required this.onVerDetalle});

  @override
  Widget build(BuildContext context) {
    final documentacion = estadoDocumentacion(abogado);
    final textoDocumentos = 'Documentos: ${documentacion.obligatoriosCargados} de '
        '${EstadoDocumentacion.obligatoriosTotal} obligatorios'
        '${documentacion.diplomaCargado ? ' · Diploma' : ''}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: EstilosAdmin.tarjeta,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onVerDetalle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${abogado.nombre} ${abogado.apellido}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ColoresApp.azulTurquiOscuro,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            abogado.especialidad.textoLegible,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ChipEstadoVerificacion(verificado: estaVerificado(abogado)),
                  ],
                ),
                const SizedBox(height: 12),
                _Dato(icono: Icons.mail_outline_rounded, valor: abogado.correo),
                _Dato(icono: Icons.phone_outlined, valor: abogado.telefono),
                _Dato(
                  icono: documentacion.completa ? Icons.task_alt_rounded : Icons.error_outline_rounded,
                  colorIcono: documentacion.completa ? ColoresApp.verdeVerificado : ColoresApp.dorado,
                  valor: textoDocumentos,
                ),
                Row(
                  children: [
                    const Icon(Icons.fingerprint_rounded, size: 16, color: ColoresApp.grisTexto),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'UID ${abreviarUid(abogado.uid)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5),
                      ),
                    ),
                    BotonCopiar(valor: abogado.uid, etiqueta: 'UID'),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onVerDetalle,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Ver detalle'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String valor;
  final Color colorIcono;

  const _Dato({required this.icono, required this.valor, this.colorIcono = ColoresApp.grisTexto});

  @override
  Widget build(BuildContext context) {
    final vacio = valor.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icono, size: 16, color: colorIcono),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vacio ? '—' : valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: vacio ? ColoresApp.grisTexto : ColoresApp.azulTurquiOscuro, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
