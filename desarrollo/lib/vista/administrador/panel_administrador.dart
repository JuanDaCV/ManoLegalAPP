import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_administrador.dart';
import '../../controlador/controlador_autenticacion.dart';
import '../../controlador/filtros_administrador.dart';
import '../compartido/barra_superior_post_login.dart';
import '../tema/tema_app.dart';
import 'detalle/detalle_abogado.dart';
import 'estilos_administrador.dart';
import 'navegacion_administrador.dart';
import 'seccion_herramientas_verificacion.dart';
import 'seccion_inicio_administrador.dart';
import 'seccion_verificacion_abogados.dart';

/// Panel de administrador de ManoLegal.
///
/// Tres niveles responsive:
///   - desde 1200 px, sidebar completo;
///   - entre 900 y 1199 px, sidebar reducido a un riel de íconos;
///   - por debajo de 900 px, barra de navegación inferior y detalle a
///     pantalla completa.
///
/// Toda la lógica de datos sigue en [ControladorAdministrador]: este widget
/// solo decide qué se muestra y dónde.
class PanelAdministrador extends StatefulWidget {
  const PanelAdministrador({super.key});

  @override
  State<PanelAdministrador> createState() => _PanelAdministradorState();
}

class _PanelAdministradorState extends State<PanelAdministrador> {
  late final ControladorAdministrador _controlador;
  SeccionAdministrador _seccion = SeccionAdministrador.inicio;

  /// Filtro con el que se abre el listado cuando otra sección lo pide.
  FiltroEstadoAbogado _filtroListado = FiltroEstadoAbogado.todos;
  int _versionFiltro = 0;

  @override
  void initState() {
    super.initState();
    _controlador = context.read<ControladorAdministrador>();
    _controlador.escucharAbogados();
  }

  @override
  void dispose() {
    _controlador.detenerEscucha();
    super.dispose();
  }

  void _irAlListado(FiltroEstadoAbogado filtro) {
    setState(() {
      _seccion = SeccionAdministrador.verificacion;
      _filtroListado = filtro;
      _versionFiltro++;
    });
  }

  /// Abre el detalle como panel lateral en escritorio y como pantalla
  /// completa en móvil. Si el detalle se cierra tras eliminar la cuenta,
  /// devuelve el correo y se muestra el aviso sobre Authentication.
  Future<void> _abrirDetalle(String uid) async {
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    final String? correoEliminado;

    if (anchoPantalla >= EstilosAdmin.corteMovil) {
      correoEliminado = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar detalle',
        barrierColor: const Color(0x660A1930),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (contexto, _, _) => Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: math.min(600, MediaQuery.sizeOf(contexto).width * 0.92),
            height: double.infinity,
            child: Material(
              elevation: 24,
              clipBehavior: Clip.antiAlias,
              child: DetalleAbogado(uid: uid, pantallaCompleta: false),
            ),
          ),
        ),
        transitionBuilder: (_, animacion, _, hijo) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animacion, curve: Curves.easeOutCubic)),
          child: hijo,
        ),
      );
    } else {
      correoEliminado = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => DetalleAbogado(uid: uid, pantallaCompleta: true)),
      );
    }

    if (correoEliminado != null && mounted) _mostrarAvisoAuthPendiente(correoEliminado);
  }

  /// El SDK cliente de Firebase no puede borrar la cuenta de Authentication
  /// de otro usuario: esa operación requiere el Admin SDK. Por eso el panel
  /// borra los datos y los archivos, y avisa que la cuenta de inicio de
  /// sesión queda pendiente de borrado manual en la consola.
  void _mostrarAvisoAuthPendiente(String correo) {
    showDialog<void>(
      context: context,
      builder: (avisoContext) => AlertDialog(
        title: const Text('Cuenta eliminada parcialmente'),
        content: Text(
          'Se borraron los datos, el perfil público y los documentos de $correo.\n\n'
          'La cuenta de inicio de sesión debe eliminarse manualmente en '
          'Firebase Console → Authentication.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(avisoContext), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _cerrarSesion() => context.read<ControladorAutenticacion>().cerrarSesion();

  @override
  Widget build(BuildContext context) {
    // IndexedStack conserva la búsqueda, los filtros y el desplazamiento de
    // cada sección al cambiar entre ellas.
    final cuerpo = IndexedStack(
      index: _seccion.index,
      children: [
        SeccionInicioAdministrador(
          onRevisarPendientes: () => _irAlListado(FiltroEstadoAbogado.pendientes),
          onAbrirDetalle: _abrirDetalle,
        ),
        SeccionVerificacionAbogados(
          filtroInicial: _filtroListado,
          versionFiltro: _versionFiltro,
          onAbrirDetalle: _abrirDetalle,
        ),
        const SeccionHerramientasVerificacion(),
      ],
    );

    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth >= EstilosAdmin.corteMovil) {
          return Scaffold(
            backgroundColor: ColoresApp.grisClaro,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SidebarAdministrador(
                  seccionActual: _seccion,
                  compacto: restricciones.maxWidth < EstilosAdmin.corteSidebarCompleto,
                  correoAdministrador:
                      FirebaseAuth.instance.currentUser?.email ?? ControladorAutenticacion.correoAdministrador,
                  onSeleccionar: (seccion) => setState(() => _seccion = seccion),
                  onCerrarSesion: _cerrarSesion,
                ),
                Expanded(child: cuerpo),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: ColoresApp.grisClaro,
          appBar: AppBar(
            title: const MarcaManoLegal(colorTexto: ColoresApp.blanco),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout_rounded),
                onPressed: _cerrarSesion,
              ),
            ],
          ),
          body: cuerpo,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _seccion.index,
            onDestinationSelected: (indice) => setState(() => _seccion = SeccionAdministrador.values[indice]),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: 'Abogados',
              ),
              NavigationDestination(
                icon: Icon(Icons.policy_outlined),
                selectedIcon: Icon(Icons.policy),
                label: 'Herramientas',
              ),
            ],
          ),
        );
      },
    );
  }
}
