import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../controlador/controlador_administrador.dart';
import '../../../controlador/filtros_administrador.dart';
import '../../../modelo/modelo_abogado.dart';
import '../../../modelo/modelo_archivo_adjunto.dart';
import '../../../modelo/modelo_info_archivo.dart';
import '../../tema/tema_app.dart';
import '../../utilidades/abridor_archivo.dart';
import 'visor_imagen_documento.dart';

/// Los cinco documentos de verificación de un abogado, con su estado real.
///
/// Distingue dos cosas que la versión anterior del panel no separaba: que
/// Firestore registre una ruta para el documento, y que el archivo exista de
/// verdad en Storage. Lo segundo se comprueba leyendo sus metadatos, sin
/// descargarlo.
class DocumentosVerificacion extends StatelessWidget {
  final ModeloAbogado abogado;

  const DocumentosVerificacion({super.key, required this.abogado});

  @override
  Widget build(BuildContext context) {
    final documentacion = estadoDocumentacion(abogado);
    final completa = documentacion.completa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              completa ? Icons.task_alt_rounded : Icons.error_outline_rounded,
              size: 18,
              color: completa ? ColoresApp.verdeVerificado : ColoresApp.dorado,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${documentacion.obligatoriosCargados} de ${EstadoDocumentacion.obligatoriosTotal} obligatorios '
                'registrados · Diploma: ${documentacion.diplomaCargado ? 'cargado' : 'no cargado'}',
                style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final documento in documentosDeVerificacion(abogado)) ...[
          _FilaDocumento(key: ValueKey('${abogado.uid}-${documento.etiqueta}'), documento: documento),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

enum _EstadoArchivo { noCargado, comprobando, disponible, noEncontrado, sinComprobar }

class _FilaDocumento extends StatefulWidget {
  final DocumentoVerificacion documento;

  const _FilaDocumento({super.key, required this.documento});

  @override
  State<_FilaDocumento> createState() => _FilaDocumentoState();
}

class _FilaDocumentoState extends State<_FilaDocumento> {
  /// Se guarda para no volver a consultar Storage en cada reconstrucción:
  /// el detalle se reconstruye con cada cambio del stream en tiempo real.
  Future<ModeloInfoArchivo?>? _info;
  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    _consultarInfo();
  }

  @override
  void didUpdateWidget(_FilaDocumento anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.documento.ruta != widget.documento.ruta) _consultarInfo();
  }

  void _consultarInfo() {
    final ruta = widget.documento.ruta;
    _info = widget.documento.tieneRuta
        ? context.read<ControladorAdministrador>().obtenerInfoDocumento(ruta!)
        : null;
  }

