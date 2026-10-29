import 'dart:async';

import 'package:desarrollo/configuracion/configuracion_recorrido_visitante.dart';
import 'package:desarrollo/controlador/controlador_dictado_lexus.dart';
import 'package:desarrollo/controlador/controlador_lexus.dart';
import 'package:desarrollo/controlador/controlador_pqrs.dart';
import 'package:desarrollo/controlador/servicio_conversaciones_lexus_visitante.dart';
import 'package:desarrollo/controlador/servicio_firestore.dart';
import 'package:desarrollo/controlador/servicio_perfil_publico.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_perfil_publico_abogado.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:desarrollo/vista/visitante/panel_visitante.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dobles_como_funciona.dart';
import 'dobles_dictado_lexus.dart';
import 'dobles_lexus.dart';
import 'dobles_pqrs.dart';
import 'dobles_recorrido.dart';

// =============================================================================
// Dobles del modo visitante. El panel real lee Authentication, Firestore,
// Lexus, el micrófono y el video; aquí todo es falso y queda registrado.
// =============================================================================

/// Proyección pública falsa: devuelve [perfiles] y registra con qué filtros
/// se buscó. Se declara con `implements` porque extender la clase real
/// ejecutaría `FirebaseFirestore.instance` al crearla.
class TarjetasFalsas implements ServicioPerfilPublico {
  TarjetasFalsas(this.perfiles);

  final List<ModeloPerfilPublicoAbogado> perfiles;

  /// Las especialidades de cada búsqueda, en orden.
  final List<List<EspecialidadAbogado>> busquedas = [];

  @override
  Future<List<ModeloPerfilPublicoAbogado>> buscar({
    bool soloVerificados = true,
    double calificacionMinima = 0,
    List<EspecialidadAbogado> especialidades = const [],
    int limite = 100,
  }) async {
    busquedas.add(List.of(especialidades));
    return perfiles;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Dos abogados verificados con datos inventados y una ubicación corta: la
/// fuente de las pruebas dibuja cada letra del ancho de su altura.
List<ModeloPerfilPublicoAbogado> abogadosVisitante() => [
  perfilDePrueba(
    uid: 'a1',
    nombreCompleto: 'Ana Prueba',
    especialidad: EspecialidadAbogado.laboral,
    ubicacion: UbicacionCali.jamundi,
    calificacion: 4.5,
    cantidadResenas: 3,
    tarifa: 120000,
  ),
  perfilDePrueba(
    uid: 'a2',
    nombreCompleto: 'Beto Prueba',
    ubicacion: UbicacionCali.jamundi,
  ),
];

/// Usuario de Authentication falso: solo hace falta que no sea nulo.
class UsuarioFalso implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Firestore falso para construir `ControladorAutenticacion` sin Firebase.
class FirestoreFalso implements ServicioFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Video falso: el real necesita la plataforma de video. Sin id de
/// reproductor, `VideoPlayer` dibuja un contenedor vacío.
class VideoIntroductorioFalso extends ValueNotifier<VideoPlayerValue> implements VideoPlayerController {
  VideoIntroductorioFalso() : super(const VideoPlayerValue.uninitialized());

  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  Future<void> initialize() async {
    value = const VideoPlayerValue(duration: Duration(seconds: 10), size: Size(848, 480), isInitialized: true);
  }

  @override
  Future<void> setVolume(double volume) async => value = value.copyWith(volume: volume);

  @override
  Future<void> setLooping(bool looping) async => value = value.copyWith(isLooping: looping);

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> dispose() async => super.dispose();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Banco del panel del visitante, con todos sus servicios falsos.
class BancoVisitante {
  final TarjetasFalsas tarjetas = TarjetasFalsas(abogadosVisitante());
  final PqrsFalso pqrs = PqrsFalso();
  final StorageFalso storage = StorageFalso();
  final ServicioLexusDoble lexus = ServicioLexusDoble();
  final GrabacionAudioFalsa grabadora = GrabacionAudioFalsa();
  final TranscriptorFalso transcriptor = TranscriptorFalso();
  final RelojDictadoFalso relojDictado = RelojDictadoFalso();
  final StreamController<User?> sesion = StreamController<User?>.broadcast();

  /// El controlador de Lexus que creó el panel, si se pidió uno de prueba.
  ControladorLexus? controladorLexus;

  /// Si es verdadero, el panel crea su propio controlador de Lexus (el del
  /// visitante, como en la aplicación) en lugar de uno con [lexus].
  bool lexusDeLaAplicacion = false;

  /// Estado de los recorridos guiados del visitante. Por defecto ya se vieron
  /// todos, para que la capa no tape lo que prueban las demás pruebas; las de
  /// los recorridos ponen [recorridosVistos] en falso.
  final AlmacenMemoria recorridos = AlmacenMemoria();
  bool recorridosVistos = true;

  PanelVisitante panel() {
    if (recorridosVistos) {
      for (final recorrido in ConfiguracionRecorridoVisitante.todos) {
        recorridos.datos.putIfAbsent(
          '${recorrido.prefijoClave}${ConfiguracionRecorridoVisitante.claveDispositivo}',
          () => 'completado',
        );
      }
    }
    return PanelVisitante(
      almacenRecorridos: recorridos,
      intervaloSondeoRecorridos: const Duration(milliseconds: 10),
      servicioPerfilPublico: tarjetas,
      crearControladorVideo: VideoIntroductorioFalso.new,
      crearControladorComoFunciona: controladorDePrueba,
      crearControladorLexus: lexusDeLaAplicacion
          ? null
          : () => controladorLexus = ControladorLexus(
              servicio: lexus,
              conversaciones: ServicioConversacionesLexusVisitante(),
              haySesion: () => false,
            ),
      crearDictado: (alTranscribir) => ControladorDictadoLexus(
        alTranscribir: alTranscribir,
        grabadora: grabadora,
        transcriptor: transcriptor,
        ahora: relojDictado.call,
        crearTemporizador: relojDictado.crearTemporizador,
      ),
      crearControladorPqrs: () => ControladorPqrs(
        servicioPqrs: pqrs,
        servicioStorage: storage,
        obtenerUid: () => null,
        obtenerCorreo: () => null,
      ),
      flujoSesion: sesion.stream,
    );
  }

  Future<void> cerrar() async {
    await pqrs.flujo.close();
    await sesion.close();
  }
}
