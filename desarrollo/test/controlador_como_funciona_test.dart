import 'dart:async';
import 'dart:math' as math;

import 'package:desarrollo/controlador/controlador_como_funciona.dart';
import 'package:desarrollo/controlador/servicio_pantalla.dart';
import 'package:desarrollo/modelo/modelo_capitulo_como_funciona.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'dobles_como_funciona.dart';

void main() {
  final capitulo1 = capitulosComoFunciona[0];
  final capitulo2 = capitulosComoFunciona[1];
  final capitulo3 = capitulosComoFunciona[2];

  setUp(VideoFalso.reiniciarRegistro);

  group('creación de reproductores', () {
    testWidgets('al construirse no crea ningún reproductor', (tester) async {
      final controlador = controladorDePrueba();

      expect(VideoFalso.creados, isEmpty);
      expect(controlador.capituloActivo, isNull);
      expect(controlador.video, isNull);
      for (final capitulo in capitulosComoFunciona) {
        expect(controlador.estadoDe(capitulo), EstadoReproduccion.inactivo);
      }
      controlador.dispose();
    });

    testWidgets('reproducir pasa por "cargando", queda "listo" y arranca con sonido y sin repetir', (tester) async {
      final retener = Completer<void>();
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(retenerInicio: retener));
      final estados = <EstadoReproduccion>[];
      controlador.addListener(() => estados.add(controlador.estadoDe(capitulo3)));

      final futuro = controlador.reproducir(capitulo3);
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.cargando);
      expect(controlador.capituloActivo, capitulo3);
      expect(controlador.estadoDe(capitulo1), EstadoReproduccion.inactivo);
      final video = VideoFalso.creados.single;
      expect(video.llamadas, ['initialize']);

      retener.complete();
      await futuro;

      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.listo);
      expect(controlador.video, same(video));
      // El volumen y el loop se fijan antes de reproducir.
      expect(video.llamadas, ['initialize', 'volumen 1.0', 'loop false', 'play']);
      expect(video.value.isPlaying, isTrue);
      expect(video.value.volume, 1);
      expect(video.value.isLooping, isFalse);
      expect(estados.first, EstadoReproduccion.cargando);
      expect(estados, contains(EstadoReproduccion.listo));

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('un segundo toque durante la carga no crea otro reproductor', (tester) async {
      final retener = Completer<void>();
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(retenerInicio: retener));

      final primero = controlador.reproducir(capitulo3);
      final segundo = controlador.reproducir(capitulo3);
      retener.complete();
      await Future.wait([primero, segundo]);

      expect(VideoFalso.creados, hasLength(1));
      expect(VideoFalso.creados.single.veces('play'), 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si el capítulo ya está listo, reproducir reanuda sin crear otro reproductor', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      await controlador.pausar();
      final video = VideoFalso.creados.single;
      expect(video.value.isPlaying, isFalse);

      await controlador.reproducir(capitulo3);

      expect(VideoFalso.creados, hasLength(1));
      expect(video.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si el video había terminado, reproducir lo repite desde el principio', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;
      video.completar();

      await controlador.reproducir(capitulo3);

      expect(VideoFalso.creados, hasLength(1));
      expect(video.llamadas.where((l) => l.startsWith('seekTo')), ['seekTo 0']);
      expect(video.value.isPlaying, isTrue);
      expect(video.value.isCompleted, isFalse);

      controlador.dispose();
      await tester.pump();
    });
  });

  group('un solo reproductor a la vez', () {
    testWidgets('al cambiar de capítulo el anterior se pausa y se libera tras el fotograma', (tester) async {
      var sonandoAlMismoTiempo = 0;
      late ControladorComoFunciona controlador;
      void vigilar() {
        sonandoAlMismoTiempo = math.max(sonandoAlMismoTiempo, VideoFalso.vivos.where((v) => v.value.isPlaying).length);
      }

      controlador = controladorDePrueba(
        crear: (capitulo) => VideoFalso(duracion: capitulo.duracion)..addListener(vigilar),
      );
      await controlador.reproducir(capitulo3);
      final primero = VideoFalso.creados.single;

      final futuro = controlador.reproducir(capitulo1);
      // El anterior queda pausado y fuera de escena de inmediato…
      expect(primero.llamadas, contains('pause'));
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.inactivo);
      // …pero no se libera hasta dibujar el siguiente fotograma.
      expect(primero.liberado, isFalse);
      await futuro;
      expect(VideoFalso.creados, hasLength(2));

      await tester.pump();
      expect(primero.liberado, isTrue);
      expect(primero.veces('dispose'), 1);
      expect(VideoFalso.vivos, [VideoFalso.creados.last]);
      expect(controlador.estadoDe(capitulo1), EstadoReproduccion.listo);
      expect(sonandoAlMismoTiempo, 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('un initialize tardío de un reproductor descartado se ignora (termina antes del fotograma)', (
      tester,
    ) async {
      final retenerPrimero = Completer<void>();
      var creados = 0;
      final controlador = controladorDePrueba(
        crear: (_) => VideoFalso(retenerInicio: creados++ == 0 ? retenerPrimero : null),
      );

      final primero = controlador.reproducir(capitulo1);
      final segundo = controlador.reproducir(capitulo2);
      // El primero termina de cargar cuando ya fue reemplazado.
      retenerPrimero.complete();
      await Future.wait([primero, segundo]);
      await tester.pump();

      final video1 = VideoFalso.creados[0];
      final video2 = VideoFalso.creados[1];
      expect(video1.llamadas, isNot(contains('play')));
      expect(video1.llamadas.any((l) => l.startsWith('volumen')), isFalse);
      expect(video1.liberado, isTrue);
      expect(video1.veces('dispose'), 1);
      expect(controlador.video, same(video2));
      expect(controlador.estadoDe(capitulo2), EstadoReproduccion.listo);
      expect(controlador.estadoDe(capitulo1), EstadoReproduccion.inactivo);
      expect(video2.value.isPlaying, isTrue);
      expect(tester.takeException(), isNull);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('un initialize tardío de un reproductor descartado se ignora (termina después del fotograma)', (
      tester,
    ) async {
      final retenerPrimero = Completer<void>();
      var creados = 0;
      final controlador = controladorDePrueba(
        crear: (_) => VideoFalso(retenerInicio: creados++ == 0 ? retenerPrimero : null),
      );

      final primero = controlador.reproducir(capitulo1);
      await controlador.reproducir(capitulo2);
      await tester.pump();
      final video1 = VideoFalso.creados[0];
      expect(video1.liberado, isTrue);

      retenerPrimero.complete();
      await primero;
      await tester.pump();

      expect(video1.llamadas, ['initialize', 'pause', 'dispose']);
      expect(controlador.estadoDe(capitulo2), EstadoReproduccion.listo);
      expect(VideoFalso.vivos, hasLength(1));
      expect(tester.takeException(), isNull);

      controlador.dispose();
      await tester.pump();
    });
  });

  group('errores y reintentos', () {
    testWidgets('si el video no carga, el capítulo queda en error', (tester) async {
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(fallaAlIniciar: true));

      await controlador.reproducir(capitulo3);

      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.error);
      expect(controlador.capituloActivo, capitulo3);
      expect(controlador.estadoDe(capitulo1), EstadoReproduccion.inactivo);

      controlador.dispose();
      await tester.pump();
      expect(VideoFalso.vivos, isEmpty);
    });

    testWidgets('si la carga tarda más de 25 segundos, termina en error', (tester) async {
      final retener = Completer<void>();
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(retenerInicio: retener));

      final futuro = controlador.reproducir(capitulo3);
      await tester.pump(const Duration(seconds: 24));
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.cargando);

      await tester.pump(const Duration(seconds: 2));
      await futuro;
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.error);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('reintentar crea un reproductor nuevo y libera el fallido', (tester) async {
      var creados = 0;
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(fallaAlIniciar: creados++ == 0));
      await controlador.reproducir(capitulo3);
      final fallido = VideoFalso.creados.single;
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.error);

      await controlador.reintentar(capitulo3);
      await tester.pump();

      expect(VideoFalso.creados, hasLength(2));
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.listo);
      expect(fallido.liberado, isTrue);
      expect(VideoFalso.vivos, [VideoFalso.creados.last]);
      expect(VideoFalso.creados.last.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('reproducir sobre un capítulo con error también lo intenta de nuevo', (tester) async {
      var creados = 0;
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(fallaAlIniciar: creados++ == 0));
      await controlador.reproducir(capitulo3);

      await controlador.reproducir(capitulo3);

      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.listo);
      expect(VideoFalso.creados, hasLength(2));

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('en Web, un error después de cargar no oculta el video (los controles nativos siguen sirviendo)', (
      tester,
    ) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      // Por ejemplo, el navegador rechazó la reproducción automática.
      video.fallar();

      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.listo);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('en Web, un error antes de cargar sí es un error', (tester) async {
      final controlador = controladorDePrueba(navegador: true, crear: (_) => VideoFalso(fallaAlIniciar: true));

      await controlador.reproducir(capitulo3);

      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.error);
      controlador.dispose();
      await tester.pump();
    });

    testWidgets('en Android e iOS, un error durante la reproducción pasa a "error"', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);

      VideoFalso.creados.single.fallar();

      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.error);

      controlador.dispose();
      await tester.pump();
    });
  });

  group('pausar', () {
    testWidgets('no libera el reproductor ni reanuda por su cuenta', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      await controlador.pausar();
      await tester.pump(const Duration(seconds: 5));

      expect(video.value.isPlaying, isFalse);
      expect(video.liberado, isFalse);
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.listo);
      expect(video.veces('play'), 1);

      // Solo el usuario lo reanuda.
      await controlador.alternarReproduccion();
      expect(video.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si se pausa durante la carga, el video no arranca solo al terminar de cargar', (tester) async {
      final retener = Completer<void>();
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(retenerInicio: retener));
      final futuro = controlador.reproducir(capitulo3);

      // Por ejemplo, el usuario cambia de pestaña mientras carga.
      await controlador.pausar();
      retener.complete();
      await futuro;

      final video = VideoFalso.creados.single;
      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.listo);
      expect(video.llamadas, isNot(contains('play')));
      expect(video.value.isPlaying, isFalse);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('un nuevo toque durante la carga cancela la pausa pedida y sí reproduce', (tester) async {
      final retener = Completer<void>();
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(retenerInicio: retener));
      final futuro = controlador.reproducir(capitulo3);
      await controlador.pausar();

      final repeticion = controlador.reproducir(capitulo3);
      retener.complete();
      await Future.wait([futuro, repeticion]);

      expect(VideoFalso.creados.single.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });
  });

  // Al cruzar los 900 px del panel, el motor de Flutter para Web saca el DOM de
  // las vistas de plataforma y lo vuelve a insertar; por especificación, el
  // navegador pausa un elemento multimedia que sale del documento.
  group('reanudar tras reubicar (Web)', () {
    const espera = Duration(milliseconds: 150);

    testWidgets('si el navegador pausa el video al reubicarlo, se reanuda a los 150 ms y una sola vez', (tester) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;
      expect(video.value.isPlaying, isTrue);
      final reproduccionesIniciales = video.veces('play');

      controlador.reanudarTrasReubicar();
      video.simularPausaDelNavegador();

      // El evento de pausa va en cola: hasta pasados los 150 ms no se mira.
      await tester.pump(const Duration(milliseconds: 149));
      expect(video.value.isPlaying, isFalse);
      expect(video.veces('play'), reproduccionesIniciales);

      await tester.pump(const Duration(milliseconds: 1));
      expect(video.value.isPlaying, isTrue);
      expect(video.veces('play'), reproduccionesIniciales + 1);

      // No se repite.
      await tester.pump(const Duration(seconds: 2));
      expect(video.veces('play'), reproduccionesIniciales + 1);
      // Es la misma instancia: no se creó ni se liberó nada.
      expect(VideoFalso.creados, hasLength(1));
      expect(video.liberado, isFalse);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si ya estaba en pausa al llamar, no se reanuda', (tester) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;
      await controlador.pausar();
      final reproducciones = video.veces('play');

      controlador.reanudarTrasReubicar();
      await tester.pump(const Duration(seconds: 1));

      expect(video.veces('play'), reproducciones);
      expect(video.value.isPlaying, isFalse);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si el video no está listo (carga o error), no hace nada', (tester) async {
      final retener = Completer<void>();
      final controlador = controladorDePrueba(navegador: true, crear: (_) => VideoFalso(retenerInicio: retener));

      controlador.reanudarTrasReubicar();
      final futuro = controlador.reproducir(capitulo3);
      controlador.reanudarTrasReubicar();
      retener.complete();
      await futuro;
      await tester.pump(const Duration(seconds: 1));

      expect(VideoFalso.creados.single.veces('play'), 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('en Android e iOS no hace nada', (tester) async {
      final controlador = controladorDePrueba();
      expect(controlador.controlesDelNavegador, isFalse);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      controlador.reanudarTrasReubicar();
      video.simularPausaDelNavegador();
      await tester.pump(const Duration(seconds: 1));

      expect(video.value.isPlaying, isFalse);
      expect(video.veces('play'), 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si a los 150 ms el video sigue sonando, no se vuelve a pedir reproducir', (tester) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      // El navegador no llegó a pausarlo.
      controlador.reanudarTrasReubicar();
      await tester.pump(espera);

      expect(video.veces('play'), 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si a los 150 ms el video ya se reanudó por su cuenta, no se vuelve a pedir reproducir', (
      tester,
    ) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      controlador.reanudarTrasReubicar();
      video.simularPausaDelNavegador();
      // Por ejemplo, el usuario tocó el botón de reproducir del navegador.
      video.value = video.value.copyWith(isPlaying: true);
      await tester.pump(espera);

      expect(video.veces('play'), 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('una pausa de la app en ese lapso (pestaña oculta) cancela la reanudación', (tester) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      controlador.reanudarTrasReubicar();
      video.simularPausaDelNavegador();
      await controlador.pausar();
      await tester.pump(const Duration(seconds: 1));

      // Un video escondido no debe volver a sonar (I5).
      expect(video.veces('play'), 1);
      expect(video.value.isPlaying, isFalse);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si en ese lapso se pasa a otro capítulo, el anterior no se reanuda', (tester) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final primero = VideoFalso.creados.single;

      controlador.reanudarTrasReubicar();
      primero.simularPausaDelNavegador();
      await controlador.reproducir(capitulo1);
      await tester.pump(const Duration(seconds: 1));

      final segundo = VideoFalso.creados.last;
      expect(primero.veces('play'), 1);
      expect(primero.liberado, isTrue);
      // El nuevo no recibe ninguna orden extra de reproducir.
      expect(segundo.veces('play'), 1);
      expect(segundo.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si el controlador se libera en ese lapso, no hace nada ni falla', (tester) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      controlador.reanudarTrasReubicar();
      video.simularPausaDelNavegador();
      controlador.dispose();
      await tester.pump(const Duration(seconds: 1));

      expect(video.veces('play'), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dos reubicaciones seguidas reanudan una sola vez', (tester) async {
      final controlador = controladorDePrueba(navegador: true);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      // Por ejemplo, una tableta que gira de un lado a otro.
      controlador.reanudarTrasReubicar();
      controlador.reanudarTrasReubicar();
      video.simularPausaDelNavegador();
      await tester.pump(const Duration(seconds: 1));

      expect(video.veces('play'), 2);
      expect(video.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si falla al reanudar, el error se ignora', (tester) async {
      final controlador = controladorDePrueba(navegador: true, crear: (_) => _VideoQueFallaAlReanudar());
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single as _VideoQueFallaAlReanudar;
      video.fallaEnPlay = true;

      controlador.reanudarTrasReubicar();
      video.simularPausaDelNavegador();
      await tester.pump(const Duration(seconds: 1));

      expect(video.veces('play'), 2);
      expect(tester.takeException(), isNull);

      controlador.dispose();
      await tester.pump();
    });
  });

  group('pantalla encendida', () {
    testWidgets('se pide solo al cambiar el estado de reproducción y se quita al pausar', (tester) async {
      final pantalla = PantallaFalsa();
      final controlador = controladorDePrueba(pantalla: pantalla);
      expect(pantalla.llamadas, isEmpty);

      await controlador.reproducir(capitulo3);
      expect(pantalla.llamadas, [true]);

      // El avance del video no repite la petición.
      final video = VideoFalso.creados.single;
      for (var segundo = 1; segundo <= 5; segundo++) {
        video.avanzarA(Duration(seconds: segundo));
      }
      expect(pantalla.llamadas, [true]);

      await controlador.pausar();
      expect(pantalla.llamadas, [true, false]);

      await controlador.alternarReproduccion();
      expect(pantalla.llamadas, [true, false, true]);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('al cambiar de capítulo se apaga la del anterior antes de encender la del siguiente', (tester) async {
      final pantalla = PantallaFalsa();
      final controlador = controladorDePrueba(pantalla: pantalla);
      await controlador.reproducir(capitulo3);

      await controlador.reproducir(capitulo1);

      expect(pantalla.llamadas, [true, false, true]);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('al liberar el controlador se apaga', (tester) async {
      final pantalla = PantallaFalsa();
      final controlador = controladorDePrueba(pantalla: pantalla);
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      controlador.dispose();
      await tester.pump();

      expect(pantalla.llamadas, [true, false]);
      expect(video.llamadas, contains('pause'));
      expect(video.liberado, isTrue);
    });

    testWidgets('si nunca se reprodujo nada, liberar el controlador no toca la pantalla', (tester) async {
      final pantalla = PantallaFalsa();
      controladorDePrueba(pantalla: pantalla).dispose();
      await tester.pump();

      expect(pantalla.llamadas, isEmpty);
    });

    testWidgets('un error de la plataforma también apaga la pantalla encendida', (tester) async {
      final pantalla = PantallaFalsa();
      final controlador = controladorDePrueba(pantalla: pantalla, navegador: true);
      await controlador.reproducir(capitulo3);

      VideoFalso.creados.single.fallar();

      expect(pantalla.llamadas, [true, false]);

      controlador.dispose();
      await tester.pump();
    });
  });

  group('controles', () {
    testWidgets('alternarReproduccion pausa y reanuda', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      await controlador.alternarReproduccion();
      expect(video.value.isPlaying, isFalse);
      await controlador.alternarReproduccion();
      expect(video.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si el video terminó, alternarReproduccion lo reinicia', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;
      video.completar();

      await controlador.alternarReproduccion();

      expect(video.llamadas.where((l) => l.startsWith('seekTo')), ['seekTo 0']);
      expect(video.value.isPlaying, isTrue);
      expect(video.value.position, Duration.zero);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('reiniciar vuelve al segundo cero y reproduce', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single..avanzarA(const Duration(seconds: 20));

      await controlador.reiniciar();

      expect(video.value.position, Duration.zero);
      expect(video.value.isPlaying, isTrue);
      expect(video.llamadas.last, 'play');

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('alternarSonido silencia y devuelve el sonido, y avisa a la interfaz', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;
      var avisos = 0;
      controlador.addListener(() => avisos++);
      expect(controlador.silenciado, isFalse);

      await controlador.alternarSonido();
      expect(video.value.volume, 0);
      expect(controlador.silenciado, isTrue);
      expect(avisos, 1);

      await controlador.alternarSonido();
      expect(video.value.volume, 1);
      expect(controlador.silenciado, isFalse);
      expect(avisos, 2);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('saltar avanza y retrocede sin salirse del video', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo1);
      final video = VideoFalso.creados.single..avanzarA(const Duration(seconds: 10));

      await controlador.saltar(const Duration(seconds: 5));
      expect(video.value.position, const Duration(seconds: 15));

      await controlador.saltar(const Duration(seconds: -20));
      expect(video.value.position, Duration.zero);

      video.avanzarA(video.value.duration - const Duration(seconds: 2));
      await controlador.saltar(const Duration(seconds: 5));
      expect(video.value.position, video.value.duration);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('sin un video listo, los controles no hacen nada ni fallan', (tester) async {
      final controlador = controladorDePrueba();

      await controlador.alternarReproduccion();
      await controlador.reiniciar();
      await controlador.alternarSonido();
      await controlador.saltar(const Duration(seconds: 5));
      await controlador.buscar(const Duration(seconds: 5));
      await controlador.pausar();

      expect(VideoFalso.creados, isEmpty);
      expect(controlador.silenciado, isFalse);
      controlador.dispose();
    });

    testWidgets('detener vuelve a la portada y libera el reproductor', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;

      controlador.detener();
      await tester.pump();

      expect(controlador.estadoDe(capitulo3), EstadoReproduccion.inactivo);
      expect(controlador.capituloActivo, isNull);
      expect(controlador.video, isNull);
      expect(video.liberado, isTrue);

      controlador.dispose();
    });
  });

  group('avisos a la interfaz', () {
    testWidgets('el avance del video no genera avisos; reproducir, completar y silenciar sí', (tester) async {
      final controlador = controladorDePrueba();
      await controlador.reproducir(capitulo3);
      final video = VideoFalso.creados.single;
      var avisos = 0;
      controlador.addListener(() => avisos++);

      for (var segundo = 1; segundo <= 20; segundo++) {
        video.avanzarA(Duration(seconds: segundo));
      }
      expect(avisos, 0);

      video.completar();
      expect(avisos, 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('tras liberar el controlador un reproductor tardío ya no lo avisa', (tester) async {
      final retener = Completer<void>();
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(retenerInicio: retener));
      final futuro = controlador.reproducir(capitulo3);

      controlador.dispose();
      retener.complete();
      await futuro;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(VideoFalso.vivos, isEmpty);
    });
  });

  group('reproductor real por defecto', () {
    test('no hereda mixWithOthers y activa los controles del navegador sin descarga', () {
      final video = ControladorComoFunciona.crearVideoPorDefecto(capitulo3);
      addTearDown(video.dispose);

      expect(video.dataSource, capitulo3.rutaVideo);
      expect(video.dataSourceType, DataSourceType.asset);
      final opciones = video.videoPlayerOptions!;
      // Sin esto, en Android heredaría la bandera compartida del video del Inicio.
      expect(opciones.mixWithOthers, isFalse);
      final web = opciones.webOptions!;
      expect(web.controls.enabled, isTrue);
      expect(web.controls.allowDownload, isFalse);
      expect(web.controls.allowFullscreen, isTrue);
      expect(web.controls.allowPlaybackRate, isTrue);
      expect(web.controls.allowPictureInPicture, isFalse);
      expect(web.allowContextMenu, isFalse);
      expect(web.allowRemotePlayback, isFalse);
    });

    test('los controles del navegador se activan solo en Web por defecto', () {
      // En `flutter test` no es Web.
      expect(ControladorComoFunciona().controlesDelNavegador, kIsWeb);
      expect(ControladorComoFunciona(controlesDelNavegador: true).controlesDelNavegador, isTrue);
    });
  });

  group('ServicioPantalla', () {
    const canal = MethodChannel(ServicioPantalla.canal);

    testWidgets('en Android manda el booleano por el canal', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final llamadas = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, (llamada) async {
        llamadas.add(llamada);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, null));

      try {
        await const ServicioPantalla().mantenerEncendida(true);
        await const ServicioPantalla().mantenerEncendida(false);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(llamadas.map((l) => l.method), ['mantenerEncendida', 'mantenerEncendida']);
      expect(llamadas.map((l) => l.arguments), [true, false]);
    });

    testWidgets('en iOS no hace nada: video_player ya mantiene la pantalla encendida', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final llamadas = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, (llamada) async {
        llamadas.add(llamada);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, null));

      try {
        await const ServicioPantalla().mantenerEncendida(true);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(llamadas, isEmpty);
    });

    testWidgets('si la parte nativa no existe, el fallo se ignora', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, (llamada) async {
        throw MissingPluginException();
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, null));

      try {
        await expectLater(const ServicioPantalla().mantenerEncendida(true), completes);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('si la plataforma responde con un error, el fallo se ignora', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, (llamada) async {
        throw PlatformException(code: 'argumento_invalido', message: 'Se esperaba un booleano.');
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, null));

      try {
        await expectLater(const ServicioPantalla().mantenerEncendida(true), completes);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}

/// Reproductor cuyo `play()` puede fallar, para comprobar que un error al
/// reanudar tras reubicar no se propaga.
class _VideoQueFallaAlReanudar extends VideoFalso {
  bool fallaEnPlay = false;

  @override
  Future<void> play() async {
    if (!fallaEnPlay) return super.play();
    llamadas.add('play');
    throw PlatformException(code: 'no_permitido', message: 'El navegador rechazó la reproducción.');
  }
}
