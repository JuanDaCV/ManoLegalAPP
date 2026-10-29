import 'package:flutter/foundation.dart';

import '../modelo/modelo_abogado.dart';
import '../modelo/modelo_archivo_adjunto.dart';
import '../modelo/modelo_experiencia_profesional.dart';
import '../modelo/modelo_perfil_abogado.dart';
import '../modelo/modelo_resena.dart';
import '../modelo/ubicacion_cali.dart';
import 'servicio_firestore.dart';
import 'servicio_perfil_publico.dart';
import 'servicio_resenas.dart';
import 'servicio_storage.dart';

/// Estado de carga del perfil del abogado autenticado.
enum EstadoPerfilAbogado { cargando, listo, error }

/// Controlador del perfil del abogado autenticado, expuesto vía Provider al
/// panel del abogado.
///
/// La fuente de verdad interna es el documento privado `abogados/{uid}`. El
/// [ModeloPerfilAbogado] que consumen las vistas se reconstruye a partir de
/// él después de cada cambio, de modo que no existen dos copias del perfil
/// que puedan desincronizarse.
class ControladorPerfilAbogado extends ChangeNotifier {
  final ServicioFirestore _servicioFirestore;
  final ServicioPerfilPublico _servicioPerfilPublico;
  final ServicioResenas _servicioResenas;
  final ServicioStorage _servicioStorage;

  ControladorPerfilAbogado({
    ServicioFirestore? servicioFirestore,
    ServicioPerfilPublico? servicioPerfilPublico,
    ServicioResenas? servicioResenas,
    ServicioStorage? servicioStorage,
  })  : _servicioFirestore = servicioFirestore ?? ServicioFirestore(),
        _servicioPerfilPublico = servicioPerfilPublico ?? ServicioPerfilPublico(),
        _servicioResenas = servicioResenas ?? ServicioResenas(),
        _servicioStorage = servicioStorage ?? ServicioStorage();

  EstadoPerfilAbogado estado = EstadoPerfilAbogado.cargando;
  String? mensajeError;

  /// Perfil listo para mostrar. Es `null` mientras carga y si la carga falló.
  ModeloPerfilAbogado? perfil;

  ModeloAbogado? _abogado;
  List<ModeloResena> _resenas = const [];
  double _calificacion = 0;
  int _cantidadResenas = 0;

  /// Carga el perfil real del abogado [uid] desde Firestore.
  ///
  /// Si el abogado todavía no tiene perfil público, lo crea a partir de su
  /// documento privado. Esa es la migración no destructiva de las cuentas
  /// creadas antes de que existiera la colección pública: sin ella, esos
  /// abogados nunca aparecerían en el buscador, y no hay forma de generarlo
  /// desde fuera sin borrar ni reescribir nada.
  Future<void> cargar(String uid) async {
    estado = EstadoPerfilAbogado.cargando;
    mensajeError = null;
    notifyListeners();

    try {
      final abogado = await _servicioFirestore.obtenerAbogado(uid);
      if (abogado == null) {
        estado = EstadoPerfilAbogado.error;
        mensajeError = 'No encontramos tu perfil profesional.';
        notifyListeners();
        return;
      }
      _abogado = abogado;

      var publico = await _servicioPerfilPublico.obtener(uid);
      if (publico == null) {
        await _servicioPerfilPublico.crear(abogado.aPerfilPublico());
        publico = await _servicioPerfilPublico.obtener(uid);
      }

      _resenas = await _servicioResenas.obtenerDeAbogado(uid);
      _calificacion = publico?.calificacionPromedio ?? 0;
      _cantidadResenas = publico?.cantidadResenas ?? 0;

      _reconstruirPerfil();
      estado = EstadoPerfilAbogado.listo;
      notifyListeners();
    } catch (e) {
      estado = EstadoPerfilAbogado.error;
      mensajeError = 'No se pudo cargar tu perfil: $e';
      notifyListeners();
    }
  }

