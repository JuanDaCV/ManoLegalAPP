import 'dart:async';

import 'package:desarrollo/controlador/controlador_como_funciona.dart';
import 'package:desarrollo/modelo/modelo_capitulo_como_funciona.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/boton_reproducir.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/controles_video_movil.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/escenario_web.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/estados_reproductor.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/estilos_como_funciona.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/pantalla_completa_video.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/portada_capitulo.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/reproductor_capitulo.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/video_movil.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'dobles_como_funciona.dart';

void main() {
  // El capítulo 3 es horizontal (16:9) y el 2, vertical (9:16).
  final horizontal = capitulosComoFunciona[2];
  final vertical = capitulosComoFunciona[1];

  late FocusNode foco;

  setUp(() {
    // Sin red en las pruebas: el texto usa la tipografía del tema.
    EstilosComoFunciona.usarTipografiaDeMarca = false;
    VideoFalso.reiniciarRegistro();
    foco = FocusNode(debugLabel: 'prueba');
    addTearDown(foco.dispose);
    addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
  });

  /// Monta un solo recuadro de capítulo con la proporción de su video.
  Future<void> montar(
    WidgetTester tester, {
    required ControladorComoFunciona controlador,
    ModeloCapituloComoFunciona? capitulo,
    double ancho = 400,
    bool lectorDePantalla = false,
    Widget Function(Widget recuadro)? envolver,
  }) async {
    final cap = capitulo ?? horizontal;
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget recuadro = SizedBox(
      width: ancho,
      child: AspectRatio(
        aspectRatio: cap.proporcion,
        child: ReproductorCapitulo(capitulo: cap, controlador: controlador, focoReproducir: foco),
      ),
    );
    if (envolver != null) recuadro = envolver(recuadro);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context).copyWith(accessibleNavigation: lectorDePantalla),
          child: hijo!,
        ),
        home: Scaffold(body: Center(child: recuadro)),
      ),
    );
  }

  /// Toca la portada y deja que el video cargue y arranque.
  Future<void> reproducir(WidgetTester tester) async {
    await tester.tap(find.byType(PortadaInteractiva));
    await tester.pump();
    await tester.pump();
  }

  Finder controles(Key clave) => find.byKey(clave);
  const botonCentral = ValueKey('boton_central');
  const botonPlayPausa = ValueKey('boton_play_pausa');
  const botonSonido = ValueKey('boton_sonido');
  const botonPantallaCompleta = ValueKey('boton_pantalla_completa');
  const botonSalir = ValueKey('boton_salir');

  /// Opacidad de la capa de controles (visible u oculta).
  double opacidadDeControles(WidgetTester tester) {
    return tester
        .widget<AnimatedOpacity>(
          find.descendant(of: find.byType(ControlesVideoMovil), matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
  }

  group('portada', () {
    testWidgets('muestra la portada con el botón, la duración y las etiquetas para lectores de pantalla', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);

      expect(find.byType(PortadaInteractiva), findsOneWidget);
      expect(find.byType(BotonReproducir), findsOneWidget);
      expect(find.text('0:48'), findsOneWidget);
      expect(find.byTooltip('Reproducir video'), findsOneWidget);
      expect(VideoFalso.creados, isEmpty);
      expect(find.byType(VideoPlayer), findsNothing);

      expect(
        tester.getSemantics(find.bySemanticsLabel(horizontal.etiquetaReproducir)),
        isSemantics(label: horizontal.etiquetaReproducir, isButton: true, hasTapAction: true),
      );

      controlador.dispose();
      handle.dispose();
    });

    testWidgets('la imagen es la portada del capítulo, decodificada a un tamaño acorde con el recuadro', (
      tester,
    ) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 400);

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.fit, BoxFit.cover);
      expect(imagen.gaplessPlayback, isTrue);
      expect(imagen.excludeFromSemantics, isTrue);
      final redimensionada = imagen.image as ResizeImage;
      expect((redimensionada.imageProvider as AssetImage).assetName, horizontal.rutaPortada);
      // 400 px a razón de 1 píxel por punto: el escalón de 540.
      expect(redimensionada.width, 540);

      controlador.dispose();
    });

    test('el ancho de decodificación sube por escalones y nunca pasa del original', () {
      int bucket(double ancho, double razon, {int original = 1920}) =>
          PortadaCapitulo.anchoDeDecodificacion(anchoLogico: ancho, pixelRatio: razon, anchoOriginal: original);

      expect(bucket(288, 1), 360);
      expect(bucket(360, 1), 360);
      expect(bucket(361, 1), 540);
      expect(bucket(356, 2), 720);
      expect(bucket(856, 1), 960);
      expect(bucket(976, 1), 1280);
      expect(bucket(976, 2), 1920);
      expect(bucket(1400, 2), 1920);
      // El capítulo vertical solo mide 1080 px de ancho.
      expect(bucket(405, 3, original: 1080), 1080);
      expect(bucket(300, 2, original: 1080), 720);
    });

    testWidgets('el disco mide 64 px y 56 en recuadros angostos', (tester) async {
      final controlador = controladorDePrueba();
      Size disco() =>
          tester.getSize(find.descendant(of: find.byType(BotonReproducir), matching: find.byType(Container)).last);

      await montar(tester, controlador: controlador, ancho: 600);
      expect(disco(), const Size(64, 64));

      await montar(tester, controlador: controlador, ancho: 300);
      expect(disco(), const Size(56, 56));

      controlador.dispose();
    });

    testWidgets('al pasar el cursor, el disco crece un poco', (tester) async {
      // En escritorio y Web el modo de resaltado es el tradicional (ratón y
      // teclado); en `flutter test` el valor inicial es el de Android (táctil).
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);
      double escala() => tester
          .widget<AnimatedScale>(
            find.descendant(of: find.byType(BotonReproducir), matching: find.byType(AnimatedScale)),
          )
          .scale;
      expect(escala(), 1);

      final cursor = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await cursor.addPointer(location: Offset.zero);
      addTearDown(cursor.removePointer);
      await cursor.moveTo(tester.getCenter(find.byType(PortadaInteractiva)));
      await tester.pump();

      expect(escala(), 1.06);
      expect(tester.widget<BotonReproducir>(find.byType(BotonReproducir)).resaltado, isTrue);

      await cursor.moveTo(const Offset(5, 5));
      await tester.pump();
      expect(escala(), 1);

      controlador.dispose();
    });

    testWidgets('el aro de foco aparece solo con el teclado', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);
      bool enfocado() => tester.widget<BotonReproducir>(find.byType(BotonReproducir)).enfocado;

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      foco.requestFocus();
      await tester.pump();
      expect(foco.hasFocus, isTrue);
      expect(enfocado(), isFalse);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      expect(enfocado(), isTrue);

      controlador.dispose();
    });

    for (final (tecla, nombre) in [
      (LogicalKeyboardKey.enter, 'Enter'),
      (LogicalKeyboardKey.space, 'Espacio'),
      (LogicalKeyboardKey.numpadEnter, 'Enter del teclado numérico'),
    ]) {
      testWidgets('con el foco en la portada, $nombre reproduce el video', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador);
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
        foco.requestFocus();
        await tester.pump();

        await tester.sendKeyEvent(tecla);
        await tester.pump();
        await tester.pump();

        expect(VideoFalso.creados, hasLength(1));
        expect(controlador.estadoDe(horizontal), EstadoReproduccion.listo);

        controlador.dispose();
        await tester.pump();
      });
    }
  });

  group('carga y error', () {
    testWidgets('mientras carga muestra el indicador y anuncia "Cargando video…"', (tester) async {
      final handle = tester.ensureSemantics();
      final retener = Completer<void>();
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(retenerInicio: retener));
      await montar(tester, controlador: controlador);

      await tester.tap(find.byType(PortadaInteractiva));
      await tester.pump();

      expect(controlador.estadoDe(horizontal), EstadoReproduccion.cargando);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Cargando video…')),
        isSemantics(label: 'Cargando video…', isLiveRegion: true),
      );
      expect(find.bySemanticsLabel(horizontal.etiquetaReproducir), findsNothing);

      retener.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(VideoMovil), findsOneWidget);

      controlador.dispose();
      await tester.pump();
      handle.dispose();
    });

    testWidgets('si el video no carga, avisa y ofrece reintentar', (tester) async {
      var creados = 0;
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(fallaAlIniciar: creados++ == 0));
      await montar(tester, controlador: controlador);

      await reproducir(tester);

      expect(find.byType(EstadoErrorVideo), findsOneWidget);
      expect(find.text('No se pudo cargar el video.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
      expect(find.byType(VideoMovil), findsNothing);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(VideoFalso.creados, hasLength(2));
      expect(find.byType(EstadoErrorVideo), findsNothing);
      expect(find.byType(VideoMovil), findsOneWidget);
      expect(VideoFalso.creados.last.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('el aviso de error cabe en un recuadro pequeño con el texto al doble', (tester) async {
      final controlador = controladorDePrueba(crear: (_) => VideoFalso(fallaAlIniciar: true));
      await montar(
        tester,
        controlador: controlador,
        ancho: 260,
        envolver: (recuadro) => MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: recuadro,
        ),
      );

      await reproducir(tester);

      expect(find.byType(EstadoErrorVideo), findsOneWidget);
      expect(tester.takeException(), isNull);

      controlador.dispose();
      await tester.pump();
    });
  });

  group('controles en Android e iOS', () {
    testWidgets('al empezar, la portada cubre el video hasta que avanza y entonces se desvanece', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);
      await reproducir(tester);

      expect(find.byType(VideoPlayer), findsOneWidget);
      final cubierta = find.descendant(of: find.byType(VideoMovil), matching: find.byType(AnimatedOpacity)).first;
      expect(tester.widget<AnimatedOpacity>(cubierta).opacity, 1);
      expect(find.descendant(of: find.byType(VideoMovil), matching: find.byType(PortadaCapitulo)), findsOneWidget);

      VideoFalso.creados.single.avanzarA(const Duration(milliseconds: 120));
      await tester.pump();
      expect(tester.widget<AnimatedOpacity>(cubierta).opacity, 0);

      // Una vez descubierto no vuelve a cubrirse, ni siquiera al volver al principio.
      VideoFalso.creados.single.avanzarA(Duration.zero);
      await tester.pump();
      expect(tester.widget<AnimatedOpacity>(cubierta).opacity, 0);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('el botón de play y pausa de la barra pausa y reanuda', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);
      await reproducir(tester);
      final video = VideoFalso.creados.single;
      expect(tester.widget<IconButton>(controles(botonPlayPausa)).tooltip, 'Pausar');

      await tester.tap(controles(botonPlayPausa));
      await tester.pump();
      expect(video.value.isPlaying, isFalse);
      expect(tester.widget<IconButton>(controles(botonPlayPausa)).tooltip, 'Reproducir');
      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(2));

      await tester.tap(controles(botonPlayPausa));
      await tester.pump();
      expect(video.value.isPlaying, isTrue);
      expect(find.byIcon(Icons.pause_rounded), findsNWidgets(2));

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('el botón central también pausa y reanuda', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);
      await reproducir(tester);
      final video = VideoFalso.creados.single;

      await tester.tap(controles(botonCentral));
      await tester.pump();
      expect(video.value.isPlaying, isFalse);

      await tester.tap(controles(botonCentral));
      await tester.pump();
      expect(video.value.isPlaying, isTrue);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('el botón de sonido silencia y devuelve el sonido', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);
      await reproducir(tester);
      final video = VideoFalso.creados.single;
      expect(tester.widget<IconButton>(controles(botonSonido)).tooltip, 'Silenciar');

      await tester.tap(controles(botonSonido));
      await tester.pump();
      expect(video.value.volume, 0);
      expect(tester.widget<IconButton>(controles(botonSonido)).tooltip, 'Activar sonido');
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

      await tester.tap(controles(botonSonido));
      await tester.pump();
      expect(video.value.volume, 1);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('la barra de progreso busca solo al soltar, no mientras se arrastra', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);
      final video = VideoFalso.creados.single;
      int busquedas() => video.llamadas.where((l) => l.startsWith('seekTo')).length;
      double valorDeLaBarra() => tester.widget<Slider>(find.byType(Slider)).value;
      expect(valorDeLaBarra(), 0);

      final gesto = await tester.startGesture(tester.getCenter(find.byType(Slider)));
      await gesto.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesto.moveBy(const Offset(30, 0));
      await tester.pump();

      // Durante el arrastre la barra se mueve, pero el video no busca.
      expect(valorDeLaBarra(), greaterThan(0));
      expect(busquedas(), 0);

      await gesto.up();
      await tester.pump();
      expect(busquedas(), 1);
      final destino = int.parse(video.llamadas.firstWhere((l) => l.startsWith('seekTo')).split(' ').last);
      expect(destino, inInclusiveRange(1, horizontal.duracion.inMilliseconds));

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('la barra de progreso es accesible: etiqueta "Progreso del video" y valor "m:ss de m:ss"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);
      VideoFalso.creados.single.avanzarA(const Duration(seconds: 12));
      await tester.pump();

      expect(
        tester.getSemantics(find.byType(Slider)),
        isSemantics(
          label: 'Progreso del video',
          value: '0:12 de 0:48',
          isSlider: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      controlador.dispose();
      await tester.pump();
      handle.dispose();
    });

    testWidgets('el tiempo se muestra completo solo si hay ancho', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);
      VideoFalso.creados.single.avanzarA(const Duration(seconds: 30));
      await tester.pump();
      expect(find.text('0:30 / 0:48'), findsOneWidget);

      await montar(tester, controlador: controlador, ancho: 360);
      expect(find.text('0:30'), findsOneWidget);
      expect(find.text('0:30 / 0:48'), findsNothing);

      // En un recuadro todavía más angosto, la barra de progreso tiene prioridad.
      await montar(tester, controlador: controlador, ancho: 240);
      expect(find.text('0:30'), findsNothing);
      expect(find.byType(Slider), findsOneWidget);
      expect(tester.takeException(), isNull);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('al terminar, el botón dice "Ver de nuevo" y repite el video', (tester) async {
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador);
      await reproducir(tester);
      final video = VideoFalso.creados.single;

      video.completar();
      await tester.pump();
      expect(tester.widget<IconButton>(controles(botonCentral)).tooltip, 'Ver de nuevo');
      expect(find.byIcon(Icons.replay_rounded), findsNWidgets(2));

      await tester.tap(controles(botonCentral));
      await tester.pump();

      expect(video.llamadas.where((l) => l.startsWith('seekTo')), ['seekTo 0']);
      expect(video.value.isPlaying, isTrue);
      expect(video.value.isCompleted, isFalse);

      controlador.dispose();
      await tester.pump();
    });

    group('ocultar los controles', () {
      testWidgets('se esconden solos a los 3 segundos mientras suena', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador);
        await reproducir(tester);
        expect(opacidadDeControles(tester), 1);

        await tester.pump(const Duration(milliseconds: 2900));
        expect(opacidadDeControles(tester), 1);

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 300));
        expect(opacidadDeControles(tester), 0);

        controlador.dispose();
        await tester.pump();
      });

      testWidgets('un toque en el video los muestra de nuevo y otro los oculta', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador);
        await reproducir(tester);
        await tester.pump(const Duration(seconds: 4));
        expect(opacidadDeControles(tester), 0);

        // Esquina superior izquierda: no hay ningún botón.
        final esquina = tester.getTopLeft(find.byType(VideoMovil)) + const Offset(20, 20);
        await tester.tapAt(esquina);
        await tester.pump(const Duration(milliseconds: 300));
        expect(opacidadDeControles(tester), 1);

        await tester.tapAt(esquina);
        await tester.pump(const Duration(milliseconds: 300));
        expect(opacidadDeControles(tester), 0);

        controlador.dispose();
        await tester.pump();
      });

      testWidgets('con los controles ocultos, sus botones no reciben toques', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador);
        await reproducir(tester);
        await tester.pump(const Duration(seconds: 4));
        final video = VideoFalso.creados.single;

        // El toque en el centro solo vuelve a mostrar los controles: no pausa.
        await tester.tapAt(tester.getCenter(find.byType(VideoMovil)));
        await tester.pump(const Duration(milliseconds: 300));

        expect(video.value.isPlaying, isTrue);
        expect(opacidadDeControles(tester), 1);

        controlador.dispose();
        await tester.pump();
      });

      testWidgets('cada interacción reinicia la cuenta de 3 segundos', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador, ancho: 640);
        await reproducir(tester);

        await tester.pump(const Duration(milliseconds: 2500));
        await tester.tap(controles(botonSonido));
        await tester.pump(const Duration(milliseconds: 2500));
        // Habrían pasado 5 segundos desde el inicio, pero solo 2,5 desde el toque.
        expect(opacidadDeControles(tester), 1);

        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 300));
        expect(opacidadDeControles(tester), 0);

        controlador.dispose();
        await tester.pump();
      });

      testWidgets('en pausa los controles no se esconden nunca', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador);
        await reproducir(tester);
        await tester.tap(controles(botonCentral));
        await tester.pump();

        await tester.pump(const Duration(seconds: 10));
        expect(opacidadDeControles(tester), 1);

        controlador.dispose();
        await tester.pump();
      });

      testWidgets('si se pausa con los controles ocultos, reaparecen', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador);
        await reproducir(tester);
        await tester.pump(const Duration(seconds: 4));
        expect(opacidadDeControles(tester), 0);

        await controlador.pausar();
        await tester.pump(const Duration(milliseconds: 300));

        expect(opacidadDeControles(tester), 1);

        controlador.dispose();
        await tester.pump();
      });

      testWidgets('con un lector de pantalla activo no se esconden nunca', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador, lectorDePantalla: true);
        await reproducir(tester);

        await tester.pump(const Duration(seconds: 10));
        expect(opacidadDeControles(tester), 1);

        // Tocar el video tampoco los esconde.
        await tester.tapAt(tester.getTopLeft(find.byType(VideoMovil)) + const Offset(20, 20));
        await tester.pump(const Duration(milliseconds: 300));
        expect(opacidadDeControles(tester), 1);

        controlador.dispose();
        await tester.pump();
      });

      testWidgets('al terminar el video los controles se quedan a la vista', (tester) async {
        final controlador = controladorDePrueba();
        await montar(tester, controlador: controlador);
        await reproducir(tester);
        await tester.pump(const Duration(seconds: 4));
        expect(opacidadDeControles(tester), 0);

        VideoFalso.creados.single.completar();
        await tester.pump(const Duration(milliseconds: 300));
        expect(opacidadDeControles(tester), 1);

        controlador.dispose();
        await tester.pump();
      });
    });

    testWidgets('todos los botones de los controles miden al menos 48 dp y tienen etiqueta', (tester) async {
      final handle = tester.ensureSemantics();
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);

      for (final clave in [botonCentral, botonPlayPausa, botonSonido, botonPantallaCompleta]) {
        final tamano = tester.getSize(controles(clave));
        expect(tamano.width, greaterThanOrEqualTo(48), reason: '$clave');
        expect(tamano.height, greaterThanOrEqualTo(48), reason: '$clave');
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      controlador.dispose();
      await tester.pump();
      handle.dispose();
    });
  });

  group('pantalla completa', () {
    late List<MethodCall> llamadasDelSistema;

    setUp(() {
      llamadasDelSistema = [];
    });

    Future<void> simularSistema(WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
        llamadasDelSistema.add(llamada);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    }

    /// Llamadas a `SystemChrome` en el orden en que ocurrieron, como texto
    /// ("método: argumentos"). Se omite la descripción de la app en el
    /// selector de tareas, que `MaterialApp` envía por su cuenta.
    List<String> sistema() => [
      for (final llamada in llamadasDelSistema)
        if (llamada.method.startsWith('SystemChrome.') &&
            llamada.method != 'SystemChrome.setApplicationSwitcherDescription')
          '${llamada.method}: ${llamada.arguments}',
    ];

    Future<void> abrirPantallaCompleta(WidgetTester tester) async {
      await tester.tap(controles(botonPantallaCompleta));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Al salir: barras visibles otra vez y orientación libre (lista vacía).
    const restauracion = [
      'SystemChrome.setEnabledSystemUIOverlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]',
      'SystemChrome.setPreferredOrientations: []',
    ];

    testWidgets('un video horizontal entra sin barras y en horizontal, con el mismo reproductor', (tester) async {
      await simularSistema(tester);
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);
      final video = VideoFalso.creados.single;

      await abrirPantallaCompleta(tester);

      expect(find.byType(PantallaCompletaVideo), findsOneWidget);
      expect(sistema(), [
        'SystemChrome.setEnabledSystemUIMode: SystemUiMode.immersiveSticky',
        'SystemChrome.setPreferredOrientations: [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]',
      ]);
      // No se crea otro reproductor: se dibuja el mismo.
      expect(VideoFalso.creados, hasLength(1));
      expect(tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller, same(video));
      expect(video.value.isPlaying, isTrue);
      // El botón cambia de función dentro de la pantalla completa.
      expect(tester.widget<IconButton>(controles(botonPantallaCompleta)).tooltip, 'Salir de pantalla completa');
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('un video vertical entra en vertical', (tester) async {
      await simularSistema(tester);
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, capitulo: vertical, ancho: 300);
      await reproducir(tester);

      await abrirPantallaCompleta(tester);

      expect(sistema().last, 'SystemChrome.setPreferredOrientations: [DeviceOrientation.portraitUp]');

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('al salir con la flecha, restaura las barras y la orientación', (tester) async {
      await simularSistema(tester);
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);
      await abrirPantallaCompleta(tester);

      await tester.tap(controles(botonSalir));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PantallaCompletaVideo), findsNothing);
      expect(sistema().skip(2), restauracion);
      // El video sigue donde estaba.
      expect(VideoFalso.creados.single.liberado, isFalse);
      expect(find.byType(VideoMovil), findsOneWidget);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('al salir con el botón de la barra, restaura las barras y la orientación', (tester) async {
      await simularSistema(tester);
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);
      await abrirPantallaCompleta(tester);

      await tester.tap(controles(botonPantallaCompleta));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PantallaCompletaVideo), findsNothing);
      expect(sistema().skip(2), restauracion);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('al salir con el botón atrás del sistema, restaura las barras y la orientación', (tester) async {
      await simularSistema(tester);
      final controlador = controladorDePrueba();
      await montar(tester, controlador: controlador, ancho: 640);
      await reproducir(tester);
      await abrirPantallaCompleta(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PantallaCompletaVideo), findsNothing);
      expect(sistema().skip(2), restauracion);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('restaura aunque la sección ya no exista cuando se cierra', (tester) async {
      await simularSistema(tester);
      final controlador = controladorDePrueba();
      final mostrar = ValueNotifier<bool>(true);
      addTearDown(mostrar.dispose);
      await montar(
        tester,
        controlador: controlador,
        ancho: 640,
        envolver: (recuadro) => ValueListenableBuilder<bool>(
          valueListenable: mostrar,
          builder: (context, visible, _) => visible ? recuadro : const SizedBox(),
        ),
      );
      await reproducir(tester);
      await abrirPantallaCompleta(tester);

      // La sección desaparece mientras el video está a pantalla completa.
      mostrar.value = false;
      await tester.pump();
      expect(find.byType(ReproductorCapitulo), findsNothing);

      await tester.tap(controles(botonSalir));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sistema().skip(2), restauracion);
      expect(tester.takeException(), isNull);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('con el movimiento reducido, la pantalla completa aparece sin transición', (tester) async {
      await simularSistema(tester);
      final controlador = controladorDePrueba();
      await montar(
        tester,
        controlador: controlador,
        ancho: 640,
        envolver: (recuadro) => MediaQuery(data: const MediaQueryData(disableAnimations: true), child: recuadro),
      );
      await reproducir(tester);

      await tester.tap(controles(botonPantallaCompleta));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PantallaCompletaVideo), findsOneWidget);

      controlador.dispose();
      await tester.pump();
    });
  });

  group('en Web', () {
    ControladorComoFunciona controladorWeb() => controladorDePrueba(navegador: true);

    Future<void> reproducirConTeclado(WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      foco.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('el video no lleva nada encima: ni controles propios ni detectores de gestos', (tester) async {
      final controlador = controladorWeb();
      await montar(tester, controlador: controlador);

      await reproducir(tester);

      expect(find.byType(EscenarioWeb), findsOneWidget);
      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(find.byType(ControlesVideoMovil), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.descendant(of: find.byType(EscenarioWeb), matching: find.byType(GestureDetector)), findsNothing);
      expect(find.descendant(of: find.byType(EscenarioWeb), matching: find.byType(IgnorePointer)), findsNothing);
      // El video es lo último que se dibuja de su pila.
      final pila = tester.widget<Stack>(
        find.ancestor(of: find.byType(VideoPlayer), matching: find.byType(Stack)).first,
      );
      expect(pila.children, hasLength(1));

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('el escenario anuncia los atajos de teclado a los lectores de pantalla', (tester) async {
      final handle = tester.ensureSemantics();
      final controlador = controladorWeb();
      await montar(tester, controlador: controlador);
      await reproducir(tester);

      expect(
        find.bySemanticsLabel(
          'Video: ¿Cómo funciona la selección?. Usa la barra de reproducción del video o el teclado: '
          'Espacio para pausar o reproducir, flechas para avanzar o retroceder, M para silenciar.',
        ),
        findsOneWidget,
      );

      controlador.dispose();
      await tester.pump();
      handle.dispose();
    });

    testWidgets('al activar la portada con el teclado, el foco pasa al video y los atajos funcionan', (tester) async {
      final controlador = controladorWeb();
      await montar(tester, controlador: controlador);

      await reproducirConTeclado(tester);

      final video = VideoFalso.creados.single;
      expect(foco.hasFocus, isFalse);
      expect(video.value.isPlaying, isTrue);
      int veces(String llamada) => video.veces(llamada);
      final pausasIniciales = veces('pause');

      // Espacio: pausa; otra vez, reanuda. Una llamada por pulsación.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(video.value.isPlaying, isFalse);
      expect(veces('pause'), pausasIniciales + 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(video.value.isPlaying, isTrue);

      // K hace lo mismo que Espacio.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      expect(video.value.isPlaying, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      expect(video.value.isPlaying, isTrue);

      // Las flechas saltan 5 segundos.
      video.avanzarA(const Duration(seconds: 20));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(video.value.position, const Duration(seconds: 25));
      expect(video.llamadas.where((l) => l.startsWith('seekTo')), ['seekTo 25000']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(video.value.position, const Duration(seconds: 20));

      // M silencia y devuelve el sonido.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(video.value.volume, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(video.value.volume, 1);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('otras teclas, o las mismas con Ctrl, no se tocan', (tester) async {
      final controlador = controladorWeb();
      await montar(tester, controlador: controlador);
      await reproducirConTeclado(tester);
      final video = VideoFalso.creados.single;
      final llamadas = List<String>.of(video.llamadas);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(video.llamadas, llamadas);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('el aro de foco solo existe con el escenario enfocado', (tester) async {
      final controlador = controladorWeb();
      await montar(tester, controlador: controlador);
      await reproducirConTeclado(tester);

      Finder aro() => find.descendant(of: find.byType(EscenarioWeb), matching: find.byType(IgnorePointer));
      expect(aro(), findsOneWidget);

      // Un toque fuera del video suelta el foco: el aro desaparece y Espacio deja de actuar.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(aro(), findsNothing);
      final pausas = VideoFalso.creados.single.veces('pause');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(VideoFalso.creados.single.veces('pause'), pausas);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('con el ratón no se mueve el foco ni se dibuja el aro', (tester) async {
      final controlador = controladorWeb();
      await montar(tester, controlador: controlador);

      await reproducir(tester);

      expect(find.descendant(of: find.byType(EscenarioWeb), matching: find.byType(IgnorePointer)), findsNothing);

      controlador.dispose();
      await tester.pump();
    });

    testWidgets('si el navegador rechaza la reproducción, el video sigue a la vista con sus controles', (tester) async {
      final controlador = controladorWeb();
      await montar(tester, controlador: controlador);
      await reproducir(tester);

      VideoFalso.creados.single.fallar();
      await tester.pump();

      expect(find.byType(EscenarioWeb), findsOneWidget);
      expect(find.byType(EstadoErrorVideo), findsNothing);
      expect(tester.takeException(), isNull);

      controlador.dispose();
      await tester.pump();
    });
  });
}
