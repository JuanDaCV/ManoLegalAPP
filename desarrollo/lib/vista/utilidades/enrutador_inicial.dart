import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../configuracion/arranque_firebase.dart';
import '../../controlador/controlador_autenticacion.dart';
import '../tema/tema_app.dart';
import '../autenticacion/pantalla_bienvenida_movil.dart';
import '../autenticacion/pantalla_landing_web.dart';
import '../autenticacion/pantalla_seleccion_rol.dart';
import '../abogado/panel_abogado.dart';
import '../administrador/panel_administrador.dart';
import '../cliente/panel_cliente.dart';
import '../widgets_comunes/boton_personalizado.dart';

/// Decide qué pantalla mostrar según el estado de autenticación y el rol resuelto.
class EnrutadorInicial extends StatelessWidget {
  const EnrutadorInicial({super.key});

  @override
  Widget build(BuildContext context) {
    // En la web Firebase termina de arrancar después del primer cuadro. Hasta
    // entonces no hay flujo de sesión (stream null) y se muestra la landing,
    // que no usa Firebase, en la misma posición del árbol: al terminar el
    // arranque no se reconstruye ni pierde su desplazamiento.
    return FutureBuilder<void>(
      future: ArranqueFirebase.listo,
      builder: (context, arranque) {
        final firebaseListo = arranque.connectionState == ConnectionState.done;
        return StreamBuilder<User?>(
          stream: firebaseListo ? FirebaseAuth.instance.authStateChanges() : null,
          builder: (context, instantanea) => _construir(context, instantanea),
        );
      },
    );
  }

  Widget _construir(BuildContext context, AsyncSnapshot<User?> instantanea) {
    final usuario = instantanea.data;
    if (usuario == null) {
      // Quien tenía sesión la última vez espera a saber si sigue
      // iniciada, en lugar de ver la landing un instante.
      final sinRespuestaTodavia = instantanea.connectionState == ConnectionState.none ||
          instantanea.connectionState == ConnectionState.waiting;
      if (ArranqueFirebase.hayIndicioDeSesion && sinRespuestaTodavia) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return kIsWeb ? const PantallaLandingWeb() : const PantallaBienvenidaMovil();
    }

    return Consumer<ControladorAutenticacion>(
      builder: (context, controlador, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => controlador.resolverRol(usuario));

        switch (controlador.rolActual) {
          case RolUsuario.cargando:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case RolUsuario.cliente:
            return const PanelCliente();
          case RolUsuario.abogado:
            return const PanelAbogado();
          case RolUsuario.administrador:
            return const PanelAdministrador();
          case RolUsuario.error:
            return _PantallaEstadoNoResuelto(
              icono: Icons.error_outline,
              mensaje: controlador.mensajeError ?? 'No se pudo cargar tu perfil',
            );
          case RolUsuario.desconocido:
            return _PantallaEstadoNoResuelto(
              icono: Icons.help_outline,
              mensaje: 'Falta completar tu registro',
              textoAccionPrimaria: 'Completar registro',
              accionPrimaria: () => Navigator.push(
                context,
                MaterialPageRoute(
                  // Se autorrellena con los datos de la cuenta ya
                  // autenticada (caso típico: registro abandonado).
                  builder: (_) => PantallaSeleccionRol(
                    datosGoogle: controlador.datosGoogleDelUsuarioActual(),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}

/// Pantalla mostrada cuando no se pudo resolver el rol del usuario ya
/// autenticado: error de red/permisos (con opción de reintentar), o
/// autenticado sin perfil asociado en Firestore todavía, por ejemplo tras
/// registrarse con Google sin terminar el formulario (con opción de
/// completarlo). Siempre ofrece cerrar sesión como salida alternativa.
class _PantallaEstadoNoResuelto extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  /// Acción del botón primario. Por defecto reintenta resolver el rol
  /// (caso de error); se puede reemplazar, por ejemplo, para llevar al
  /// usuario a completar su registro.
  final VoidCallback? accionPrimaria;
  final String textoAccionPrimaria;

  const _PantallaEstadoNoResuelto({
    required this.icono,
    required this.mensaje,
    this.accionPrimaria,
    this.textoAccionPrimaria = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) {
    final controlador = context.read<ControladorAutenticacion>();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 56, color: ColoresApp.grisTexto),
              const SizedBox(height: 16),
              Text(mensaje, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              BotonPersonalizado(
                texto: textoAccionPrimaria,
                onPressed: accionPrimaria ?? () => controlador.reintentarResolverRol(),
              ),
              const SizedBox(height: 12),
              BotonPersonalizado(
                texto: 'Cerrar sesión',
                esPrimario: false,
                onPressed: () => controlador.cerrarSesion(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
