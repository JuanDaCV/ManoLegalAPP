import 'package:desarrollo/vista/compartido/widgets/bloque_video_introductorio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

// =============================================================================
// El reproductor real necesita la plataforma de video, que no existe en
// `flutter test`. Estas pruebas inyectan un controlador falso que registra las
// llamadas, para comprobar el comportamiento pedido: arranca solo, en silencio
// y en loop; el toque alterna el sonido y nunca pausa; se pausa cuando no está
// a la vista. Se declara con `implements` + `noSuchMethod`, como los demás
// dobles de prueba del proyecto.
// =============================================================================

class _ControladorVideoFalso extends ValueNotifier<VideoPlayerValue> implements VideoPlayerController {
  _ControladorVideoFalso({this.fallaAlIniciar = false}) : super(const VideoPlayerValue.uninitialized());

  final bool fallaAlIniciar;
  final llamadas = <String>[];
  bool liberado = false;

  // Sin id de reproductor, VideoPlayer dibuja un contenedor vacío en vez de
  // pedirle una vista a la plataforma.
  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  Future<void> initialize() async {
    llamadas.add('initialize');
    if (fallaAlIniciar) throw PlatformException(code: 'sin_video');
    value = const VideoPlayerValue(duration: Duration(seconds: 10), size: Size(848, 480), isInitialized: true);
  }

