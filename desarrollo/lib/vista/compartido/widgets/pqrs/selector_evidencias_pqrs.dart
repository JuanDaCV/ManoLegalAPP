import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../controlador/servicio_storage.dart';
import '../../../../modelo/modelo_archivo_adjunto.dart';
import '../../../../modelo/modelo_pqrs.dart';
import '../../../tema/tema_app.dart';

/// Firmas de los primeros bytes de cada formato admitido. Son las que
/// deciden el tipo del archivo, no la extensión, que se puede cambiar.
const List<int> _firmaPdf = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
const List<int> _firmaPng = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const List<int> _firmaJpeg = [0xFF, 0xD8, 0xFF];

const List<String> _extensionesPermitidas = ['pdf', 'png', 'jpg', 'jpeg'];

/// Resultado de validar un archivo elegido como evidencia: o el archivo listo
/// para subir, o el mensaje para el usuario.
class ResultadoEvidencia {
  final ModeloArchivoAdjunto? archivo;
  final String? error;

  const ResultadoEvidencia.valido(ModeloArchivoAdjunto this.archivo) : error = null;
  const ResultadoEvidencia.invalido(String this.error) : archivo = null;
}

/// Valida un archivo elegido como evidencia: extensión, tamaño y firma real
/// de PDF, PNG o JPEG. Mismo criterio que `SelectorDocumento` con los PDF,
/// extendido a imágenes.
ResultadoEvidencia validarArchivoEvidencia(String nombreArchivo, Uint8List bytes) {
  final punto = nombreArchivo.lastIndexOf('.');
  final extension = punto == -1 ? '' : nombreArchivo.substring(punto + 1).toLowerCase();
  if (!_extensionesPermitidas.contains(extension)) {
    return const ResultadoEvidencia.invalido('Solo se aceptan archivos PDF, PNG o JPG.');
  }
  if (bytes.isEmpty) {
    return const ResultadoEvidencia.invalido('El archivo está vacío.');
  }
  if (bytes.length > ServicioStorage.tamanioMaximoDocumentoBytes) {
    return const ResultadoEvidencia.invalido('El archivo supera el máximo de 10 MB.');
  }
  final tipoContenido = _tipoContenidoPorFirma(bytes);
  if (tipoContenido == null) {
    return const ResultadoEvidencia.invalido('El archivo no es un PDF o una imagen PNG/JPG válida.');
  }
  return ResultadoEvidencia.valido(ModeloArchivoAdjunto(
    nombreArchivo: nombreArchivo,
    tipoContenido: tipoContenido,
    tamanio: bytes.length,
    bytes: bytes,
  ));
}

String? _tipoContenidoPorFirma(Uint8List bytes) {
  if (_empiezaCon(bytes, _firmaPdf)) return 'application/pdf';
  if (_empiezaCon(bytes, _firmaPng)) return 'image/png';
  if (_empiezaCon(bytes, _firmaJpeg)) return 'image/jpeg';
  return null;
}

bool _empiezaCon(Uint8List bytes, List<int> firma) {
  if (bytes.length < firma.length) return false;
  for (var i = 0; i < firma.length; i++) {
    if (bytes[i] != firma[i]) return false;
  }
  return true;
}

/// Selector de evidencias opcionales para una PQRS: hasta
/// [maximoEvidenciasPqrs] archivos PDF, PNG o JPG de hasta 10 MB cada uno.
///
/// Usa el mismo `file_picker` y la misma lectura en bytes que
/// `SelectorDocumento`, para funcionar igual en Web y en móvil. No comprime
/// las imágenes: una evidencia debe llegar tal como el usuario la eligió.
class SelectorEvidenciasPqrs extends StatefulWidget {
  final List<ModeloArchivoAdjunto> evidencias;
  final ValueChanged<List<ModeloArchivoAdjunto>> onCambio;
  final bool habilitado;

  const SelectorEvidenciasPqrs({
    super.key,
    required this.evidencias,
    required this.onCambio,
    this.habilitado = true,
  });

  @override
  State<SelectorEvidenciasPqrs> createState() => _SelectorEvidenciasPqrsState();
}

class _SelectorEvidenciasPqrsState extends State<SelectorEvidenciasPqrs> {
  String? _error;

  bool get _hayCupo => widget.evidencias.length < maximoEvidenciasPqrs;

  Future<void> _adjuntar() async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _extensionesPermitidas,
    );
    if (archivo == null || !mounted) return;

    final resultado = validarArchivoEvidencia(archivo.name, await archivo.readAsBytes());
    if (!mounted) return;
    if (resultado.error != null) {
      setState(() => _error = resultado.error);
      return;
    }
    setState(() => _error = null);
    widget.onCambio([...widget.evidencias, resultado.archivo!]);
  }

  void _quitar(int indice) {
    setState(() => _error = null);
    widget.onCambio([...widget.evidencias]..removeAt(indice));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidencias (opcional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColoresApp.azulTurquiOscuro),
        ),
        const SizedBox(height: 4),
        const Text(
          'PDF, PNG o JPG · hasta 10 MB por archivo · máximo $maximoEvidenciasPqrs archivos',
          style: TextStyle(color: ColoresApp.grisTexto, fontSize: 12),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < widget.evidencias.length; i++)
          _FilaEvidencia(
            archivo: widget.evidencias[i],
            onQuitar: widget.habilitado ? () => _quitar(i) : null,
          ),
        if (_hayCupo)
          OutlinedButton.icon(
            onPressed: widget.habilitado ? _adjuntar : null,
            icon: const Icon(Icons.attach_file),
            label: const Text('Adjuntar archivo'),
          ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: const TextStyle(color: ColoresApp.rojoNoVerificado, fontSize: 12)),
        ],
      ],
    );
  }
}

class _FilaEvidencia extends StatelessWidget {
  final ModeloArchivoAdjunto archivo;
  final VoidCallback? onQuitar;

  const _FilaEvidencia({required this.archivo, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    final esPdf = archivo.tipoContenido == 'application/pdf';
    final megas = archivo.tamanio / (1024 * 1024);
    final tamanio = megas >= 1
        ? '${megas.toStringAsFixed(1)} MB'
        : '${(archivo.tamanio / 1024).ceil()} KB';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColoresApp.grisClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(esPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, color: ColoresApp.azulTurqui),
          const SizedBox(width: 10),
          Expanded(
            child: Text(archivo.nombreArchivo, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(tamanio, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12)),
          IconButton(
            tooltip: 'Quitar archivo',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onQuitar,
          ),
        ],
      ),
    );
  }
}
