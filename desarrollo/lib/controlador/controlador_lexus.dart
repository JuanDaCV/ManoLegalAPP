import 'dart:async';
import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../configuracion/configuracion_lexus.dart';
import '../configuracion/respuestas_locales_lexus.dart';
import '../modelo/error_lexus.dart';
import '../modelo/especialidad_abogado.dart';
import '../modelo/modelo_mensaje_lexus.dart';
import '../modelo/modelo_respuesta_lexus.dart';
import '../modelo/modelo_resultado_abogado.dart';
import 'filtro_lexus.dart';
import 'filtros_abogados.dart';
import 'historial_lexus.dart';
import 'servicio_conversaciones_lexus.dart';
import 'servicio_lexus.dart';
import 'servicio_lexus_real.dart';
import 'servicio_perfil_publico.dart';

/// Resultado de validar el texto que la persona quiere enviar.
enum ValidacionMensajeLexus {
  valido,
  vacio,
  demasiadoLargo,
  limiteTurnos,
  enCurso,
  muyRapido,
}

enum EstadoAbogadosLexus { inicial, cargando, conResultados, vacio, error }

/// Abogados reales sugeridos para una especialidad, con el estado de su
/// carga.
class SugerenciasAbogadosLexus {
  const SugerenciasAbogadosLexus(this.estado, [this.abogados = const []]);

  final EstadoAbogadosLexus estado;
  final List<ModeloResultadoAbogado> abogados;
}

/// Coordina la conversación con Lexus.
///
/// La conversación se guarda en `clientes/{uid}/conversacionesLexus`, así que
/// sobrevive a cerrar la aplicación, cerrar sesión o cambiar de dispositivo:
/// al abrir se retoma la más reciente si sigue activa (ver
/// [ConfiguracionLexus.vigenciaConversacion]). Son relatos jurídicos
/// sensibles: las reglas de Firestore solo dejan leerlos a su dueño, ni
/// siquiera al administrador de la app.
///
/// Guardar nunca bloquea el chat y, si falla, [historialNoDisponible] pasa a
/// verdadero y la conversación sigue solo en memoria. De guardar y retomar se
/// encarga [HistorialLexus]; este controlador solo lo invoca en cada paso.
class ControladorLexus extends ChangeNotifier {
  ControladorLexus({
    ServicioLexus? servicio,
    ServicioConversacionesLexus? conversaciones,
    Future<List<ModeloResultadoAbogado>> Function(EspecialidadAbogado area)?
    buscarAbogados,
    bool Function()? haySesion,
    DateTime Function()? ahora,
  }) : _servicioInyectado = servicio,
       _buscarAbogados = buscarAbogados ?? _buscarAbogadosReales,
       _haySesion =
           haySesion ?? (() => FirebaseAuth.instance.currentUser != null),
       _ahora = ahora ?? DateTime.now {
    _historialGuardado = HistorialLexus(
      servicio: conversaciones,
      alQuedarNoDisponible: _notificar,
    );
    _mensajes.add(_mensajeSaludo());
    _cargaInicial = _cargarHistorial();
  }

  final ServicioLexus? _servicioInyectado;
  final Future<List<ModeloResultadoAbogado>> Function(EspecialidadAbogado area)
  _buscarAbogados;
  final bool Function() _haySesion;
  final DateTime Function() _ahora;

  /// Se crea al primer uso: el servicio real depende de Firebase.
  late final ServicioLexus _servicio =
      _servicioInyectado ?? ServicioLexusReal();

  final List<ModeloMensajeLexus> _mensajes = [];
  final Map<EspecialidadAbogado, SugerenciasAbogadosLexus> _sugerencias = {};
  bool _enviando = false;
  bool _introduccionVista = false;
  bool _desechado = false;
  int _turnosUsados = 0;
  int _contadorId = 0;
  DateTime? _ultimoEnvio;

  /// Cada conversación nueva sube el contador: una respuesta que llega
  /// después de empezar otra se descarta.
  int _generacion = 0;

  // Historial guardado.
  late final Future<void> _cargaInicial;
  bool _cargando = true;
  late final HistorialLexus _historialGuardado;

  List<ModeloMensajeLexus> get mensajes => UnmodifiableListView(_mensajes);
  bool get enviando => _enviando;

