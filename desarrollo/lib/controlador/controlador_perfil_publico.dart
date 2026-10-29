import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../modelo/modelo_perfil_abogado.dart';
import '../modelo/modelo_resena.dart';
import 'servicio_firestore.dart';
import 'servicio_perfil_publico.dart';
import 'servicio_resenas.dart';

/// Estado del visualizador de perfil público.
enum EstadoPerfilPublico { cargando, encontrado, noEncontrado, error, noAutenticado }

/// Controlador del perfil público que ve un cliente al abrir "Ver perfil".
class ControladorPerfilPublico extends ChangeNotifier {
  final ServicioPerfilPublico _servicioPerfilPublico;
  final ServicioResenas _servicioResenas;
  final ServicioFirestore _servicioFirestore;

  ControladorPerfilPublico({
    ServicioPerfilPublico? servicioPerfilPublico,
    ServicioResenas? servicioResenas,
    ServicioFirestore? servicioFirestore,
  })  : _servicioPerfilPublico = servicioPerfilPublico ?? ServicioPerfilPublico(),
        _servicioResenas = servicioResenas ?? ServicioResenas(),
        _servicioFirestore = servicioFirestore ?? ServicioFirestore();

  EstadoPerfilPublico estado = EstadoPerfilPublico.cargando;
  String? mensajeError;
  ModeloPerfilAbogado? perfil;

  /// Reseña que el cliente actual ya dejó en este perfil, si existe. Permite
  /// mostrarla para editarla en vez de ofrecer publicar una segunda.
  ModeloResena? miResena;

  String? _uid;

  /// Verdadero si el usuario actual tiene una cuenta de cliente y no es el
  /// propio abogado del perfil.
  ///
  /// Las reglas de Firestore imponen las dos condiciones del lado del
  /// servidor. Aquí se comprueban también para no mostrarle el formulario a
  /// alguien que después va a recibir un rechazo de permisos: por ejemplo,
  /// un abogado mirando el perfil de un colega.
  bool get puedeResenar {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null || perfil == null) return false;
    if (usuario.uid == perfil!.uid) return false;
    return _esCliente;
  }

  bool _esCliente = false;

  Future<void> cargar(String uid) async {
    _uid = uid;
    estado = EstadoPerfilPublico.cargando;
    mensajeError = null;
    notifyListeners();

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      estado = EstadoPerfilPublico.noAutenticado;
      notifyListeners();
      return;
    }

    try {
      final publico = await _servicioPerfilPublico.obtener(uid);
      if (publico == null) {
        estado = EstadoPerfilPublico.noEncontrado;
        notifyListeners();
        return;
      }

      final resenas = await _servicioResenas.obtenerDeAbogado(uid);
      perfil = ModeloPerfilAbogado.desdePerfilPublico(publico, resenas: resenas);
      miResena = await _servicioResenas.obtenerDeCliente(
        abogadoUid: uid,
        clienteUid: usuario.uid,
      );
      // Solo quien tiene documento en `clientes` puede reseñar. Es la misma
      // condición que aplica la regla de Firestore.
      _esCliente = usuario.uid != uid && await _servicioFirestore.obtenerCliente(usuario.uid) != null;

      estado = EstadoPerfilPublico.encontrado;
      notifyListeners();
    } catch (e) {
      estado = EstadoPerfilPublico.error;
      mensajeError = 'No se pudo cargar el perfil: $e';
      notifyListeners();
    }
  }

  /// Publica o reemplaza la reseña del cliente actual.
  ///
  /// Devuelve `null` si se publicó, o el mensaje de error a mostrar.
  ///
  /// El promedio y la cantidad NO se actualizan aquí. Los mantiene una Cloud
  /// Function con el Admin SDK, y las reglas prohíben a todo cliente
  /// escribirlos. Por eso, tras publicar, se recarga el perfil: la reseña
  /// nueva ya aparece en la lista aunque el agregado tarde un segundo más en
  /// llegar. Calcular el promedio en el widget daría un número que no es el
  /// que guarda la base.
  Future<String?> publicarResena({required int calificacion, required String comentario}) async {
    final usuario = FirebaseAuth.instance.currentUser;
    final perfilActual = perfil;
    if (usuario == null) return 'Debes iniciar sesión para dejar una reseña.';
    if (perfilActual == null) return 'El perfil todavía no terminó de cargar.';

    final error = validarResena(
      calificacion: calificacion,
      comentario: comentario,
      abogadoUid: perfilActual.uid,
      clienteUid: usuario.uid,
    );
    if (error != null) return error;

    try {
      await _servicioResenas.publicar(
        ModeloResena(
          abogadoUid: perfilActual.uid,
          clienteUid: usuario.uid,
          autor: (usuario.displayName ?? '').trim().isEmpty ? 'Cliente' : usuario.displayName!,
          calificacion: calificacion,
          comentario: comentario.trim(),
          fecha: DateTime.now(),
        ),
      );
      await cargar(_uid ?? perfilActual.uid);
      return null;
    } catch (e) {
      return 'No se pudo publicar tu reseña: $e';
    }
  }
}
