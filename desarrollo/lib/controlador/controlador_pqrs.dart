import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../modelo/modelo_archivo_adjunto.dart';
import '../modelo/modelo_evidencia_pqrs.dart';
import '../modelo/modelo_pqrs.dart';
import 'servicio_pqrs.dart';
import 'servicio_storage.dart';

/// Etapas del flujo de PQRS tal como las ve el usuario.
enum EtapaPqrs { inicio, formulario, esperandoRadicado, confirmada }

/// Coordina el envío de una PQRS: sube las evidencias, crea el documento y
/// espera el radicado que asigna la Cloud Function.
///
/// El orden garantiza que nunca quede una PQRS a medias: el documento se crea
/// en una sola escritura y solo después de que todas las evidencias subieron.
/// Si algo falla antes, se borran los archivos ya subidos, igual que hace el
/// registro de abogado.
class ControladorPqrs extends ChangeNotifier {
  ControladorPqrs({
    ServicioPqrs? servicioPqrs,
    ServicioStorage? servicioStorage,
    String? Function()? obtenerUid,
    String? Function()? obtenerCorreo,
    this.esperaAntesDeAviso = const Duration(seconds: 45),
  })  : _servicioPqrs = servicioPqrs ?? ServicioPqrs(),
        _servicioStorage = servicioStorage ?? ServicioStorage(),
        _obtenerUid = obtenerUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
        _obtenerCorreo = obtenerCorreo ?? (() => FirebaseAuth.instance.currentUser?.email);

  final ServicioPqrs _servicioPqrs;
  final ServicioStorage _servicioStorage;
  final String? Function() _obtenerUid;
  final String? Function() _obtenerCorreo;

  /// Tiempo tras el cual se avisa que el radicado está tardando más de lo
  /// normal. La espera no se corta: el radicado se muestra si llega después.
  final Duration esperaAntesDeAviso;

  EtapaPqrs etapa = EtapaPqrs.inicio;

  /// Tipo con el que se abre el formulario (el de la tarjeta elegida).
  TipoPqrs? tipoInicial;

  bool enviando = false;
  String? mensajeError;

  /// La PQRS enviada. Tiene radicado cuando [etapa] es [EtapaPqrs.confirmada].
  ModeloPqrs? pqrs;

  bool esperaProlongada = false;

  /// La PQRS quedó registrada, pero no se pudo consultar su radicado.
  String? errorEspera;

  StreamSubscription<ModeloPqrs?>? _suscripcion;
  Timer? _temporizador;
  bool _desechado = false;

  /// Correo de la cuenta autenticada, al que llega la confirmación.
  String? get correoUsuario => _obtenerCorreo();

  void iniciarNueva([TipoPqrs? tipo]) {
    _reiniciar();
    tipoInicial = tipo;
    etapa = EtapaPqrs.formulario;
    _notificar();
  }

  void volverAlInicio() {
    _reiniciar();
    etapa = EtapaPqrs.inicio;
    _notificar();
  }

