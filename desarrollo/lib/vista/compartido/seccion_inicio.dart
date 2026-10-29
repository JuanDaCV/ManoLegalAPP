import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../controlador/servicio_perfil_publico.dart';
import '../../modelo/modelo_resultado_abogado.dart';
import 'widgets/bienvenida_post_login.dart';
import 'widgets/bloque_video_introductorio.dart';
import 'widgets/buscador_abogados.dart';

/// Primera sección del panel post-login (cliente o abogado): bienvenida,
/// video introductorio y buscador de abogados. El visitante web la reutiliza
/// tal cual, con un saludo neutro y el buscador sobre la proyección pública.
class SeccionInicio extends StatelessWidget {
  final String nombre;
  final bool esEscritorio;

  /// Subtítulo de la bienvenida. Si es `null`, [BienvenidaPostLogin] usa su
  /// texto por defecto (pensado para el cliente).
  final String? subtituloBienvenida;

  /// Título de la bienvenida. Si es `null`, [BienvenidaPostLogin] saluda por
  /// [nombre].
  final String? titulo;

  /// Servicio del buscador. Si es `null`, el buscador usa el de siempre.
  final ServicioPerfilPublico? servicioPerfilPublico;

  /// «Ver perfil» de cada tarjeta. Si es `null`, abre el perfil completo.
  final void Function(ModeloResultadoAbogado abogado)? alVerPerfil;

  /// Permite a las pruebas reemplazar el video: el real necesita la
  /// plataforma de video, que no existe en `flutter test`.
  @visibleForTesting
  final VideoPlayerController Function()? crearControladorVideo;

  const SeccionInicio({
    super.key,
    required this.nombre,
    required this.esEscritorio,
    this.subtituloBienvenida,
    this.titulo,
    this.servicioPerfilPublico,
    this.alVerPerfil,
    this.crearControladorVideo,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = Padding(
      padding: EdgeInsets.symmetric(horizontal: esEscritorio ? 32 : 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BienvenidaPostLogin(
            nombre: nombre,
            esEscritorio: esEscritorio,
            subtitulo: subtituloBienvenida,
            titulo: titulo,
          ),
          const SizedBox(height: 24),
          BloqueVideoIntroductorio(crearControlador: crearControladorVideo),
          const SizedBox(height: 32),
          BuscadorAbogados(
            esEscritorio: esEscritorio,
            servicioPerfilPublico: servicioPerfilPublico,
            alVerPerfil: alVerPerfil,
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      child: esEscritorio
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: contenido))
          : contenido,
    );
  }
}
