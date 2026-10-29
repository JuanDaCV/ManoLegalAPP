import 'package:web/web.dart' as web;

import 'almacen_local_base.dart';

/// Crea el almacén local de Web: `localStorage` del navegador.
AlmacenLocal crearAlmacenLocal() => AlmacenLocalNavegador();

/// Almacén sobre `window.localStorage`.
///
/// El navegador puede bloquear el acceso (cookies y datos de sitios
/// bloqueados, algunos modos privados), y en ese caso hasta obtener
/// `localStorage` lanza una excepción. Por eso cada acceso va en un `try`.
class AlmacenLocalNavegador implements AlmacenLocal {
  @override
  Future<String?> leer(String clave) async {
    try {
      return web.window.localStorage.getItem(clave);
    } catch (_) {
      // Se relanza en vez de devolver `null`: quien lee debe poder distinguir
      // «no hay nada guardado» de «no puedo saberlo».
      throw StateError('El navegador no permite leer el almacenamiento local.');
    }
  }

  @override
  Future<void> escribir(String clave, String valor) async {
    try {
      web.window.localStorage.setItem(clave, valor);
    } catch (_) {
      // Mejor esfuerzo: sin almacenamiento, el recorrido simplemente se
      // volverá a mostrar en la próxima visita.
    }
  }

  @override
  Future<void> borrar(String clave) async {
    try {
      web.window.localStorage.removeItem(clave);
    } catch (_) {
      // Mejor esfuerzo, igual que al escribir.
    }
  }
}