  /// Verdadero mientras se busca la conversación guardada. Hasta entonces no
  /// se admite ningún envío.
  bool get cargando => _cargando;

  /// Termina cuando se sabe si hay una conversación que retomar.
  Future<void> get cargaInicial => _cargaInicial;

  /// Verdadero si el historial no se pudo cargar o guardar: la conversación
  /// sigue, pero solo en memoria.
  bool get historialNoDisponible => _historialGuardado.noDisponible;
  bool get introduccionVista => _introduccionVista;
  int get turnosUsados => _turnosUsados;
  bool get conversacionExtensa =>
      _turnosUsados >= ConfiguracionLexus.turnosAvisoConversacionLarga;
  bool get limiteAlcanzado => _turnosUsados >= ConfiguracionLexus.turnosMaximos;
  bool get hayConversacion =>
      _mensajes.any((m) => m.autor == AutorMensajeLexus.usuario);

  /// No notifica: la introducción decide si se anima al montarse y un
  /// reconstruir a mitad de la animación la cortaría.
  void marcarIntroduccionVista() => _introduccionVista = true;

  ValidacionMensajeLexus validar(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return ValidacionMensajeLexus.vacio;
    if (limpio.runes.length > ConfiguracionLexus.largoMaximoMensaje) {
      return ValidacionMensajeLexus.demasiadoLargo;
    }
    // Hasta saber si hay una conversación que retomar, enviar la mezclaría
    // con ella.
    if (_cargando) return ValidacionMensajeLexus.enCurso;
    if (limiteAlcanzado) return ValidacionMensajeLexus.limiteTurnos;
    if (_enviando) return ValidacionMensajeLexus.enCurso;
    final ultimo = _ultimoEnvio;
    if (ultimo != null &&
        _ahora().difference(ultimo) <
            ConfiguracionLexus.intervaloMinimoEntreEnvios) {
      return ValidacionMensajeLexus.muyRapido;
    }
    return ValidacionMensajeLexus.valido;
  }