  @override
  Future<void> setVolume(double volume) async {
    llamadas.add('volumen $volume');
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> setLooping(bool looping) async {
    llamadas.add('loop $looping');
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> play() async {
    llamadas.add('play');
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    llamadas.add('pause');
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> dispose() async {
    liberado = true;
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _enPantalla(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

void main() {
  testWidgets('arranca solo, en silencio y en loop, sin que nadie toque', (tester) async {
    final controlador = _ControladorVideoFalso();
    await tester.pumpWidget(_enPantalla(BloqueVideoIntroductorio(crearControlador: () => controlador)));
    await tester.pump();

    expect(controlador.value.isPlaying, isTrue);
    expect(controlador.value.volume, 0);
    expect(controlador.value.isLooping, isTrue);
    // El silencio va antes del play: es lo que permite el autoplay en Web.
    expect(controlador.llamadas.indexOf('volumen 0.0'), lessThan(controlador.llamadas.indexOf('play')));
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
  });

  testWidgets('el toque alterna el sonido y nunca pausa', (tester) async {
    final controlador = _ControladorVideoFalso();
    await tester.pumpWidget(_enPantalla(BloqueVideoIntroductorio(crearControlador: () => controlador)));
    await tester.pump();

    await tester.tap(find.byType(BloqueVideoIntroductorio));
    await tester.pump();
    expect(controlador.value.volume, 1);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.tap(find.byType(BloqueVideoIntroductorio));
    await tester.pump();
    expect(controlador.value.volume, 0);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    expect(controlador.llamadas, isNot(contains('pause')));
    expect(controlador.value.isPlaying, isTrue);
  });

  testWidgets('la capa táctil está encima del video, no lo envuelve', (tester) async {
    // En Web el video es un elemento HTML que se queda con los clics que lo
    // alcanzan primero: el toque solo llega a Flutter si un widget lo tapa.
    await tester.pumpWidget(_enPantalla(BloqueVideoIntroductorio(crearControlador: _ControladorVideoFalso.new)));
    await tester.pump();

    final detectorDelBloque = find.descendant(
      of: find.byType(BloqueVideoIntroductorio),
      matching: find.byType(GestureDetector),
    );
    expect(find.ancestor(of: find.byType(VideoPlayer), matching: detectorDelBloque), findsNothing);

    final pila = tester.widget<Stack>(
      find.ancestor(of: find.byType(VideoPlayer), matching: find.byType(Stack)).first,
    );
    expect(find.descendant(of: find.byWidget(pila.children.last), matching: detectorDelBloque), findsOneWidget);
  });

  testWidgets('no muestra controles de reproductor', (tester) async {
    await tester.pumpWidget(_enPantalla(BloqueVideoIntroductorio(crearControlador: _ControladorVideoFalso.new)));
    await tester.pump();

    for (final icono in [Icons.play_arrow, Icons.play_arrow_rounded, Icons.pause, Icons.pause_rounded, Icons.fullscreen]) {
      expect(find.byIcon(icono), findsNothing);
    }
    expect(find.byType(VideoProgressIndicator), findsNothing);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('se pausa al ocultarse la sección y retoma al volver', (tester) async {
    final controlador = _ControladorVideoFalso();
    final indice = ValueNotifier<int>(0);
    addTearDown(indice.dispose);
    await tester.pumpWidget(
      _enPantalla(
        ValueListenableBuilder<int>(
          valueListenable: indice,
          builder: (_, valor, _) => IndexedStack(
            index: valor,
            children: [BloqueVideoIntroductorio(crearControlador: () => controlador), const SizedBox()],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(controlador.value.isPlaying, isTrue);

    indice.value = 1;
    await tester.pump();
    expect(controlador.value.isPlaying, isFalse);

    indice.value = 0;
    await tester.pump();
    expect(controlador.value.isPlaying, isTrue);
  });

  testWidgets('se pausa cuando otra pantalla lo tapa y retoma al volver', (tester) async {
    final controlador = _ControladorVideoFalso();
    final navegador = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navegador,
        home: Scaffold(body: BloqueVideoIntroductorio(crearControlador: () => controlador)),
      ),
    );
    await tester.pump();
    expect(controlador.value.isPlaying, isTrue);

    navegador.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pumpAndSettle();
    expect(controlador.value.isPlaying, isFalse);

    navegador.currentState!.pop();
    await tester.pumpAndSettle();
    expect(controlador.value.isPlaying, isTrue);
  });

  testWidgets('libera el reproductor al salir de la pantalla', (tester) async {
    final controlador = _ControladorVideoFalso();
    await tester.pumpWidget(_enPantalla(BloqueVideoIntroductorio(crearControlador: () => controlador)));
    await tester.pump();

    await tester.pumpWidget(_enPantalla(const SizedBox()));
    expect(controlador.liberado, isTrue);
  });

  testWidgets('si el video falla, un toque lo vuelve a intentar', (tester) async {
    final controladores = [_ControladorVideoFalso(fallaAlIniciar: true), _ControladorVideoFalso()];
    var creados = 0;
    await tester.pumpWidget(
      _enPantalla(BloqueVideoIntroductorio(crearControlador: () => controladores[creados++])),
    );
    await tester.pump();
    expect(find.text('No se pudo reproducir el video. Toca para reintentar.'), findsOneWidget);

    await tester.tap(find.byType(BloqueVideoIntroductorio));
    await tester.pump();

    expect(creados, 2);
    expect(controladores.first.liberado, isTrue);
    expect(controladores.last.value.isPlaying, isTrue);
    expect(controladores.last.value.volume, 0);
  });

  for (final ancho in [360.0, 600.0, 900.0, 1280.0]) {
    testWidgets('no desborda a $ancho px', (tester) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _enPantalla(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BloqueVideoIntroductorio(crearControlador: _ControladorVideoFalso.new),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // El bloque ocupa todo el ancho disponible con proporción 16:9.
      final tamano = tester.getSize(find.byType(BloqueVideoIntroductorio));
      expect(tamano.width, ancho - 32);
      expect(tamano.height, closeTo((ancho - 32) * 9 / 16, 0.01));
    });
  }

  testWidgets('el archivo del video está declarado como asset', (tester) async {
    // Lectura real del archivo: fuera del reloj simulado de testWidgets.
    final datos = await tester.runAsync(() => rootBundle.load(rutaVideoIntroductorio));
    expect(datos!.lengthInBytes, greaterThan(0));
  });
}
