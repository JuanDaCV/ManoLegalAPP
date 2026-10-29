import 'package:desarrollo/configuracion/configuracion_lexus.dart';
import 'package:desarrollo/controlador/controlador_dictado_lexus.dart';
import 'package:desarrollo/controlador/controlador_lexus.dart';
import 'package:desarrollo/controlador/servicio_grabacion_audio.dart';
import 'package:desarrollo/modelo/error_lexus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_dictado_lexus.dart';
import 'dobles_lexus.dart';

void main() {
  late GrabacionAudioFalsa grabadora;
  late TranscriptorFalso transcriptor;
  late RelojDictadoFalso reloj;
  late List<String> entregados;
  late ControladorDictadoLexus dictado;

  setUp(() {
    grabadora = GrabacionAudioFalsa();
    transcriptor = TranscriptorFalso();
    reloj = RelojDictadoFalso();
    entregados = [];
    dictado = ControladorDictadoLexus(
      alTranscribir: entregados.add,
      grabadora: grabadora,
      transcriptor: transcriptor,
      ahora: reloj.call,
      crearTemporizador: reloj.crearTemporizador,
    );
  });

  tearDown(() => dictado.dispose());

  /// Empieza a grabar y deja pasar [duracion] antes de que se detenga.
  Future<void> grabar([Duration duracion = const Duration(seconds: 5)]) async {
    await dictado.alternar();
    expect(dictado.estado, EstadoDictadoLexus.grabando);
    reloj.tic(duracion);
  }

  group('permiso', () {
    test('si se deniega, no graba y deja el error de permiso', () async {
      grabadora.permiso = PermisoMicrofono.denegado;

      await dictado.alternar();

      expect(dictado.estado, EstadoDictadoLexus.inactivo);
      expect(dictado.ultimoError?.tipo, TipoErrorDictadoLexus.permisoDenegado);
      expect(grabadora.cuenta('iniciar'), 0);
      expect(transcriptor.recibidos, isEmpty);
      expect(entregados, isEmpty);
    });

    test('si no hay micrófono, deja el error "no disponible"', () async {
      grabadora.permiso = PermisoMicrofono.noDisponible;

      await dictado.alternar();

      expect(dictado.ultimoError?.tipo, TipoErrorDictadoLexus.noDisponible);
      expect(dictado.estado, EstadoDictadoLexus.inactivo);
    });

    test('una excepción al pedir el permiso no se propaga', () async {
      grabadora.errorAlPedirPermiso = StateError('plugin');

      await dictado.alternar();

      expect(dictado.ultimoError?.tipo, TipoErrorDictadoLexus.noDisponible);
      expect(dictado.estado, EstadoDictadoLexus.inactivo);
    });

    test('si la grabadora no arranca, deja "no disponible"', () async {
      grabadora.iniciarCorrecto = false;

      await dictado.alternar();

      expect(dictado.ultimoError?.tipo, TipoErrorDictadoLexus.noDisponible);
      expect(dictado.estado, EstadoDictadoLexus.inactivo);
      expect(reloj.hayTemporizadorActivo, isFalse);
    });

    test('un nuevo intento borra el error anterior', () async {
      grabadora.permiso = PermisoMicrofono.denegado;
      await dictado.alternar();
      expect(dictado.ultimoError, isNotNull);

      grabadora.permiso = PermisoMicrofono.concedido;
      await dictado.alternar();

      expect(dictado.ultimoError, isNull);
      expect(dictado.estado, EstadoDictadoLexus.grabando);
    });
  });

  group('flujo normal', () {
    test('graba, transcribe y entrega el texto por la devolución', () async {
      await grabar();

      await dictado.alternar();

      expect(dictado.estado, EstadoDictadoLexus.inactivo);
      expect(dictado.ultimoError, isNull);
      expect(entregados, ['Me despidieron sin justa causa']);
      expect(transcriptor.recibidos.single, grabadora.wav);
      expect(grabadora.cuenta('detener'), 1);
    });

    test('recorta los espacios del texto transcrito', () async {
      transcriptor.texto = '  hola  \n';
      await grabar();

      await dictado.alternar();

      expect(entregados, ['hola']);
    });

    test('el dictado nunca envía al chat', () async {
      final servicioChat = ServicioLexusDoble();
      final historial = ServicioConversacionesLexusDoble();
      final chat = ControladorLexus(
        servicio: servicioChat,
        conversaciones: historial,
        haySesion: () => true,
      );
      addTearDown(chat.dispose);
      await chat.cargaInicial;
      await grabar();

      await dictado.alternar();

      expect(entregados, isNotEmpty);
      expect(servicioChat.llamadas, isEmpty);
      expect(historial.llamadasDe('guardarEnvio'), isEmpty);
      expect(historial.llamadasDe('guardarEnvio:nueva'), isEmpty);
      expect(chat.hayConversacion, isFalse);
    });

    test('mientras transcribe, otro toque se ignora', () async {
      final espera = transcriptor.retener();
      await grabar();

      final primero = dictado.alternar();
      await pumpEventQueue();
      expect(dictado.estado, EstadoDictadoLexus.transcribiendo);
      await dictado.alternar();
      expect(transcriptor.recibidos, hasLength(1));

      espera.complete('texto');
      await primero;
      expect(entregados, ['texto']);
      expect(dictado.estado, EstadoDictadoLexus.inactivo);
    });
  });

  group('cuenta atrás', () {
    test('al empezar queda el máximo y disminuye con cada segundo', () async {
      await dictado.alternar();
      expect(dictado.restante, ConfiguracionLexus.duracionMaximaAudio);
      expect(dictado.restante, const Duration(minutes: 2));

      reloj.tic();
      expect(dictado.restante, const Duration(minutes: 1, seconds: 59));

      reloj.tic(const Duration(seconds: 14));
      expect(dictado.restante, const Duration(minutes: 1, seconds: 45));
    });

    test('se mide con el reloj aunque el sistema retrase los tics', () async {
      await dictado.alternar();

      reloj.tic(const Duration(seconds: 30)); // Un solo tic tardío.

      expect(dictado.restante, const Duration(seconds: 90));
    });

    test('a los 2:00 se detiene sola y transcribe, sin enviar', () async {
      await dictado.alternar();

      reloj.tic(const Duration(minutes: 1, seconds: 59));
      expect(dictado.estado, EstadoDictadoLexus.grabando);
      expect(transcriptor.recibidos, isEmpty);

      reloj.tic();
      await pumpEventQueue();

      expect(dictado.restante, ConfiguracionLexus.duracionMaximaAudio);
      expect(dictado.estado, EstadoDictadoLexus.inactivo);
      expect(transcriptor.recibidos, hasLength(1));
      expect(entregados, ['Me despidieron sin justa causa']);
      expect(reloj.hayTemporizadorActivo, isFalse);
    });
  });

  group('errores', () {
    test('menos de 1 s se descarta sin llamar al transcriptor', () async {
      await dictado.alternar();
      reloj.tic(const Duration(milliseconds: 600));

      await dictado.alternar();

      expect(dictado.estado, EstadoDictadoLexus.inactivo);
      expect(dictado.ultimoError?.tipo, TipoErrorDictadoLexus.demasiadoCorto);
      expect(transcriptor.recibidos, isEmpty);
      expect(entregados, isEmpty);
      expect(grabadora.cuenta('cancelar'), 1);
      expect(grabadora.cuenta('detener'), 0);
    });

    test('exactamente 1 s ya se transcribe', () async {
      await grabar(ConfiguracionLexus.duracionMinimaAudio);

      await dictado.alternar();

      expect(transcriptor.recibidos, hasLength(1));
      expect(dictado.ultimoError, isNull);
    });

    test(
      'si la transcripción falla, deja el error y vuelve a inactivo',
      () async {
        transcriptor.error = const ErrorLexus(TipoErrorLexus.sinConexion);
        await grabar();

        await dictado.alternar();

        expect(dictado.estado, EstadoDictadoLexus.inactivo);
        expect(
          dictado.ultimoError?.tipo,
          TipoErrorDictadoLexus.transcripcionFallida,
        );
        expect(dictado.ultimoError?.causa, TipoErrorLexus.sinConexion);
        expect(entregados, isEmpty);
      },
    );

    test('un fallo inesperado del transcriptor tampoco se propaga', () async {
      transcriptor.error = StateError('inesperado');
      await grabar();

      await dictado.alternar();

      expect(
        dictado.ultimoError?.tipo,
        TipoErrorDictadoLexus.transcripcionFallida,
      );
      expect(dictado.ultimoError?.causa, TipoErrorLexus.interno);
      expect(dictado.estado, EstadoDictadoLexus.inactivo);
    });

    test('una transcripción vacía deja el error "sin texto"', () async {
      transcriptor.texto = '   ';
      await grabar();

      await dictado.alternar();

      expect(dictado.estado, EstadoDictadoLexus.inactivo);
      expect(dictado.ultimoError?.tipo, TipoErrorDictadoLexus.sinTexto);
      expect(entregados, isEmpty);
    });

    test('si no hay audio al detener, deja "no disponible"', () async {
      grabadora.wav = null;
      await grabar();

      await dictado.alternar();

      expect(dictado.ultimoError?.tipo, TipoErrorDictadoLexus.noDisponible);
      expect(transcriptor.recibidos, isEmpty);
    });

    test('cada fallo es un objeto nuevo, aunque se repita el tipo', () async {
      grabadora.permiso = PermisoMicrofono.denegado;
      await dictado.alternar();
      final primero = dictado.ultimoError;

      await dictado.alternar();

      expect(dictado.ultimoError?.tipo, primero?.tipo);
      expect(identical(dictado.ultimoError, primero), isFalse);
    });

    test('una devolución que lanza no rompe el controlador', () async {
      final conFallo = ControladorDictadoLexus(
        alTranscribir: (_) => throw StateError('vista cerrada'),
        grabadora: grabadora,
        transcriptor: transcriptor,
        ahora: reloj.call,
        crearTemporizador: reloj.crearTemporizador,
      );
      addTearDown(conFallo.dispose);
      await conFallo.alternar();
      reloj.tic(const Duration(seconds: 3));

      await conFallo.alternar();

      expect(conFallo.estado, EstadoDictadoLexus.inactivo);
    });
  });

  group('cancelar y dispose', () {
    test('cancelar descarta la grabación sin transcribir', () async {
      await grabar();

      await dictado.cancelar();

      expect(dictado.estado, EstadoDictadoLexus.inactivo);
      expect(grabadora.cuenta('cancelar'), 1);
      expect(transcriptor.recibidos, isEmpty);
      expect(entregados, isEmpty);
      expect(dictado.ultimoError, isNull);
      expect(reloj.hayTemporizadorActivo, isFalse);
    });

    test('cancelar durante la transcripción descarta el resultado', () async {
      final espera = transcriptor.retener();
      await grabar();
      final enCurso = dictado.alternar();
      await pumpEventQueue();

      await dictado.cancelar();
      espera.complete('texto tardío');
      await enCurso;

      expect(entregados, isEmpty);
      expect(dictado.estado, EstadoDictadoLexus.inactivo);
    });

    test(
      'dispose durante la grabación la cancela y libera la grabadora',
      () async {
        await grabar();

        dictado.dispose();
        await pumpEventQueue();

        expect(grabadora.cuenta('cancelar'), greaterThanOrEqualTo(1));
        expect(grabadora.cuenta('liberar'), 1);
        expect(reloj.hayTemporizadorActivo, isFalse);
        expect(transcriptor.recibidos, isEmpty);
      },
    );

    test('dispose mientras se transcribe no entrega el texto', () async {
      final espera = transcriptor.retener();
      await grabar();
      final enCurso = dictado.alternar();
      await pumpEventQueue();

      dictado.dispose();
      espera.complete('texto tardío');
      await enCurso;

      expect(entregados, isEmpty);
    });

    test('dispose sin haber grabado no toca la grabadora', () async {
      dictado.dispose();
      await pumpEventQueue();

      expect(grabadora.llamadas, isEmpty);
    });
  });
}
