import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../configuracion/arranque_firebase.dart';
import '../../../../configuracion/configuracion_landing.dart';
import '../../../visitante/panel_visitante.dart';
import '../../pantalla_inicio_sesion.dart';
import '../../pantalla_seleccion_rol.dart';

/// Punto único de navegación de la landing. Las pruebas lo interceptan para
/// registrar el destino sin abrir pantallas ni pestañas.
abstract final class NavegacionLanding {
  @visibleForTesting
  static void Function(String destino)? interceptor;

  /// La landing se dibuja antes de que Firebase termine de arrancar; el
  /// inicio de sesión y el registro sí lo usan, así que se espera a
  /// [ArranqueFirebase.listo] antes de abrirlos.
  static Future<void> irAInicioSesion(BuildContext context) async {
    final captura = interceptor;
    if (captura != null) {
      captura('login');
      return;
    }
    await ArranqueFirebase.listo;
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
    );
  }

  static Future<void> irARegistro(BuildContext context) async {
    final captura = interceptor;
    if (captura != null) {
      captura('registro');
      return;
    }
    await ArranqueFirebase.listo;
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaSeleccionRol()),
    );
  }

  /// Abre el modo visitante: el directorio y las secciones del panel sin
  /// cuenta. También espera a Firebase, porque el directorio lo consulta y
  /// el panel escucha si se inicia sesión.
  static Future<void> irAExplorar(BuildContext context) async {
    final captura = interceptor;
    if (captura != null) {
      captura('explorar');
      return;
    }
    await ArranqueFirebase.listo;
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PanelVisitante()),
    );
  }

  /// Abre [url] en una pestaña nueva. No hace nada si no es una URL https
  /// válida.
  static Future<bool> abrirEnlace(String? url) async {
    if (url == null || !ConfiguracionLanding.esUrlValida(url)) return false;
    final captura = interceptor;
    if (captura != null) {
      captura('externo:$url');
      return true;
    }
    return launchUrl(Uri.parse(url.trim()), webOnlyWindowName: '_blank');
  }
}
