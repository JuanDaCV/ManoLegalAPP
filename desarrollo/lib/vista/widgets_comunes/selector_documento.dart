import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../controlador/servicio_storage.dart';
import '../../modelo/modelo_archivo_adjunto.dart';
import '../tema/tema_app.dart';

/// Firma de los primeros bytes de un PDF válido: "%PDF-".
const List<int> _firmaPdf = [0x25, 0x50, 0x44, 0x46, 0x2D];

/// Selector de documento PDF reutilizable (cédula, tarjeta profesional, etc.).
/// Siempre trabaja con bytes (`withData: true`) para funcionar igual en Web y nativo.
class SelectorDocumento extends StatefulWidget {
  final String etiqueta;
  final bool esObligatorio;
  final void Function(ModeloArchivoAdjunto archivo) onArchivoSeleccionado;

  const SelectorDocumento({
    super.key,
    required this.etiqueta,
    required this.esObligatorio,
    required this.onArchivoSeleccionado,
  });

  @override
  State<SelectorDocumento> createState() => _SelectorDocumentoState();
}

class _SelectorDocumentoState extends State<SelectorDocumento> {
  String? _nombreArchivo;
  String? _error;

  Future<void> _seleccionarArchivo() async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (archivo == null) return;

    if (!archivo.name.toLowerCase().endsWith('.pdf')) {
      setState(() {
        _error = 'Solo se aceptan archivos PDF';
        _nombreArchivo = null;
      });
      return;
    }

    final bytes = await archivo.readAsBytes();

    if (bytes.length < _firmaPdf.length || !_tieneFirmaPdf(bytes)) {
      setState(() {
        _error = 'El archivo no es un PDF válido';
        _nombreArchivo = null;
      });
      return;
    }

    if (bytes.length > ServicioStorage.tamanioMaximoDocumentoBytes) {
      setState(() {
        _error = 'El archivo supera el máximo de 10 MB';
        _nombreArchivo = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _nombreArchivo = archivo.name;
    });
    widget.onArchivoSeleccionado(
      ModeloArchivoAdjunto(
        nombreArchivo: archivo.name,
        tipoContenido: 'application/pdf',
        tamanio: bytes.length,
        bytes: bytes,
      ),
    );
  }

  bool _tieneFirmaPdf(Uint8List bytes) {
    for (var i = 0; i < _firmaPdf.length; i++) {
      if (bytes[i] != _firmaPdf[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final obligatoriedad = widget.esObligatorio ? '(obligatorio)' : '(opcional)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.etiqueta} $obligatoriedad', style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const Text('PDF, máximo 1 MB', style: TextStyle(color: ColoresApp.grisTexto, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _seleccionarArchivo,
              icon: const Icon(Icons.upload_file),
              label: const Text('Seleccionar archivo'),
            ),
            if (_nombreArchivo != null)
              Chip(
                avatar: const Icon(Icons.check_circle, color: ColoresApp.verdeVerificado, size: 18),
                label: Text(_nombreArchivo!),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
