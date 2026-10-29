import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../controlador/controlador_perfil_abogado.dart';
import '../../../../controlador/servicio_storage.dart';
import '../../../../modelo/modelo_archivo_adjunto.dart';
import '../../../../modelo/modelo_perfil_abogado.dart';
import '../../../tema/tema_app.dart';
import '../avatar_abogado.dart';

/// Cabecera del perfil del abogado: foto grande, nombre, insignia de
/// verificación, especialidad, calificación y ubicación general.
///
/// En escritorio la foto va a la izquierda y los datos a la derecha; en
/// móvil se apila con la foto centrada arriba.
class CabeceraPerfil extends StatelessWidget {
  final ModeloPerfilAbogado perfil;
  final bool esEscritorio;
  final bool editable;

  const CabeceraPerfil({super.key, required this.perfil, required this.esEscritorio, required this.editable});

  @override
  Widget build(BuildContext context) {
    final foto = _FotoConCamara(perfil: perfil, tamanio: esEscritorio ? 200 : 160, editable: editable);
    final datos = _DatosCabecera(perfil: perfil, esEscritorio: esEscritorio);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: esEscritorio
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [foto, const SizedBox(width: 28), Expanded(child: datos)],
            )
          : Column(children: [foto, const SizedBox(height: 20), datos]),
    );
  }
}

/// Foto de perfil con, si [editable], un botón circular de cámara
/// superpuesto en una esquina para cambiarla.
///
/// La foto nueva se sube a Cloud Storage y su URL queda guardada en el
/// perfil, así que sobrevive al cierre de la aplicación y se ve tanto en las
/// tarjetas del buscador como en el perfil público.
class _FotoConCamara extends StatelessWidget {
  final ModeloPerfilAbogado perfil;
  final double tamanio;
  final bool editable;

  const _FotoConCamara({required this.perfil, required this.tamanio, required this.editable});

  Future<void> _cambiarFoto(BuildContext context) async {
    final controlador = context.read<ControladorPerfilAbogado>();
    final mensajero = ScaffoldMessenger.of(context);

    final imagen = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (imagen == null) return;

    final bytes = await imagen.readAsBytes();
    if (bytes.length > ServicioStorage.tamanioMaximoFotoBytes) {
      mensajero.showSnackBar(const SnackBar(content: Text('La imagen supera el máximo de 5 MB.')));
      return;
    }

    final esPng = imagen.name.toLowerCase().endsWith('.png');
    final guardado = await controlador.cambiarFotoPerfil(
      ModeloArchivoAdjunto(
        nombreArchivo: imagen.name,
        tipoContenido: esPng ? 'image/png' : 'image/jpeg',
        tamanio: bytes.length,
        bytes: bytes,
      ),
    );
    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          guardado ? 'Foto actualizada.' : controlador.mensajeError ?? 'No se pudo actualizar la foto.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AvatarAbogado(iniciales: perfil.iniciales, fotoUrl: perfil.fotoUrl, tamanio: tamanio),
        if (editable)
          Positioned(
            bottom: -4,
            right: -4,
            child: Material(
              color: ColoresApp.azulTurqui,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _cambiarFoto(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.camera_alt, color: ColoresApp.blanco, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DatosCabecera extends StatelessWidget {
  final ModeloPerfilAbogado perfil;
  final bool esEscritorio;

  const _DatosCabecera({required this.perfil, required this.esEscritorio});

  @override
  Widget build(BuildContext context) {
    final alineacion = esEscritorio ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final alineacionTexto = esEscritorio ? TextAlign.left : TextAlign.center;

    return Column(
      crossAxisAlignment: alineacion,
      children: [
        Text(
          perfil.nombreCompleto,
          textAlign: alineacionTexto,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 24, color: ColoresApp.azulTurquiOscuro),
        ),
        const SizedBox(height: 8),
        if (perfil.verificado) const _InsigniaVerificada(),
        const SizedBox(height: 8),
        Text(perfil.especialidad, textAlign: alineacionTexto, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          alignment: esEscritorio ? WrapAlignment.start : WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            _EstrellasPerfil(calificacion: perfil.calificacion),
            Text(
              '${perfil.calificacion.toStringAsFixed(1)} · ${perfil.cantidadResenas} reseñas',
              style: const TextStyle(fontWeight: FontWeight.w600, color: ColoresApp.azulTurquiOscuro, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: ColoresApp.grisTexto),
            const SizedBox(width: 4),
            Flexible(
              child: Text(perfil.ubicacionGeneral, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
            ),
          ],
        ),
        if (perfil.tarifa != null) ...[
          const SizedBox(height: 10),
          Text(
            'Desde \$${NumberFormat.decimalPattern('es_CO').format(perfil.tarifa)} COP',
            textAlign: alineacionTexto,
            style: const TextStyle(fontWeight: FontWeight.w700, color: ColoresApp.azulTurquiOscuro, fontSize: 15),
          ),
        ],
      ],
    );
  }
}

/// Insignia "Verificada", con candado indicando que el estado lo gestiona
/// ManoLegal.
class _InsigniaVerificada extends StatelessWidget {
  const _InsigniaVerificada();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColoresApp.verdeVerificado.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 15, color: ColoresApp.verdeVerificado),
          const SizedBox(width: 5),
          const Text('Verificada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ColoresApp.verdeVerificado)),
          const SizedBox(width: 5),
          Tooltip(
            message: 'Lo gestiona ManoLegal',
            child: Icon(Icons.lock_outline, size: 13, color: ColoresApp.verdeVerificado.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// Fila de 5 estrellas (llenas/media/vacías) en dorado, según [calificacion].
class _EstrellasPerfil extends StatelessWidget {
  final double calificacion;

  const _EstrellasPerfil({required this.calificacion});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (indice) {
        final valorEstrella = indice + 1;
        final IconData icono;
        if (calificacion >= valorEstrella) {
          icono = Icons.star;
        } else if (calificacion >= valorEstrella - 0.5) {
          icono = Icons.star_half;
        } else {
          icono = Icons.star_border;
        }
        return Icon(icono, size: 18, color: ColoresApp.dorado);
      }),
    );
  }
}