  /// Mismo flujo que el panel anterior: descargar con `obtenerArchivo()` y
  /// abrir con `abrirArchivo()`, informando si algo falla. Las imágenes se
  /// muestran además en un visor interno.
  Future<void> _verDocumento() async {
    final ruta = widget.documento.ruta;
    if (ruta == null) return;
    final administrador = context.read<ControladorAdministrador>();
    final mensajero = ScaffoldMessenger.of(context);

    // En Web, la pestaña se reserva ahora, antes de cualquier espera: la
    // descarga puede tardar más de lo que el navegador tolera entre el clic
    // y la apertura de una ventana. Fuera de Web no hace nada.
    reservarPestanaDocumento();

    setState(() => _abriendo = true);
    ModeloArchivoAdjunto? archivo;
    try {
      archivo = await administrador.obtenerArchivo(ruta);
    } catch (_) {
      archivo = null;
    }
    if (!mounted) {
      cancelarPestanaReservada();
      return;
    }
    setState(() => _abriendo = false);

    if (archivo == null) {
      cancelarPestanaReservada();
      mensajero.showSnackBar(const SnackBar(content: Text('No se pudo abrir el documento.')));
      return;
    }
    if (archivo.tipoContenido.startsWith('image/')) {
      cancelarPestanaReservada();
      await mostrarVisorImagenDocumento(context, titulo: widget.documento.etiqueta, archivo: archivo);
      return;
    }
    try {
      await abrirArchivo(archivo);
    } catch (_) {
      mensajero.showSnackBar(const SnackBar(content: Text('No se pudo abrir el documento.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final documento = widget.documento;

    return FutureBuilder<ModeloInfoArchivo?>(
      future: _info,
      builder: (context, instantanea) {
        final _EstadoArchivo estado;
        if (!documento.tieneRuta) {
          estado = _EstadoArchivo.noCargado;
        } else if (instantanea.connectionState != ConnectionState.done) {
          estado = _EstadoArchivo.comprobando;
        } else if (instantanea.hasError) {
          estado = _EstadoArchivo.sinComprobar;
        } else if (instantanea.data == null) {
          estado = _EstadoArchivo.noEncontrado;
        } else {
          estado = _EstadoArchivo.disponible;
        }
        final info = instantanea.data;
        final puedeVer = documento.tieneRuta && estado != _EstadoArchivo.noEncontrado && !_abriendo;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColoresApp.blanco,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _colorBorde(estado)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColoresApp.azulTurqui.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconoTipo(info), color: ColoresApp.azulTurqui, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              documento.etiqueta,
                              style: const TextStyle(
                                color: ColoresApp.azulTurquiOscuro,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            _EtiquetaObligatoriedad(obligatorio: documento.obligatorio),
                          ],
                        ),
                        const SizedBox(height: 5),
                        _LineaEstado(estado: estado, obligatorio: documento.obligatorio),
                        if (info != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            info.nombreArchivo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 12.5),
                          ),
                          Text(
                            _describir(info),
                            style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (documento.tieneRuta) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: puedeVer ? _verDocumento : null,
                    icon: _abriendo
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(_abriendo ? 'Abriendo…' : 'Ver documento'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side: BorderSide(color: ColoresApp.azulTurqui.withValues(alpha: 0.4)),
                      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _describir(ModeloInfoArchivo info) {
    final tipo = info.esPdf
        ? 'PDF'
        : info.esImagen
            ? 'Imagen'
            : info.tipoContenido;
    final partes = [tipo, formatearTamanio(info.tamanio)];
    final fecha = info.fechaSubida;
    if (fecha != null) partes.add('subido el ${DateFormat('dd/MM/yyyy').format(fecha.toLocal())}');
    return partes.join(' · ');
  }

  static IconData _iconoTipo(ModeloInfoArchivo? info) {
    if (info == null) return Icons.description_outlined;
    if (info.esPdf) return Icons.picture_as_pdf_outlined;
    if (info.esImagen) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  static Color _colorBorde(_EstadoArchivo estado) {
    switch (estado) {
      case _EstadoArchivo.disponible:
        return ColoresApp.verdeVerificado.withValues(alpha: 0.3);
      case _EstadoArchivo.noEncontrado:
        return ColoresApp.rojoNoVerificado.withValues(alpha: 0.35);
      case _EstadoArchivo.noCargado:
      case _EstadoArchivo.comprobando:
      case _EstadoArchivo.sinComprobar:
        return ColoresApp.grisTexto.withValues(alpha: 0.18);
    }
  }
}

class _LineaEstado extends StatelessWidget {
  final _EstadoArchivo estado;
  final bool obligatorio;

  const _LineaEstado({required this.estado, required this.obligatorio});

  @override
  Widget build(BuildContext context) {
    final Widget icono;
    final String texto;
    final Color color;

    switch (estado) {
      case _EstadoArchivo.comprobando:
        icono = const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1.8));
        texto = 'Comprobando en Storage…';
        color = ColoresApp.grisTexto;
      case _EstadoArchivo.disponible:
        icono = const Icon(Icons.check_circle_rounded, size: 15, color: ColoresApp.verdeVerificado);
        texto = 'Disponible en Storage';
        color = ColoresApp.verdeVerificado;
      case _EstadoArchivo.noEncontrado:
        icono = const Icon(Icons.error_outline_rounded, size: 15, color: ColoresApp.rojoNoVerificado);
        texto = 'Registrado en Firestore, pero el archivo no existe en Storage';
        color = ColoresApp.rojoNoVerificado;
      case _EstadoArchivo.sinComprobar:
        icono = const Icon(Icons.help_outline_rounded, size: 15, color: ColoresApp.grisTexto);
        texto = 'No se pudo comprobar el archivo. Puedes intentar abrirlo.';
        color = ColoresApp.grisTexto;
      case _EstadoArchivo.noCargado:
        icono = Icon(
          obligatorio ? Icons.error_outline_rounded : Icons.remove_circle_outline_rounded,
          size: 15,
          color: obligatorio ? ColoresApp.rojoNoVerificado : ColoresApp.grisTexto,
        );
        texto = obligatorio ? 'No cargado · falta un documento obligatorio' : 'No cargado';
        color = obligatorio ? ColoresApp.rojoNoVerificado : ColoresApp.grisTexto;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: icono),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _EtiquetaObligatoriedad extends StatelessWidget {
  final bool obligatorio;

  const _EtiquetaObligatoriedad({required this.obligatorio});

  @override
  Widget build(BuildContext context) {
    final color = obligatorio ? ColoresApp.azulTurqui : ColoresApp.grisTexto;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        obligatorio ? 'Obligatorio' : 'Opcional',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
