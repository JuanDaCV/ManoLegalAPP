import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_perfil_publico.dart';
import '../../modelo/modelo_perfil_abogado.dart';
import '../tema/tema_app.dart';
import 'plantilla_post_login.dart';
import 'widgets/perfil/acciones_perfil.dart';
import 'widgets/perfil/bloque_perfil.dart';
import 'widgets/perfil/cabecera_perfil.dart';
import 'widgets/perfil/formulario_nueva_resena.dart';
import 'widgets/perfil/seccion_experiencia.dart';
import 'widgets/perfil/seccion_redes_sociales.dart';
import 'widgets/perfil/seccion_resenas.dart';
import 'widgets/perfil/seccion_sobre_mi.dart';
import 'widgets/perfil/seccion_ubicacion.dart';

/// Visualizador de perfil público de un abogado: la pantalla a la que llega
/// un cliente al pulsar "Ver perfil" desde una tarjeta de resultado del
/// buscador. Siempre de solo lectura (`editable: false` en todos los
/// bloques): la edición del perfil solo existe en el panel del propio
/// abogado (ver `SeccionMiPerfil`).
///
/// Los datos provienen de `perfilesPublicosAbogados/{uid}`, nunca del
/// documento privado del abogado.
class PantallaPerfilAbogado extends StatefulWidget {
  final String uid;

  const PantallaPerfilAbogado({super.key, required this.uid});

  @override
  State<PantallaPerfilAbogado> createState() => _PantallaPerfilAbogadoState();
}

class _PantallaPerfilAbogadoState extends State<PantallaPerfilAbogado> {
  late final ControladorPerfilPublico _controlador;

  @override
  void initState() {
    super.initState();
    _controlador = ControladorPerfilPublico();
    _controlador.cargar(widget.uid);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ControladorPerfilPublico>.value(
      value: _controlador,
      child: Scaffold(
        backgroundColor: ColoresApp.grisClaro,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controlador,
            builder: (context, _) {
              final perfil = _controlador.perfil;
              if (_controlador.estado == EstadoPerfilPublico.encontrado && perfil != null) {
                return _construirPerfil(perfil);
              }
              return _construirEstadoSimple();
            },
          ),
        ),
      ),
    );
  }

  /// Enlace de vuelta, presente en todos los estados para que la pantalla
  /// nunca deje al usuario sin salida.
  Widget get _botonVolver => TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Volver a resultados'),
      );

  Widget _construirEstadoSimple() {
    final Widget contenido;
    switch (_controlador.estado) {
      case EstadoPerfilPublico.cargando:
        contenido = const CircularProgressIndicator();
      case EstadoPerfilPublico.noAutenticado:
        contenido = const _MensajeCentral(
          icono: Icons.lock_outline,
          titulo: 'Inicia sesión para ver este perfil',
          detalle: 'Los perfiles de abogados solo están disponibles para usuarios registrados.',
        );
      case EstadoPerfilPublico.noEncontrado:
        contenido = const _MensajeCentral(
          icono: Icons.person_search,
          titulo: 'No encontramos este perfil',
          detalle: 'Es posible que el abogado ya no esté disponible en el directorio.',
        );
      case EstadoPerfilPublico.error:
        contenido = _MensajeCentral(
          icono: Icons.cloud_off,
          titulo: 'No se pudo cargar el perfil',
          detalle: _controlador.mensajeError ?? '',
          onReintentar: () => _controlador.cargar(widget.uid),
        );
      case EstadoPerfilPublico.encontrado:
        contenido = const SizedBox.shrink();
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(padding: const EdgeInsets.all(16), child: _botonVolver),
        ),
        Expanded(
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: contenido),
          ),
        ),
      ],
    );
  }

  Widget _construirPerfil(ModeloPerfilAbogado perfil) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esEscritorio = constraints.maxWidth >= anchoEscritorioPostLogin;

        final columnaContacto = Column(
          children: [
            BloquePerfil(
              titulo: 'Contacto',
              icono: Icons.contact_phone_outlined,
              child: AccionesPerfil(
                telefonoContacto: perfil.telefonoContacto,
                correoContacto: perfil.correoContacto,
                nombreAbogado: perfil.nombreCompleto,
              ),
            ),
            const SizedBox(height: 20),
            SeccionRedesSociales(perfil: perfil, esEscritorio: esEscritorio, editable: false),
            const SizedBox(height: 20),
            SeccionUbicacion(perfil: perfil, esEscritorio: esEscritorio, editable: false),
          ],
        );

        final columnaContenido = Column(
          children: [
            SeccionSobreMi(sobreMi: perfil.sobreMi, esEscritorio: esEscritorio, editable: false),
            const SizedBox(height: 20),
            SeccionExperiencia(experiencia: perfil.experiencia, esEscritorio: esEscritorio, editable: false),
            const SizedBox(height: 20),
            SeccionResenas(resenas: perfil.resenas, promedio: perfil.calificacion, editable: false),
            const SizedBox(height: 20),
            const FormularioNuevaResena(),
          ],
        );

        final contenido = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _botonVolver,
            const SizedBox(height: 4),
            CabeceraPerfil(perfil: perfil, esEscritorio: esEscritorio, editable: false),
            const SizedBox(height: 20),
            if (esEscritorio)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: columnaContacto),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: columnaContenido),
                ],
              )
            else
              Column(children: [columnaContacto, const SizedBox(height: 20), columnaContenido]),
          ],
        );

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: esEscritorio ? 32 : 16, vertical: 16),
          child: esEscritorio
              ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: contenido))
              : contenido,
        );
      },
    );
  }
}

/// Mensaje centrado reutilizado por los estados sin perfil que mostrar.
class _MensajeCentral extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback? onReintentar;

  const _MensajeCentral({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 40, color: ColoresApp.grisTexto),
        const SizedBox(height: 12),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ColoresApp.azulTurquiOscuro),
        ),
        if (detalle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
          ),
        ],
        if (onReintentar != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ],
    );
  }
}
