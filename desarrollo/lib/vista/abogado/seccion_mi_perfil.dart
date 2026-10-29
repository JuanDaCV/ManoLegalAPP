import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_perfil_abogado.dart';
import '../../modelo/modelo_paso_recorrido.dart';
import '../compartido/widgets/perfil/acciones_perfil.dart';
import '../compartido/widgets/perfil/bloque_perfil.dart';
import '../compartido/widgets/perfil/cabecera_perfil.dart';
import '../compartido/widgets/perfil/seccion_datos_basicos.dart';
import '../compartido/widgets/perfil/seccion_experiencia.dart';
import '../compartido/widgets/perfil/seccion_redes_sociales.dart';
import '../compartido/widgets/perfil/seccion_resenas.dart';
import '../compartido/widgets/perfil/seccion_sobre_mi.dart';
import '../compartido/widgets/perfil/seccion_ubicacion.dart';
import '../compartido/widgets/recorrido/ambito_recorrido.dart';
import '../tema/tema_app.dart';
import 'estado_error_perfil.dart';

/// Sección "Mi perfil" del panel del abogado: el perfil completo que verán
/// los clientes, con edición en línea de los campos que le corresponden al
/// abogado (los demás los gestiona ManoLegal).
///
/// Los datos provienen del documento privado `abogados/{uid}` a través de
/// [ControladorPerfilAbogado]; cada edición se persiste en Firestore.
class SeccionMiPerfil extends StatelessWidget {
  final bool esEscritorio;

  const SeccionMiPerfil({super.key, required this.esEscritorio});

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorPerfilAbogado>();
    final perfil = controlador.perfil;

    if (controlador.estado == EstadoPerfilAbogado.cargando || perfil == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
    }
    if (controlador.estado == EstadoPerfilAbogado.error) {
      return EstadoErrorPerfil(controlador: controlador);
    }

    final columnaIzquierda = Column(
      children: [
        SeccionDatosBasicos(perfil: perfil, esEscritorio: esEscritorio, editable: true),
        const SizedBox(height: 20),
        SeccionUbicacion(perfil: perfil, esEscritorio: esEscritorio, editable: true),
        const SizedBox(height: 20),
        SeccionRedesSociales(perfil: perfil, esEscritorio: esEscritorio, editable: true),
      ],
    );

    // Las marcas del recorrido guiado de Mi perfil se ponen aquí, al
    // usarlos, y no dentro de los bloques: esos se comparten con el perfil
    // público, que no tiene recorrido.
    final columnaDerecha = Column(
      children: [
        MarcaRecorrido(
          id: MarcaRecorridoId.perfilSobreMi,
          child: SeccionSobreMi(sobreMi: perfil.sobreMi, esEscritorio: esEscritorio, editable: true),
        ),
        const SizedBox(height: 20),
        MarcaRecorrido(
          id: MarcaRecorridoId.perfilExperiencia,
          child: SeccionExperiencia(experiencia: perfil.experiencia, esEscritorio: esEscritorio, editable: true),
        ),
        const SizedBox(height: 20),
        SeccionResenas(resenas: perfil.resenas, promedio: perfil.calificacion, editable: true),
      ],
    );

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Encabezado(esEscritorio: esEscritorio),
        const SizedBox(height: 20),
        MarcaRecorrido(
          id: MarcaRecorridoId.perfilCabecera,
          child: CabeceraPerfil(perfil: perfil, esEscritorio: esEscritorio, editable: true),
        ),
        const SizedBox(height: 20),
        // Sin IntrinsicHeight: con alineación `start` no iguala alturas, y
        // obligaría a medir dos veces todo el contenido de las columnas.
        if (esEscritorio)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: columnaIzquierda),
              const SizedBox(width: 20),
              Expanded(child: columnaDerecha),
            ],
          )
        else
          Column(children: [columnaIzquierda, const SizedBox(height: 20), columnaDerecha]),
        const SizedBox(height: 20),
        MarcaRecorrido(
          id: MarcaRecorridoId.perfilContacto,
          child: BloquePerfil(
            titulo: 'Así verán los clientes tus opciones de contacto',
            icono: Icons.visibility_outlined,
            child: AccionesPerfil(
              telefonoContacto: perfil.telefonoContacto,
              correoContacto: perfil.correoContacto,
              nombreAbogado: perfil.nombreCompleto,
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: esEscritorio ? 32 : 16, vertical: 24),
      child: esEscritorio
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: contenido))
          : contenido,
    );
  }
}

class _Encabezado extends StatelessWidget {
  final bool esEscritorio;

  const _Encabezado({required this.esEscritorio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi perfil',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 24, color: ColoresApp.azulTurquiOscuro),
        ),
        const SizedBox(height: 8),
        // Marca de arranque del recorrido guiado de Mi perfil: solo existe
        // con el perfil ya cargado.
        MarcaRecorrido(
          id: MarcaRecorridoId.perfilLeyenda,
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: const [
              _LeyendaIcono(icono: Icons.edit_outlined, texto: 'Lo editas tú'),
              _LeyendaIcono(icono: Icons.lock_outline, texto: 'Lo gestiona ManoLegal'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeyendaIcono extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _LeyendaIcono({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: ColoresApp.grisTexto),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12)),
      ],
    );
  }
}