  Future<bool> actualizarSobreMi(String sobreMi) {
    return _guardar((abogado) => abogado.copiarCon(descripcion: sobreMi));
  }

  Future<bool> agregarExperiencia(ModeloExperienciaProfesional experiencia) {
    return _guardar(
      (abogado) => abogado.copiarCon(experiencia: [...abogado.experiencia, experiencia]),
    );
  }

  Future<bool> editarExperiencia(ModeloExperienciaProfesional experiencia) {
    return _guardar(
      (abogado) => abogado.copiarCon(
        experiencia: [
          for (final actual in abogado.experiencia)
            if (actual.id == experiencia.id) experiencia else actual,
        ],
      ),
    );
  }

  Future<bool> eliminarExperiencia(String id) {
    return _guardar(
      (abogado) => abogado.copiarCon(
        experiencia: abogado.experiencia.where((actual) => actual.id != id).toList(),
      ),
    );
  }

  /// Actualiza la ubicación del abogado.
  ///
  /// Pasar `null` en [ubicacionGeneral] conserva la zona anterior en lugar de
  /// borrarla: la zona es obligatoria desde el registro, así que una omisión
  /// aquí significa "no la estoy cambiando", no "quiero quedarme sin zona".
  Future<bool> actualizarUbicacion({
    UbicacionCali? ubicacionGeneral,
    required String sector,
    required String direccion,
  }) {
    return _guardar(
      (abogado) => abogado.copiarCon(
        ubicacionGeneral: ubicacionGeneral,
        sector: sector,
        direccionProfesional: direccion,
      ),
    );
  }

  Future<bool> actualizarRedes({String? instagram, String? facebook, String? linkedin}) {
    return _guardar(
      (abogado) => abogado.copiarCon(
        instagram: instagram,
        facebook: facebook,
        linkedin: linkedin,
      ),
    );
  }

  Future<bool> actualizarTarifa(double? tarifa) {
    return _guardar((abogado) => abogado.copiarCon(tarifa: tarifa));
  }

  /// Sube una foto nueva y guarda su URL en el perfil.
  ///
  /// La foto siempre se escribe en la misma ruta de Storage
  /// (`abogados/{uid}/foto_perfil.jpg`), así que reemplazarla sobrescribe la
  /// anterior. No queda ningún archivo huérfano y no hace falta un borrado
  /// aparte.
  Future<bool> cambiarFotoPerfil(ModeloArchivoAdjunto archivo) async {
    final actual = _abogado;
    if (actual == null) return false;

    String url;
    try {
      url = await _servicioStorage.subirFotoPerfil(actual.uid, archivo);
    } catch (e) {
      mensajeError = 'No se pudo subir la foto: $e';
      notifyListeners();
      return false;
    }
    return _guardar((abogado) => abogado.copiarCon(fotoPerfilRuta: url));
  }

  /// Persiste un cambio del perfil.
  ///
  /// El estado local solo se actualiza si Firebase aceptó la escritura. Así
  /// la interfaz nunca muestra como guardado algo que en realidad fue
  /// rechazado, que es justo lo que ocurriría si se actualizara primero la
  /// memoria y después se intentara escribir.
  Future<bool> _guardar(ModeloAbogado Function(ModeloAbogado) transformar) async {
    final actual = _abogado;
    if (actual == null) return false;

    final modificado = transformar(actual);
    try {
      await _servicioFirestore.actualizarAbogadoConPerfilPublico(modificado);
      _abogado = modificado;
      _reconstruirPerfil();
      mensajeError = null;
      notifyListeners();
      return true;
    } catch (e) {
      mensajeError = 'No se pudo guardar el cambio: $e';
      notifyListeners();
      return false;
    }
  }

  void _reconstruirPerfil() {
    final abogado = _abogado;
    if (abogado == null) return;
    perfil = ModeloPerfilAbogado.desdeAbogadoPrivado(
      abogado,
      resenas: _resenas,
      calificacion: _calificacion,
      cantidadResenas: _cantidadResenas,
    );
  }
}