  /// Tiempo que falta para que se admita otro envío (cero si ya se puede).
  Duration get esperaParaEnviar {
    final ultimo = _ultimoEnvio;
    if (ultimo == null) return Duration.zero;
    final restante =
        ConfiguracionLexus.intervaloMinimoEntreEnvios -
        _ahora().difference(ultimo);
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Si aún se está cargando el historial, espera a que termine: solo
  /// entonces se sabe a qué conversación pertenece el mensaje. Si no, valida y
  /// envía de inmediato, sin ceder el turno.
  Future<void> enviar(String texto) async {
    if (_cargando) await _cargaInicial;
    if (validar(texto) != ValidacionMensajeLexus.valido) return;
    await _procesar(texto.trim());
  }

  /// Reenvía un mensaje fallido. No aplica el intervalo mínimo: la persona
  /// ya esperó el fallo, pero sí respeta el envío en curso y el límite. El
  /// mensaje conserva su identificador y pasa al final de la conversación.
  Future<void> reintentar(String idMensajeUsuario) async {
    if (_cargando) await _cargaInicial;
    if (_enviando || limiteAlcanzado) return;
    final indice = _mensajes.indexWhere(
      (m) =>
          m.id == idMensajeUsuario &&
          m.autor == AutorMensajeLexus.usuario &&
          m.estado == EstadoMensajeLexus.fallido,
    );
    if (indice < 0) return;
    final mensaje = _mensajes.removeAt(indice);
    await _procesar(mensaje.texto, idReintento: mensaje.id);
  }

  /// Deja la conversación actual como cerrada (no se borra) y empieza otra.
  void nuevaConversacion() {
    _generacion++;
    _historialGuardado.reiniciar();
    _mensajes
      ..clear()
      ..add(_mensajeSaludo());
    _sugerencias.clear();
    _turnosUsados = 0;
    _enviando = false;
    _ultimoEnvio = null;
    _notificar();
  }

  SugerenciasAbogadosLexus sugerencias(EspecialidadAbogado area) {
    return _sugerencias[area] ??
        const SugerenciasAbogadosLexus(EstadoAbogadosLexus.inicial);
  }

  /// Carga los abogados de [area]. El resultado se conserva durante la
  /// conversación; solo un error permite volver a intentarlo.
  Future<void> cargarAbogados(EspecialidadAbogado area) async {
    final estadoActual = sugerencias(area).estado;
    if (estadoActual != EstadoAbogadosLexus.inicial &&
        estadoActual != EstadoAbogadosLexus.error) {
      return;
    }

    final generacion = _generacion;
    _sugerencias[area] = const SugerenciasAbogadosLexus(
      EstadoAbogadosLexus.cargando,
    );
    _notificar();
    try {
      final abogados = (await _buscarAbogados(area))
          .take(ConfiguracionLexus.abogadosSugeridos)
          .toList();
      if (generacion != _generacion) return;
      _sugerencias[area] = SugerenciasAbogadosLexus(
        abogados.isEmpty
            ? EstadoAbogadosLexus.vacio
            : EstadoAbogadosLexus.conResultados,
        abogados,
      );
    } catch (_) {
      if (generacion != _generacion) return;
      debugPrint('Lexus: error tipo=abogados');
      _sugerencias[area] = const SugerenciasAbogadosLexus(
        EstadoAbogadosLexus.error,
      );
    }
    _notificar();
  }

  /// [idReintento] es el identificador de un mensaje fallido que se reenvía: se
  /// reutiliza para que siga siendo el mismo documento del historial.
  Future<void> _procesar(String texto, {String? idReintento}) async {
    final generacion = _generacion;
    _ultimoEnvio = _ahora();
    final usuario = ModeloMensajeLexus(
      id: idReintento ?? _nuevoIdMensaje(),
      autor: AutorMensajeLexus.usuario,
      texto: texto,
      momento: _ahora(),
      estado: EstadoMensajeLexus.enviando,
      textoParaModelo: texto,
    );
    _mensajes.add(usuario);
    _enviando = true;
    _notificar();

    if (!_haySesion()) {
      // Sin sesión no hay a quién guardarle nada.
      _marcarFallido(usuario.id, TipoErrorLexus.sesionExpirada, guardar: false);
      return;
    }
    _historialGuardado.guardarEnvio(usuario);
    if (pareceIntentoDeManipulacion(texto)) {
      _responderLocal(
        usuario.id,
        RespuestasLocalesLexus.respuestaIntentoManipulacion,
      );
      return;
    }

    final String crudo;
    final ModeloRespuestaLexus respuesta;
    try {
      crudo = await _servicio.enviar(historial: _historial(), mensaje: texto);
      if (generacion != _generacion) return;
      respuesta = ModeloRespuestaLexus.desdeJson(crudo);
    } catch (e) {
      if (generacion != _generacion) return;
      _marcarFallido(usuario.id, mapearErrorLexus(e).tipo);
      return;
    }

    switch (respuesta.ambito) {
      case AmbitoLexus.fueraDeAlcance:
        _responderLocal(
          usuario.id,
          RespuestasLocalesLexus.respuestaFueraDeAlcance,
        );
      case AmbitoLexus.intentoDeManipulacion:
        _responderLocal(
          usuario.id,
          RespuestasLocalesLexus.respuestaIntentoManipulacion,
        );
      case AmbitoLexus.juridico || AmbitoLexus.manolegal:
        if (revelaInstrucciones(respuesta.respuesta)) {
          _responderLocal(
            usuario.id,
            RespuestasLocalesLexus.respuestaIntentoManipulacion,
          );
        } else {
          _responderDelModelo(usuario.id, respuesta, crudo);
        }
    }
  }

  /// Turnos que se reenvían al modelo. Solo entran los intercambios que el
  /// modelo respondió dentro de su ámbito.
  List<TurnoLexus> _historial() {
    return [
      for (final mensaje in _mensajes)
        if (mensaje.enHistorialModelo && mensaje.textoParaModelo != null)
          TurnoLexus(
            esUsuario: mensaje.autor == AutorMensajeLexus.usuario,
            texto: mensaje.textoParaModelo!,
          ),
    ];
  }

  /// Con [guardar] en falso el fallo solo queda en memoria.
  void _marcarFallido(
    String idUsuario,
    TipoErrorLexus tipo, {
    bool guardar = true,
  }) {
    _reemplazar(
      idUsuario,
      (m) => m.copyWith(estado: EstadoMensajeLexus.fallido, error: tipo),
    );
    if (guardar) _historialGuardado.guardarFallo(idUsuario, tipo);
    _enviando = false;
    _notificar();
  }

  /// Respuesta con texto fijo de la aplicación. Ni la pregunta ni esta
  /// respuesta pasan al historial del modelo: lo que está fuera de ámbito o
  /// intenta manipularlo no debe condicionar los turnos siguientes. Sí se
  /// guarda: se ve en pantalla y cuenta como un turno.
  void _responderLocal(String idUsuario, String texto) {
    _reemplazar(
      idUsuario,
      (m) => m.copyWith(estado: EstadoMensajeLexus.enviado),
    );
    final respuesta = ModeloMensajeLexus(
      id: _nuevoIdMensaje(),
      autor: AutorMensajeLexus.lexus,
      texto: texto,
      momento: _ahora(),
    );
    _mensajes.add(respuesta);
    _historialGuardado.guardarRespuesta(
      idUsuario,
      respuesta,
      usuarioEnHistorialModelo: false,
    );
    _terminarTurno();
  }

  void _responderDelModelo(
    String idUsuario,
    ModeloRespuestaLexus respuesta,
    String crudo,
  ) {
    _reemplazar(
      idUsuario,
      (m) => m.copyWith(
        estado: EstadoMensajeLexus.enviado,
        enHistorialModelo: true,
      ),
    );
    final mensaje = ModeloMensajeLexus(
      id: _nuevoIdMensaje(),
      autor: AutorMensajeLexus.lexus,
      texto: respuesta.respuesta,
      momento: _ahora(),
      origen: OrigenMensajeLexus.modelo,
      urgente: respuesta.urgente,
      areaSugerida: respuesta.sugerirAbogados ? respuesta.areaProbable : null,
      enHistorialModelo: true,
      textoParaModelo: crudo,
    );
    _mensajes.add(mensaje);
    _historialGuardado.guardarRespuesta(
      idUsuario,
      mensaje,
      usuarioEnHistorialModelo: true,
    );
    _terminarTurno();
  }

  void _terminarTurno() {
    _turnosUsados++;
    _enviando = false;
    _notificar();
  }

  void _reemplazar(
    String id,
    ModeloMensajeLexus Function(ModeloMensajeLexus) cambio,
  ) {
    final indice = _mensajes.indexWhere((m) => m.id == id);
    if (indice >= 0) _mensajes[indice] = cambio(_mensajes[indice]);
  }

  ModeloMensajeLexus _mensajeSaludo() => ModeloMensajeLexus(
    id: _nuevoId(),
    autor: AutorMensajeLexus.lexus,
    texto: RespuestasLocalesLexus.saludo,
    momento: _ahora(),
  );

  String _nuevoId() => 'm${_contadorId++}';

  /// Identificador de un mensaje nuevo: el del historial, para que el mensaje
  /// en pantalla y su documento sean el mismo; si no se puede, uno local.
  String _nuevoIdMensaje() => _historialGuardado.nuevoIdMensaje() ?? _nuevoId();

  /// Busca la conversación más reciente y, si sigue activa y vigente, la
  /// retoma. Nunca lanza: si falla, el chat sigue sin historial.
  Future<void> _cargarHistorial() async {
    final generacion = _generacion;
    final guardada = await _historialGuardado.cargar();

    if (generacion != _generacion) {
      _historialGuardado.descartarCargada(guardada);
    } else if (guardada != null) {
      final retomada = _historialGuardado.retomar(guardada, _ahora());
      if (retomada != null) {
        _mensajes.addAll(retomada.mensajes);
        _turnosUsados = retomada.turnos;
      }
    }
    _cargando = false;
    _notificar();
  }

  static Future<List<ModeloResultadoAbogado>> _buscarAbogadosReales(
    EspecialidadAbogado area,
  ) async {
    final perfiles = await ServicioPerfilPublico().buscar(
      especialidades: [area],
      soloVerificados: true,
      limite: ConfiguracionLexus.abogadosSugeridos,
    );
    return perfiles.map(aResultadoBusqueda).toList();
  }

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    super.dispose();
  }
}
