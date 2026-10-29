import 'package:flutter/material.dart';

import '../../../controlador/filtros_administrador.dart';
import '../../../modelo/modelo_abogado.dart';
import '../../tema/tema_app.dart';
import '../estilos_administrador.dart';
import 'boton_copiar.dart';
import 'chip_estado_verificacion.dart';

// Anchos de columna compartidos por la cabecera y las filas, para que
// siempre queden alineadas. Las columnas de texto usan `flex` y cortan con
// puntos suspensivos: la tabla nunca desborda. El texto completo queda en un
// tooltip.
const double _anchoUid = 104;
const double _anchoEstado = 112;
const double _anchoDocumentos = 92;
const double _anchoAccion = 48;
const double _separacion = 12;
const int _flexNombre = 11;
const int _flexApellido = 11;
const int _flexCorreo = 19;
const int _flexTelefono = 12;
const int _flexEspecialidad = 13;

/// Tabla de abogados para escritorio. Nunca muestra contraseñas ni fotos:
/// el foco administrativo es la identidad, el estado y la documentación.
///
/// Es un componente de presentación: recibe la página de abogados ya
/// filtrada y ordenada, y avisa cuál se quiere ver en detalle.
class TablaAbogados extends StatelessWidget {
  final List<ModeloAbogado> abogados;
  final ValueChanged<ModeloAbogado> onVerDetalle;

  const TablaAbogados({super.key, required this.abogados, required this.onVerDetalle});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: EstilosAdmin.tarjeta,
      child: Column(
        children: [
          const _CabeceraTabla(),
          for (var indice = 0; indice < abogados.length; indice++) ...[
            if (indice > 0) const Divider(height: 1, thickness: 1, color: EstilosAdmin.bordeSuave),
            _FilaAbogado(abogado: abogados[indice], onVerDetalle: onVerDetalle),
          ],
        ],
      ),
    );
  }
}

/// Reparte las nueve celdas con los mismos anchos en cabecera y filas.
List<Widget> _celdas({
  required Widget uid,
  required Widget nombre,
  required Widget apellido,
  required Widget correo,
  required Widget telefono,
  required Widget especialidad,
  required Widget estado,
  required Widget documentos,
  required Widget accion,
}) {
  return [
    SizedBox(width: _anchoUid, child: uid),
    const SizedBox(width: _separacion),
    Expanded(flex: _flexNombre, child: nombre),
    const SizedBox(width: _separacion),
    Expanded(flex: _flexApellido, child: apellido),
    const SizedBox(width: _separacion),
    Expanded(flex: _flexCorreo, child: correo),
    const SizedBox(width: _separacion),
    Expanded(flex: _flexTelefono, child: telefono),
    const SizedBox(width: _separacion),
    Expanded(flex: _flexEspecialidad, child: especialidad),
    const SizedBox(width: _separacion),
    SizedBox(width: _anchoEstado, child: estado),
    const SizedBox(width: _separacion),
    SizedBox(width: _anchoDocumentos, child: documentos),
    const SizedBox(width: _separacion),
    SizedBox(width: _anchoAccion, child: accion),
  ];
}

class _CabeceraTabla extends StatelessWidget {
  const _CabeceraTabla();

  @override
  Widget build(BuildContext context) {
    Widget titulo(String texto) =>
        Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis, style: EstilosAdmin.etiquetaColumna);

    return Container(
      color: ColoresApp.grisClaro,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: _celdas(
          uid: titulo('UID'),
          nombre: titulo('NOMBRE'),
          apellido: titulo('APELLIDO'),
          correo: titulo('CORREO'),
          telefono: titulo('TELÉFONO'),
          especialidad: titulo('ESPECIALIDAD'),
          estado: titulo('ESTADO'),
          documentos: titulo('DOCS.'),
          accion: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _FilaAbogado extends StatelessWidget {
  final ModeloAbogado abogado;
  final ValueChanged<ModeloAbogado> onVerDetalle;

  const _FilaAbogado({required this.abogado, required this.onVerDetalle});

  @override
  Widget build(BuildContext context) {
    final documentacion = estadoDocumentacion(abogado);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onVerDetalle(abogado),
        hoverColor: ColoresApp.azulTurqui.withValues(alpha: 0.035),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: _celdas(
              uid: Row(
                children: [
                  Flexible(
                    child: Text(
                      abreviarUid(abogado.uid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5, letterSpacing: 0.2),
                    ),
                  ),
                  BotonCopiar(valor: abogado.uid, etiqueta: 'UID'),
                ],
              ),
              nombre: _CeldaTexto(abogado.nombre, destacada: true),
              apellido: _CeldaTexto(abogado.apellido, destacada: true),
              correo: _CeldaTexto(abogado.correo),
              telefono: _CeldaTexto(abogado.telefono),
              especialidad: _CeldaTexto(abogado.especialidad.textoLegible),
              estado: Align(
                alignment: Alignment.centerLeft,
                child: ChipEstadoVerificacion(verificado: estaVerificado(abogado)),
              ),
              documentos: _CeldaDocumentos(documentacion: documentacion),
              accion: IconButton(
                onPressed: () => onVerDetalle(abogado),
                tooltip: 'Ver detalle',
                icon: const Icon(Icons.chevron_right_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: ColoresApp.azulTurqui.withValues(alpha: 0.07),
                  foregroundColor: ColoresApp.azulTurqui,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CeldaTexto extends StatelessWidget {
  final String texto;
  final bool destacada;

  const _CeldaTexto(this.texto, {this.destacada = false});

  @override
  Widget build(BuildContext context) {
    final vacio = texto.trim().isEmpty;
    final contenido = Text(
      vacio ? '—' : texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: vacio ? ColoresApp.grisTexto : ColoresApp.azulTurquiOscuro,
        fontSize: 13.5,
        fontWeight: destacada ? FontWeight.w600 : FontWeight.w400,
      ),
    );
    if (vacio) return contenido;
    return Tooltip(message: texto, waitDuration: const Duration(milliseconds: 500), child: contenido);
  }
}

class _CeldaDocumentos extends StatelessWidget {
  final EstadoDocumentacion documentacion;

  const _CeldaDocumentos({required this.documentacion});

  @override
  Widget build(BuildContext context) {
    final completa = documentacion.completa;
    return Tooltip(
      message: 'Obligatorios: ${documentacion.obligatoriosCargados} de ${EstadoDocumentacion.obligatoriosTotal}'
          ' · Diploma: ${documentacion.diplomaCargado ? 'cargado' : 'no cargado'}',
      child: Row(
        children: [
          Icon(
            completa ? Icons.task_alt_rounded : Icons.error_outline_rounded,
            size: 16,
            color: completa ? ColoresApp.verdeVerificado : ColoresApp.dorado,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${documentacion.obligatoriosCargados}/${EstadoDocumentacion.obligatoriosTotal}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (documentacion.diplomaCargado) ...[
            const SizedBox(width: 6),
            const Icon(Icons.school_outlined, size: 15, color: ColoresApp.grisTexto),
          ],
        ],
      ),
    );
  }
}
