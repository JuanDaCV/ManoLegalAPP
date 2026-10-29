import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controlador/servicio_storage.dart';
import '../../modelo/modelo_archivo_adjunto.dart';

/// Selector de foto de perfil reutilizable. Comprime la imagen con
/// `image_picker` antes de leerla, para que quepa cómodamente bajo el
/// límite de 1 MB de un documento de Firestore.
class SelectorFotoPerfil extends StatefulWidget {
  final void Function(ModeloArchivoAdjunto foto) onFotoSeleccionada;

  /// Foto ya elegida antes de mostrar este widget (p. ej. la foto de perfil
  /// de Google, descargada de antemano), para mostrarla ya seleccionada.
  final ModeloArchivoAdjunto? fotoInicial;

  const SelectorFotoPerfil({super.key, required this.onFotoSeleccionada, this.fotoInicial});

  @override
  State<SelectorFotoPerfil> createState() => _SelectorFotoPerfilState();
}

class _SelectorFotoPerfilState extends State<SelectorFotoPerfil> {
  ModeloArchivoAdjunto? _foto;
  String? _error;

  @override
  void initState() {
    super.initState();
    _foto = widget.fotoInicial;
  }

  @override
  void didUpdateWidget(covariant SelectorFotoPerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo adopta la nueva foto inicial si el usuario no eligió ya una a
    // mano, para no pisar su elección si esta llega tarde (p. ej. una
    // descarga de la foto de Google que termina después de que el usuario
    // ya seleccionó otra imagen).
    if (_foto == null && widget.fotoInicial != null && widget.fotoInicial != oldWidget.fotoInicial) {
      _foto = widget.fotoInicial;
    }
  }

  Future<void> _seleccionarFoto() async {
    final imagen = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (imagen == null) return;

    final bytes = await imagen.readAsBytes();
    final nombreMinuscula = imagen.name.toLowerCase();
    final tipoContenido = nombreMinuscula.endsWith('.png') ? 'image/png' : 'image/jpeg';

    if (bytes.length > ServicioStorage.tamanioMaximoFotoBytes) {
      setState(() => _error = 'La imagen supera el máximo de 5 MB');
      return;
    }

    final foto = ModeloArchivoAdjunto(
      nombreArchivo: imagen.name,
      tipoContenido: tipoContenido,
      tamanio: bytes.length,
      bytes: bytes,
    );
    setState(() {
      _error = null;
      _foto = foto;
    });
    widget.onFotoSeleccionada(foto);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto de perfil', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: _foto != null ? MemoryImage(_foto!.bytes) : null,
              child: _foto == null ? const Icon(Icons.person, size: 32) : null,
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _seleccionarFoto,
              child: Text(_foto == null ? 'Elegir foto' : 'Cambiar foto'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    );
  }
}
