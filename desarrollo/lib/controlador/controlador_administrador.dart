import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelo/modelo_abogado.dart';
import '../modelo/modelo_archivo_adjunto.dart';
import '../modelo/modelo_info_archivo.dart';
import 'servicio_firestore.dart';
import 'servicio_perfil_publico.dart';
import 'servicio_storage.dart';

/// Estado del panel de administrador: lista de abogados y acciones sobre
/// ellos.
class ControladorAdministrador extends ChangeNotifier {
  final ServicioFirestore _servicioFirestore;
  final ServicioPerfilPublico _servicioPerfilPublico;
  final ServicioStorage _servicioStorage;

  ControladorAdministrador({
    ServicioFirestore? servicioFirestore,
    ServicioPerfilPublico? servicioPerfilPublico,
    ServicioStorage? servicioStorage,
  })  : _servicioFirestore = servicioFirestore ?? ServicioFirestore(),
        _servicioPerfilPublico = servicioPerfilPublico ?? ServicioPerfilPublico(),
        _servicioStorage = servicioStorage ?? ServicioStorage();

  List<ModeloAbogado> abogados = [];

  /// Último error de lectura de la lista. La vista lo muestra en lugar de
  /// dejar la pantalla en blanco sin explicación.
  String? errorLista;

  /// Verdadero hasta que llega la primera respuesta de Firestore. Distingue
  /// "todavía cargando" de "no hay abogados": sin esto, el panel mostraría
  /// "0 abogados" durante un instante, que es un dato falso.
  bool cargandoAbogados = true;

  StreamSubscription<List<ModeloAbogado>>? _suscripcion;

  /// Empieza a escuchar la colección `abogados` en tiempo real.
  ///
  /// No notifica de forma inmediata porque se llama desde `initState`, en
  /// medio de un build: notificar ahí provocaría el error "markNeedsBuild
  /// called during build". Para reintentar desde un botón, usar
  /// [reintentarEscucha].
  void escucharAbogados() {
    _suscripcion?.cancel();
    abogados = [];
    errorLista = null;
    cargandoAbogados = true;
    _suscripcion = _servicioFirestore.observarAbogados().listen(
      (lista) {
        abogados = lista;
        errorLista = null;
        cargandoAbogados = false;
        notifyListeners();
      },
      onError: (Object error) {
        errorLista = 'No se pudo cargar la lista de abogados: $error';
        cargandoAbogados = false;
        notifyListeners();
      },
    );
  }

  /// Reintenta la escucha a partir de un gesto del usuario. Ahí sí es seguro
  /// notificar enseguida, para que la vista muestre el estado de carga.
  void reintentarEscucha() {
    escucharAbogados();
    notifyListeners();
  }

  /// Deja de escuchar la colección. El panel lo llama al cerrarse, por
  /// ejemplo al cerrar sesión: sin sesión de administrador las reglas niegan
  /// la lectura, y la escucha abierta acumularía un error de permisos que
  /// aparecería en el siguiente inicio de sesión.
  void detenerEscucha() {
    _suscripcion?.cancel();
    _suscripcion = null;
  }

  /// Cambia la verificación del abogado en su documento privado y en su
  /// perfil público a la vez.
  ///
  /// Devuelve `null` si la operación tuvo éxito, o un mensaje de error para
  /// mostrar al administrador. Nunca informa éxito sobre una escritura que
  /// Firebase rechazó.
  Future<String?> cambiarEstado(String uid, bool verificado) async {
    try {
      // Un abogado registrado antes de que existiera la colección pública no
      // tiene perfil que actualizar. Se proyecta desde su documento privado
      // antes de continuar, en lugar de fallar con un error críptico.
      await _asegurarPerfilPublico(uid);
      await _servicioFirestore.actualizarEstadoAbogadoYPerfil(
        uid,
        verificado ? 'verificado' : 'pendiente',
      );
      return null;
    } catch (e) {
      return 'No se pudo actualizar la verificación: $e';
    }
  }

  /// Vuelve a publicar el perfil público de un abogado a partir de su
  /// documento privado. Útil cuando el perfil público no existe o quedó
  /// desactualizado.
  Future<String?> regenerarPerfilPublico(String uid) async {
    try {
      final creado = await _asegurarPerfilPublico(uid);
      if (!creado) {
        final abogado = await _servicioFirestore.obtenerAbogado(uid);
        if (abogado == null) return 'El abogado ya no existe en la base de datos.';
        await _servicioPerfilPublico.actualizar(abogado.aPerfilPublico());
      }
      return null;
    } catch (e) {
      return 'No se pudo regenerar el perfil público: $e';
    }
  }

  /// Crea el perfil público si falta. Devuelve `true` si lo creó.
  Future<bool> _asegurarPerfilPublico(String uid) async {
    final existente = await _servicioPerfilPublico.obtener(uid);
    if (existente != null) return false;
    final abogado = await _servicioFirestore.obtenerAbogado(uid);
    if (abogado == null) {
      throw StateError('No existe el documento privado del abogado $uid');
    }
    await _servicioPerfilPublico.crear(abogado.aPerfilPublico());
    return true;
  }

  /// Elimina el documento privado del abogado, su perfil público y todos sus
  /// archivos de Storage.
  ///
  /// La cuenta de Authentication no se borra: el SDK cliente no puede
  /// eliminar la cuenta de otro usuario. Queda pendiente de borrado manual
  /// en la consola de Firebase. Ver [PanelAdministrador] para el aviso.
  Future<String?> eliminarAbogado(String uid) async {
    try {
      await _servicioFirestore.eliminarAbogadoCompleto(uid);
      await _servicioStorage.eliminarTodoDelAbogado(uid);
      return null;
    } catch (e) {
      return 'No se pudo eliminar la cuenta: $e';
    }
  }

  /// Descarga un documento de verificación desde Storage para mostrarlo o
  /// guardarlo en el panel. Pasa por las reglas de Storage, así que solo
  /// funciona para el dueño y para el administrador.
  Future<ModeloArchivoAdjunto?> obtenerArchivo(String ruta) {
    return _servicioStorage.obtenerArchivo(ruta);
  }

  /// Lee los metadatos de un documento sin descargarlo, para confirmar que
  /// existe en Storage y mostrar su nombre, tipo, tamaño y fecha. Devuelve
  /// `null` si la ruta está registrada pero el archivo no existe.
  Future<ModeloInfoArchivo?> obtenerInfoDocumento(String ruta) {
    return _servicioStorage.obtenerInfoArchivo(ruta);
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