  Future<void> enviar({
    required TipoPqrs tipo,
    required String descripcion,
    required List<ModeloArchivoAdjunto> evidencias,
  }) async {
    // Evita el doble envío: un segundo toque mientras se envía no hace nada.
    if (enviando) return;

    final uid = _obtenerUid();
    if (uid == null) {
      mensajeError = 'Tu sesión expiró. Vuelve a iniciar sesión para enviar la PQRS.';
      _notificar();
      return;
    }

    enviando = true;
    mensajeError = null;
    _notificar();

    final id = _servicioPqrs.nuevoId();
    final rutasSubidas = <String>[];
    try {
      final registradas = <ModeloEvidenciaPqrs>[];
      for (var i = 0; i < evidencias.length; i++) {
        final archivo = evidencias[i];
        final String ruta;
        try {
          ruta = await _servicioStorage.subirEvidenciaPqrs(uid, id, i + 1, archivo);
        } catch (e) {
          throw _ErrorSubida(archivo.nombreArchivo, e);
        }
        rutasSubidas.add(ruta);
        registradas.add(ModeloEvidenciaPqrs(
          nombreArchivo: _recortarNombre(archivo.nombreArchivo),
          ruta: ruta,
          tipoContenido: archivo.tipoContenido,
          tamanio: archivo.tamanio,
        ));
      }

      final nueva = ModeloPqrs(
        id: id,
        uid: uid,
        tipo: tipo,
        descripcion: descripcion.trim(),
        evidencias: registradas,
      );
      await _servicioPqrs.crear(nueva);
      pqrs = nueva;
    } catch (e) {
      await _borrarSubidas(rutasSubidas);
      enviando = false;
      mensajeError = _mensajeDesde(e);
      _notificar();
      return;
    }

    enviando = false;
    etapa = EtapaPqrs.esperandoRadicado;
    _notificar();
    _esperarRadicado(id);
  }

  void _esperarRadicado(String id) {
    _temporizador = Timer(esperaAntesDeAviso, () {
      esperaProlongada = true;
      _notificar();
    });
    _suscripcion = _servicioPqrs.observar(id).listen(
      (actual) {
        if (actual?.radicado == null) return;
        pqrs = actual;
        _cancelarEspera();
        etapa = EtapaPqrs.confirmada;
        _notificar();
      },
      onError: (Object _) {
        errorEspera = 'Tu PQRS quedó registrada, pero no pudimos consultar el radicado. '
            'Te llegará en el correo de confirmación.';
        _notificar();
      },
    );
  }

  /// Borra las evidencias ya subidas cuando el envío falla más adelante.
  /// Es un mejor esfuerzo: si la limpieza también falla, el mensaje que ve
  /// el usuario debe seguir siendo el del error original.
  Future<void> _borrarSubidas(List<String> rutas) async {
    if (rutas.isEmpty) return;
    try {
      await _servicioStorage.eliminarRutas(rutas);
    } catch (_) {}
  }

  /// Las reglas admiten nombres de hasta 255 caracteres.
  String _recortarNombre(String nombre) => nombre.length <= 255 ? nombre : nombre.substring(0, 255);

  String _mensajeDesde(Object e) {
    if (e is _ErrorSubida) {
      return 'No se pudo subir la evidencia "${e.nombreArchivo}". ${_mensajeDesde(e.causa)}';
    }
    if (e is ArgumentError) {
      return e.message?.toString() ?? 'Los datos de la PQRS no son válidos.';
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
        case 'unauthorized':
        case 'unauthenticated':
          return 'No tienes permiso para enviar esta PQRS. Vuelve a iniciar sesión e intenta de nuevo.';
        case 'unavailable':
        case 'retry-limit-exceeded':
        case 'network-request-failed':
          return 'No hay conexión con el servidor. Revisa tu internet e intenta de nuevo.';
      }
    }
    return 'No se pudo enviar la PQRS. Intenta de nuevo.';
  }

  void _reiniciar() {
    _cancelarEspera();
    tipoInicial = null;
    mensajeError = null;
    pqrs = null;
    esperaProlongada = false;
    errorEspera = null;
  }

  void _cancelarEspera() {
    _temporizador?.cancel();
    _temporizador = null;
    _suscripcion?.cancel();
    _suscripcion = null;
  }

  /// Si el panel se cierra a mitad de un envío (por ejemplo, al cerrar
  /// sesión), las operaciones en curso terminan igual, pero ya no hay a
  /// quién avisar.
  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    _cancelarEspera();
    super.dispose();
  }
}

/// Error de subida de una evidencia concreta, para decirle al usuario cuál
/// archivo falló.
class _ErrorSubida implements Exception {
  final String nombreArchivo;
  final Object causa;

  const _ErrorSubida(this.nombreArchivo, this.causa);
}
