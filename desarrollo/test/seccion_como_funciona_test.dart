import 'dart:math' as math;

import 'package:desarrollo/controlador/controlador_como_funciona.dart';
import 'package:desarrollo/modelo/modelo_capitulo_como_funciona.dart';
import 'package:desarrollo/vista/cliente/seccion_como_funciona.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/capitulo_como_funciona.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/contorno_de_foco.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/encabezado_como_funciona.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/estados_reproductor.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/estilos_como_funciona.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/fila_riel.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/indice_capitulos.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/piezas_capitulo.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/video_movil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_como_funciona.dart';

void main() {
  setUp(() {
    // Sin red en las pruebas: el texto usa la tipografía del tema.
    EstilosComoFunciona.usarTipografiaDeMarca = false;
    VideoFalso.reiniciarRegistro();
  });

  const telefono = Size(390, 844);
  const escritorio = Size(1440, 900);

  Future<void> montar(
    WidgetTester tester, {
    required Size tamano,
    ControladorComoFunciona? controlador,
    double escalaTexto = 1,
    bool sinAnimaciones = false,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(escalaTexto), disableAnimations: sinAnimaciones),
          child: hijo!,
        ),
        home: Scaffold(body: SeccionComoFunciona(crearControlador: () => controlador ?? controladorDePrueba())),
      ),
    );
    // Deja terminar la aparición suave del encabezado.
    await tester.pump(const Duration(milliseconds: 500));
  }

  ScrollController desplazamiento(WidgetTester tester) =>
      tester.widget<CustomScrollView>(find.byType(CustomScrollView)).controller!;

  Future<void> recorrerHastaElFinal(WidgetTester tester) async {
    final controlador = desplazamiento(tester);
    final paso = controlador.position.viewportDimension * 0.7;
    var vueltas = 0;
    while (controlador.position.pixels < controlador.position.maxScrollExtent - 0.5 && vueltas++ < 200) {
      controlador.jumpTo(math.min(controlador.position.pixels + paso, controlador.position.maxScrollExtent));
      await tester.pump();
    }
  }

  Finder marco(int numero) => find.byKey(ValueKey('marco_video_$numero'));

  Finder portadaDe(int numero) => find.descendant(of: marco(numero), matching: find.byType(PortadaInteractiva));

  /// Lleva la portada a la vista y la toca; deja que el video cargue y arranque.
  Future<void> tocarPortada(WidgetTester tester, int numero) async {
    await tester.ensureVisible(portadaDe(numero));
    await tester.pump();
    await tester.tap(portadaDe(numero));
    await tester.pump();
    await tester.pump();
  }

  /// Distancia entre el borde superior de la pantalla y el del capítulo.
  double bordeSuperiorDelCapitulo(WidgetTester tester, int numero) =>
      tester.getTopLeft(find.byType(CapituloComoFunciona).at(numero - 1)).dy;

  /// Posición de desplazamiento a la que el capítulo queda en el borde superior.
  double desplazamientoDelCapitulo(WidgetTester tester, int numero) =>
      desplazamiento(tester).position.pixels + bordeSuperiorDelCapitulo(tester, numero);

  Finder enElRiel(Finder buscado) => find.descendant(of: find.byType(RielCapitulos), matching: buscado);

  const tamanos = [
    Size(320, 640),
    Size(360, 800),
    Size(412, 915),
    Size(600, 960),
    Size(768, 1024),
    Size(900, 700),
    Size(1024, 768),
    Size(1100, 640),
    Size(1280, 720),
    Size(1280, 480),
    Size(1280, 160),
    Size(1440, 900),
    Size(1920, 1080),
    Size(2560, 1080),
    Size(2560, 1440),
  ];

  group('diseño', () {
    for (final tamano in tamanos) {
      testWidgets('no desborda a ${tamano.width.toInt()}×${tamano.height.toInt()} y llega al final', (tester) async {
        await montar(tester, tamano: tamano);
        expect(tester.takeException(), isNull);

        await recorrerHastaElFinal(tester);
        expect(tester.takeException(), isNull);
        // Llegó de verdad al final de la página.
        expect(desplazamiento(tester).position.extentAfter, lessThan(1));
      });
    }

    for (final tamano in const [Size(320, 640), Size(412, 915), Size(1280, 720)]) {
      testWidgets('no desborda a ${tamano.width.toInt()}×${tamano.height.toInt()} con el texto al doble', (
        tester,
      ) async {
        await montar(tester, tamano: tamano, escalaTexto: 2);
        expect(tester.takeException(), isNull);

        await recorrerHastaElFinal(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('al cambiar el tamaño de la ventana el diseño se adapta sin errores', (tester) async {
      await montar(tester, tamano: escritorio);
      expect(find.byType(RielCapitulos), findsOneWidget);

      for (final tamano in const [Size(1000, 800), telefono, Size(700, 900), escritorio]) {
        tester.view.physicalSize = tamano;
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$tamano');
      }
      expect(find.byType(RielCapitulos), findsOneWidget);
    });

    testWidgets('los seis títulos aparecen, exactos y en orden, de arriba abajo', (tester) async {
      for (final tamano in [telefono, escritorio]) {
        await montar(tester, tamano: tamano);

        final posiciones = <double>[];
        for (final capitulo in capitulosComoFunciona) {
          // En pantalla ancha el título también está en el riel: el del capítulo es el último.
          final titulo = find.text(capitulo.titulo);
          expect(titulo, findsWidgets, reason: capitulo.titulo);
          posiciones.add(tester.getTopLeft(titulo.last).dy);
        }
        expect(posiciones, orderedEquals([...posiciones]..sort()), reason: '$tamano');
        expect(posiciones.toSet(), hasLength(6));
      }
    });

    testWidgets('el encabezado trae el título, la frase de presentación y la duración total', (tester) async {
      await montar(tester, tamano: telefono);

      expect(find.text('GUÍA EN VIDEO'), findsOneWidget);
      expect(find.text('Cómo funciona ManoLegal'), findsOneWidget);
      expect(
        find.text(
          'Seis videos breves para conocer la plataforma: qué es, cómo encontrar y elegir un abogado, '
          'qué significa la verificación, cómo contactarlo y qué tener en cuenta como cliente.',
        ),
        findsOneWidget,
      );
      expect(find.text('6 videos · unos 5 minutos'), findsOneWidget);
    });

    testWidgets('el encabezado aparece con un fundido, y de golpe si el movimiento está reducido', (tester) async {
      double opacidad() => tester
          .widget<Opacity>(
            find.ancestor(of: find.text('Cómo funciona ManoLegal'), matching: find.byType(Opacity)).first,
          )
          .opacity;

      tester.view.physicalSize = telefono;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SeccionComoFunciona(crearControlador: controladorDePrueba)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacidad(), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(opacidad(), 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, hijo) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: hijo!),
          home: Scaffold(body: SeccionComoFunciona(crearControlador: controladorDePrueba)),
        ),
      );
      await tester.pump();
      expect(opacidad(), 1);
    });

    testWidgets('los tres temas de cada capítulo se ocultan en teléfono y se muestran en tableta y escritorio', (
      tester,
    ) async {
      void comprobarTemas(Matcher cantidad, {required String reason}) {
        for (final capitulo in capitulosComoFunciona) {
          for (final tema in capitulo.temas) {
            expect(find.text(tema), cantidad, reason: '$reason: $tema');
          }
        }
      }

      // Teléfono (menos de 600 px): ahí mandan el título, la descripción y el video.
      for (final tamano in const [Size(320, 640), telefono, Size(599, 900)]) {
        await montar(tester, tamano: tamano);
        expect(find.byType(PildorasTemas), findsNothing, reason: '$tamano');
        expect(find.byType(TemasConPunto), findsNothing, reason: '$tamano');
        comprobarTemas(findsNothing, reason: '$tamano');
        expect(tester.takeException(), isNull);
      }

      // Tableta: píldoras en las seis tarjetas, también en el borde de 600 px.
      for (final tamano in const [Size(600, 960), Size(768, 1024), Size(1099, 800)]) {
        await montar(tester, tamano: tamano);
        expect(find.byType(PildorasTemas), findsNWidgets(6), reason: '$tamano');
        comprobarTemas(findsOneWidget, reason: '$tamano');
      }

      // Escritorio: los temas van con un punto dorado en cada escena.
      await montar(tester, tamano: escritorio);
      expect(find.byType(TemasConPunto), findsNWidgets(6));
      expect(find.byType(PildorasTemas), findsNothing);
      comprobarTemas(findsOneWidget, reason: 'escritorio');
    });

    testWidgets('en tableta el largo de línea de la presentación y de las descripciones se limita a 620 px', (
      tester,
    ) async {
      for (final tamano in const [Size(768, 1024), Size(1024, 768), Size(1099, 800)]) {
        await montar(tester, tamano: tamano);

        // El tope es el que da forma al texto: ocupa casi todo el ancho permitido.
        final lead = tester.getSize(find.textContaining('Seis videos breves'));
        expect(lead.width, inInclusiveRange(400, 620), reason: '$tamano');

        for (final capitulo in capitulosComoFunciona) {
          final descripcion = find.text(capitulo.descripcion);
          final ancho = tester.getSize(descripcion).width;
          expect(ancho, lessThanOrEqualTo(620), reason: '$tamano capítulo ${capitulo.numero}');
          // El capítulo vertical comparte la tarjeta con su video y tiene menos ancho.
          if (!capitulo.esVertical) expect(ancho, greaterThan(400), reason: '$tamano capítulo ${capitulo.numero}');
          // Alineada a la izquierda, bajo el título.
          expect(
            tester.getTopLeft(descripcion).dx,
            closeTo(tester.getTopLeft(find.text(capitulo.titulo)).dx, 0.5),
            reason: '$tamano capítulo ${capitulo.numero}',
          );
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('en teléfono el texto no tiene tope de ancho: llena la tarjeta', (tester) async {
      await montar(tester, tamano: telefono);

      final tarjeta = tester.getRect(find.byType(CapituloComoFunciona).at(0));
      final descripcion = tester.getRect(find.text(capitulosComoFunciona[0].descripcion));
      // 1 px de borde y 20 px de relleno a cada lado.
      expect(descripcion.left, closeTo(tarjeta.left + 21, 0.5));
      expect(descripcion.width, greaterThan(tarjeta.width - 42 - 100));
    });
  });

  group('proporciones de los videos', () {
    for (final tamano in [
      telefono,
      const Size(768, 1024),
      escritorio,
      const Size(1920, 1080),
      const Size(2560, 1080),
    ]) {
      testWidgets(
        'cada recuadro conserva la proporción de su video a ${tamano.width.toInt()}×${tamano.height.toInt()}',
        (tester) async {
          await montar(tester, tamano: tamano);

          for (final capitulo in capitulosComoFunciona) {
            final tamanoMarco = tester.getSize(marco(capitulo.numero));
            final esperada = capitulo.esVertical ? 9 / 16 : 16 / 9;
            // Los capítulos 1, 3, 4, 5 y 6 son 16:9; el 2, vertical (9:16).
            expect(
              tamanoMarco.width / tamanoMarco.height,
              closeTo(esperada, 0.01),
              reason: 'capítulo ${capitulo.numero}',
            );
            // Con 1 px de tolerancia en la dimensión menor, como pide el diseño.
            expect(tamanoMarco.width, closeTo(tamanoMarco.height * esperada, 1));
          }
        },
      );
    }

    for (final tamano in const [Size(1920, 1080), Size(2560, 1080)]) {
      testWidgets('en ${tamano.width.toInt()} px de ancho el video horizontal no pasa de 976 px', (tester) async {
        await montar(tester, tamano: tamano);

        for (final numero in [1, 3, 4, 5, 6]) {
          expect(tester.getSize(marco(numero)).width, lessThanOrEqualTo(976), reason: 'capítulo $numero');
        }
        expect(tester.getSize(marco(1)).width, 976);
        // El vertical tiene su propio tamaño: el alto cabe en la pantalla con su marco.
        expect(tester.getSize(marco(2)).height, lessThanOrEqualTo(720));
      });
    }

    testWidgets('en teléfono el video llena el ancho de la tarjeta y el vertical queda centrado', (tester) async {
      await montar(tester, tamano: telefono);

      final tarjeta = tester.getRect(find.byType(CapituloComoFunciona).at(0));
      final video = tester.getRect(marco(1));
      // El video llega hasta los bordes de la tarjeta, menos 1 px de borde a cada lado.
      expect(video.left, closeTo(tarjeta.left + 1, 0.01));
      expect(video.right, closeTo(tarjeta.right - 1, 0.01));

      final vertical = tester.getRect(marco(2));
      final tarjetaVertical = tester.getRect(find.byType(CapituloComoFunciona).at(1));
      expect(vertical.center.dx, closeTo(tarjetaVertical.center.dx, 0.5));
      expect(vertical.width, lessThan(tarjetaVertical.width));
    });

    testWidgets('en una tableta ancha el capítulo vertical va al lado del texto', (tester) async {
      await montar(tester, tamano: const Size(768, 1024));

      final tarjeta = tester.getRect(find.byType(CapituloComoFunciona).at(1));
      final video = tester.getRect(marco(2));
      final titulo = tester.getRect(find.text(capitulosComoFunciona[1].titulo).last);
      expect(video.left, greaterThan(titulo.right - 1));
      expect(video.top, greaterThanOrEqualTo(tarjeta.top));
      expect(video.bottom, lessThanOrEqualTo(tarjeta.bottom));
    });
  });

  group('carga perezosa', () {
    testWidgets('no se crea ningún reproductor al montar ni al recorrer la página', (tester) async {
      for (final tamano in [telefono, escritorio]) {
        await montar(tester, tamano: tamano);
        await recorrerHastaElFinal(tester);

        expect(VideoFalso.creados, isEmpty, reason: '$tamano');
        expect(find.byType(PortadaInteractiva), findsNWidgets(6));
      }
    });

    testWidgets('al tocar una portada se crea un solo reproductor, para ese capítulo', (tester) async {
      await montar(tester, tamano: telefono);

      await tocarPortada(tester, 3);

      expect(VideoFalso.creados, hasLength(1));
      expect(find.descendant(of: marco(3), matching: find.byType(VideoMovil)), findsOneWidget);
      expect(find.byType(PortadaInteractiva), findsNWidgets(5));
    });

    for (final tamano in [telefono, escritorio]) {
      testWidgets(
        'al tocar otro capítulo, el anterior vuelve a su portada y queda un solo reproductor a ${tamano.width.toInt()} px',
        (tester) async {
          await montar(tester, tamano: tamano);

          await tocarPortada(tester, 3);
          final primero = VideoFalso.creados.single;
          await tocarPortada(tester, 4);
          await tester.pump();

          expect(VideoFalso.creados, hasLength(2));
          expect(VideoFalso.vivos, [VideoFalso.creados.last]);
          expect(primero.liberado, isTrue);
          expect(VideoFalso.vivos.where((v) => v.value.isPlaying), hasLength(1));
          expect(find.byType(PortadaInteractiva), findsNWidgets(5));
          expect(portadaDe(3), findsOneWidget);
          expect(portadaDe(4), findsNothing);
          expect(find.descendant(of: marco(4), matching: find.byType(VideoMovil)), findsOneWidget);
        },
      );
    }

    testWidgets('el capítulo vertical se reproduce con su proporción', (tester) async {
      await montar(tester, tamano: escritorio);

      await tocarPortada(tester, 2);

      expect(VideoFalso.creados.single.tamano, const Size(1080, 1920));
      expect(find.descendant(of: marco(2), matching: find.byType(VideoMovil)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('navegación entre capítulos', () {
    testWidgets('en pantalla ancha, el riel lleva al capítulo elegido y se queda fijo', (tester) async {
      await montar(tester, tamano: escritorio);
      final item = enElRiel(find.text(capitulosComoFunciona[4].titulo));
      await tester.ensureVisible(item);
      await tester.pump();

      await tester.tap(item);
      await tester.pumpAndSettle();

      // El capítulo 5 queda arriba de la pantalla.
      expect(bordeSuperiorDelCapitulo(tester, 5), closeTo(0, 2));
      expect(find.text('Capítulo 5 de 6'), findsOneWidget);

      // El riel sigue en su sitio mientras se recorre el medio de la página.
      final alturas = <double>[];
      for (final posicion in [1600.0, 2400.0, 3200.0, 4000.0]) {
        desplazamiento(tester).jumpTo(posicion);
        await tester.pump();
        alturas.add(tester.getTopLeft(find.byType(RielCapitulos)).dy);
      }
      expect(alturas, everyElement(closeTo(24, 0.5)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('el riel marca el capítulo que se está leyendo al desplazarse', (tester) async {
      await montar(tester, tamano: escritorio);
      expect(find.text('Capítulo 1 de 6'), findsOneWidget);

      for (final numero in [2, 3, 4, 5]) {
        desplazamiento(tester).jumpTo(desplazamientoDelCapitulo(tester, numero));
        await tester.pump();
        expect(find.text('Capítulo $numero de 6'), findsOneWidget, reason: 'capítulo $numero');
      }

      // Al llegar al final de la página, el último capítulo gana aunque no alcance la línea.
      desplazamiento(tester).jumpTo(desplazamiento(tester).position.maxScrollExtent);
      await tester.pump();
      expect(find.text('Capítulo 6 de 6'), findsOneWidget);

      desplazamiento(tester).jumpTo(0);
      await tester.pump();
      expect(find.text('Capítulo 1 de 6'), findsOneWidget);
    });

    testWidgets('el riel anuncia el capítulo activo como seleccionado', (tester) async {
      final handle = tester.ensureSemantics();
      await montar(tester, tamano: escritorio);

      Matcher item(int numero, {required bool seleccionado}) => isSemantics(
        label: 'Capítulo $numero: ${capitulosComoFunciona[numero - 1].titulo}',
        isButton: true,
        isSelected: seleccionado,
        hasTapAction: true,
      );
      Finder filaDelRiel(int numero) =>
          find.bySemanticsLabel('Capítulo $numero: ${capitulosComoFunciona[numero - 1].titulo}');

      expect(tester.getSemantics(filaDelRiel(1)), item(1, seleccionado: true));
      expect(tester.getSemantics(filaDelRiel(2)), item(2, seleccionado: false));

      desplazamiento(tester).jumpTo(desplazamientoDelCapitulo(tester, 3));
      await tester.pump();
      expect(tester.getSemantics(filaDelRiel(3)), item(3, seleccionado: true));
      expect(tester.getSemantics(filaDelRiel(1)), item(1, seleccionado: false));

      handle.dispose();
    });

    testWidgets('el botón "Empezar por el capítulo 1" y la lista "QUÉ VAS A APRENDER" llevan a sus capítulos', (
      tester,
    ) async {
      await montar(tester, tamano: escritorio);
      expect(find.text('QUÉ VAS A APRENDER'), findsOneWidget);
      expect(find.text('Empezar por el capítulo 1'), findsOneWidget);

      // Cada fila de la lista lleva al capítulo correspondiente.
      await tester.tap(find.text('Qué indica la insignia «Verificado»'));
      await tester.pumpAndSettle();
      expect(bordeSuperiorDelCapitulo(tester, 4), closeTo(0, 2));

      desplazamiento(tester).jumpTo(0);
      await tester.pump();
      await tester.tap(find.text('Empezar por el capítulo 1'));
      await tester.pumpAndSettle();
      expect(bordeSuperiorDelCapitulo(tester, 1), closeTo(0, 2));
    });

    testWidgets('en teléfono, los botones numerados llevan al capítulo elegido', (tester) async {
      await montar(tester, tamano: telefono);
      expect(find.byType(ChipsCapitulos), findsOneWidget);
      expect(find.byType(RielCapitulos), findsNothing);

      final capitulo4 = capitulosComoFunciona[3];
      await tester.tap(find.byTooltip('Ir al capítulo 4: ${capitulo4.titulo}'));
      await tester.pumpAndSettle();

      // Queda un poco de aire sobre la tarjeta, no pegada al borde.
      expect(bordeSuperiorDelCapitulo(tester, 4), closeTo(10, 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('con el movimiento reducido, el salto es inmediato', (tester) async {
      await montar(tester, tamano: telefono, sinAnimaciones: true);

      await tester.tap(find.byTooltip('Ir al capítulo 4: ${capitulosComoFunciona[3].titulo}'));
      await tester.pump();

      expect(bordeSuperiorDelCapitulo(tester, 4), closeTo(10, 2));
    });

    testWidgets('al saltar a otro capítulo, el video en reproducción se pausa', (tester) async {
      await montar(tester, tamano: telefono);
      await tocarPortada(tester, 2);
      final video = VideoFalso.creados.single;
      expect(video.value.isPlaying, isTrue);

      await tester.ensureVisible(find.byTooltip('Ir al capítulo 5: ${capitulosComoFunciona[4].titulo}'));
      await tester.pump();
      await tester.tap(find.byTooltip('Ir al capítulo 5: ${capitulosComoFunciona[4].titulo}'));
      await tester.pumpAndSettle();

      expect(video.value.isPlaying, isFalse);
      expect(video.liberado, isFalse);
    });

    testWidgets('al saltar al capítulo que ya se reproduce, el video no se pausa', (tester) async {
      await montar(tester, tamano: telefono);
      await tocarPortada(tester, 2);
      final video = VideoFalso.creados.single;

      await tester.ensureVisible(find.byTooltip('Ir al capítulo 2: ${capitulosComoFunciona[1].titulo}'));
      await tester.pump();
      await tester.tap(find.byTooltip('Ir al capítulo 2: ${capitulosComoFunciona[1].titulo}'));
      await tester.pumpAndSettle();

      expect(video.value.isPlaying, isTrue);
    });

    testWidgets('al llegar a un capítulo, el teclado queda en su botón de reproducir', (tester) async {
      await montar(tester, tamano: telefono);

      await tester.tap(find.byTooltip('Ir al capítulo 4: ${capitulosComoFunciona[3].titulo}'));
      await tester.pumpAndSettle();

      final foco = FocusManager.instance.primaryFocus;
      expect(foco?.debugLabel, 'Reproducir capítulo 4');
    });

    testWidgets('si el capítulo ya tiene video, el foco no se queda esperando a la portada', (tester) async {
      await montar(tester, tamano: telefono);
      await tocarPortada(tester, 4);

      // El botón de reproducir del capítulo 4 no está montado: pedirle el foco
      // lo dejaría pendiente y lo robaría cuando la portada volviera.
      await tester.ensureVisible(find.byTooltip('Ir al capítulo 4: ${capitulosComoFunciona[3].titulo}'));
      await tester.pump();
      await tester.tap(find.byTooltip('Ir al capítulo 4: ${capitulosComoFunciona[3].titulo}'));
      await tester.pumpAndSettle();
      await tocarPortada(tester, 5);
      await tester.pump();

      expect(portadaDe(4), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('Reproducir capítulo 4'));
    });
  });

  group('estado de la sección', () {
    testWidgets('al ocultarse la pestaña pausa el video y no lo reanuda al volver', (tester) async {
      tester.view.physicalSize = telefono;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controlador = controladorDePrueba();
      final indice = ValueNotifier<int>(0);
      addTearDown(indice.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: indice,
              builder: (_, valor, _) => IndexedStack(
                index: valor,
                children: [
                  SeccionComoFunciona(crearControlador: () => controlador),
                  const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tocarPortada(tester, 3);
      final video = VideoFalso.creados.single;
      expect(video.value.isPlaying, isTrue);

      indice.value = 1;
      await tester.pump();
      expect(video.value.isPlaying, isFalse);
      expect(video.liberado, isFalse);

      indice.value = 0;
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      // Quien decide si sigue es el usuario.
      expect(video.value.isPlaying, isFalse);
      expect(video.liberado, isFalse);
      expect(controlador.estadoDe(capitulosComoFunciona[2]), EstadoReproduccion.listo);
    });

    testWidgets('mientras la pestaña no se ha mostrado, no se construye nada pesado', (tester) async {
      tester.view.physicalSize = telefono;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final indice = ValueNotifier<int>(1);
      addTearDown(indice.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: indice,
              builder: (_, valor, _) => IndexedStack(
                index: valor,
                children: [
                  SeccionComoFunciona(crearControlador: controladorDePrueba),
                  const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CustomScrollView, skipOffstage: false), findsNothing);
      expect(find.byType(CapituloComoFunciona, skipOffstage: false), findsNothing);
      expect(find.byType(Image, skipOffstage: false), findsNothing);

      indice.value = 0;
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CapituloComoFunciona), findsNWidgets(6));
      expect(find.byType(PortadaInteractiva), findsWidgets);

      // Una vez mostrada, ocultarla no la desmonta: conserva su posición.
      desplazamiento(tester).jumpTo(900);
      await tester.pump();
      indice.value = 1;
      await tester.pump();
      indice.value = 0;
      await tester.pump();
      expect(desplazamiento(tester).position.pixels, 900);
    });

    testWidgets('al cruzar los 900 px del panel conserva el desplazamiento y el video en curso', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final clave = GlobalKey();
      final controlador = controladorDePrueba();
      var controladoresCreados = 0;
      Widget seccion() => SeccionComoFunciona(
        key: clave,
        crearControlador: () {
          controladoresCreados++;
          return controlador;
        },
      );
      // Las dos formas del panel: escritorio (Column) y móvil (cuerpo directo).
      Widget conColumna() => MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(child: IndexedStack(children: [seccion()])),
            ],
          ),
        ),
      );
      Widget sinColumna() => MaterialApp(
        home: Scaffold(body: IndexedStack(children: [seccion()])),
      );

      await tester.pumpWidget(conColumna());
      await tester.pump(const Duration(milliseconds: 500));
      await tocarPortada(tester, 3);
      final video = VideoFalso.creados.single;
      final posicion = desplazamiento(tester).position.pixels;
      expect(posicion, greaterThan(0));

      await tester.pumpWidget(sinColumna());
      await tester.pump();

      expect(controladoresCreados, 1);
      expect(VideoFalso.creados, hasLength(1));
      expect(video.liberado, isFalse);
      expect(video.value.isPlaying, isTrue);
      expect(desplazamiento(tester).position.pixels, posicion);
      expect(find.descendant(of: marco(3), matching: find.byType(VideoMovil)), findsOneWidget);

      // Y de vuelta.
      await tester.pumpWidget(conColumna());
      await tester.pump();
      expect(controladoresCreados, 1);
      expect(video.liberado, isFalse);
      expect(desplazamiento(tester).position.pixels, posicion);
      expect(tester.takeException(), isNull);
    });

    testWidgets('al cambiar de diseño con un video en curso, el reproductor sigue vivo', (tester) async {
      await montar(tester, tamano: escritorio);
      await tocarPortada(tester, 3);
      final video = VideoFalso.creados.single;

      tester.view.physicalSize = telefono;
      await tester.pump();
      await tester.pump();

      expect(video.liberado, isFalse);
      expect(video.value.isPlaying, isTrue);
      expect(VideoFalso.creados, hasLength(1));
      expect(find.descendant(of: marco(3), matching: find.byType(VideoMovil)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('libera el reproductor al salir de la pantalla', (tester) async {
      await montar(tester, tamano: telefono);
      await tocarPortada(tester, 3);
      final video = VideoFalso.creados.single;

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(video.liberado, isTrue);
      expect(video.veces('dispose'), 1);
      expect(VideoFalso.vivos, isEmpty);
    });

    testWidgets('usa su propio controlador de desplazamiento y no el de la ruta', (tester) async {
      tester.view.physicalSize = telefono;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final primario = ScrollController();
      addTearDown(primario.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: PrimaryScrollController(
            controller: primario,
            child: Scaffold(body: SeccionComoFunciona(crearControlador: controladorDePrueba)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(primario.hasClients, isFalse);

      // Control: una lista sin controlador sí adopta el de la ruta en Android.
      await tester.pumpWidget(
        MaterialApp(
          home: PrimaryScrollController(
            controller: primario,
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(child: ListView(children: const [SizedBox(height: 2000)])),
                  Expanded(child: SeccionComoFunciona(crearControlador: controladorDePrueba)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(primario.positions, hasLength(1));
    });

    group('al cruzar los 900 px de ancho del panel', () {
      /// Monta la sección con el controlador dado, con la ventana en [tamano].
      Future<void> montarEn(WidgetTester tester, Size tamano, ControladorComoFunciona controlador) async {
        tester.view.physicalSize = tamano;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SeccionComoFunciona(crearControlador: () => controlador)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
      }

      testWidgets('avisa al controlador cada vez que el ancho cruza el umbral, y solo entonces', (tester) async {
        final espia = espiaDePrueba();
        Widget aplicacion({double escalaTexto = 1}) => MaterialApp(
          builder: (context, hijo) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escalaTexto)),
            child: hijo!,
          ),
          home: Scaffold(body: SeccionComoFunciona(crearControlador: () => espia)),
        );
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(aplicacion());
        await tester.pump(const Duration(milliseconds: 500));
        // La primera lectura del ancho no es un cambio.
        expect(espia.reubicaciones, 0);

        // Cambios que no cruzan el umbral: más ancho, menos alto, otro tamaño de texto, otro fotograma.
        for (final tamano in const [Size(1200, 800), Size(1200, 500), Size(900, 500)]) {
          tester.view.physicalSize = tamano;
          await tester.pump();
          expect(espia.reubicaciones, 0, reason: '$tamano');
        }
        await tester.pumpWidget(aplicacion(escalaTexto: 1.5));
        await tester.pump(const Duration(seconds: 1));
        expect(espia.reubicaciones, 0);

        // A móvil: 899 px ya está por debajo del umbral.
        tester.view.physicalSize = const Size(899, 500);
        await tester.pump();
        expect(espia.reubicaciones, 1);

        // Moverse dentro de móvil no cuenta.
        for (final tamano in const [Size(600, 800), Size(320, 800)]) {
          tester.view.physicalSize = tamano;
          await tester.pump();
        }
        expect(espia.reubicaciones, 1);

        // De vuelta: exactamente 900 px ya es escritorio.
        tester.view.physicalSize = const Size(900, 800);
        await tester.pump();
        expect(espia.reubicaciones, 2);

        tester.view.physicalSize = const Size(1500, 800);
        await tester.pump();
        expect(espia.reubicaciones, 2);
      });

      testWidgets('si la ventana empieza en móvil, la primera lectura tampoco cuenta', (tester) async {
        final espia = espiaDePrueba();

        await montarEn(tester, const Size(500, 800), espia);

        expect(espia.reubicaciones, 0);
      });

      testWidgets('en Web, el video que el navegador pausó al cruzar el umbral se reanuda', (tester) async {
        final controlador = espiaDePrueba(navegador: true);
        await montarEn(tester, const Size(1000, 800), controlador);
        await tocarPortada(tester, 3);
        final video = VideoFalso.creados.single;
        expect(video.value.isPlaying, isTrue);
        final reproducciones = video.veces('play');

        tester.view.physicalSize = const Size(800, 800);
        await tester.pump();
        expect(controlador.reubicaciones, 1);
        // El navegador pausa el elemento al reinsertarlo en el documento.
        video.simularPausaDelNavegador();
        await tester.pump(const Duration(milliseconds: 150));

        expect(video.value.isPlaying, isTrue);
        expect(video.veces('play'), reproducciones + 1);
        // Sigue siendo el mismo reproductor.
        expect(VideoFalso.creados, hasLength(1));
        expect(video.liberado, isFalse);
        expect(tester.takeException(), isNull);
      });

      testWidgets('en Android e iOS el cruce no reanuda nada', (tester) async {
        final controlador = espiaDePrueba();
        await montarEn(tester, const Size(1000, 800), controlador);
        await tocarPortada(tester, 3);
        final video = VideoFalso.creados.single;

        tester.view.physicalSize = const Size(800, 800);
        await tester.pump();
        video.simularPausaDelNavegador();
        await tester.pump(const Duration(seconds: 1));

        expect(controlador.reubicaciones, 1);
        expect(video.value.isPlaying, isFalse);
        expect(video.veces('play'), 1);
      });

      testWidgets('con la pestaña oculta al cruzar, el video no se reanuda', (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controlador = espiaDePrueba(navegador: true);
        final indice = ValueNotifier<int>(0);
        addTearDown(indice.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: indice,
                builder: (_, valor, _) => IndexedStack(
                  index: valor,
                  children: [
                    SeccionComoFunciona(crearControlador: () => controlador),
                    const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tocarPortada(tester, 3);
        final video = VideoFalso.creados.single;
        final reproducciones = video.veces('play');

        // La pestaña se oculta y, a la vez, el ancho cruza el umbral.
        indice.value = 1;
        tester.view.physicalSize = const Size(800, 800);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(controlador.reubicaciones, 1);
        expect(video.value.isPlaying, isFalse);
        expect(video.veces('play'), reproducciones);
      });
    });
  });

  group('accesibilidad', () {
    /// ¿Algún marco dibujado por encima de [dentroDe] tiene borde? Es el
    /// contorno de foco: los demás adornos de la sección son de fondo.
    bool tieneContornoDeFoco(WidgetTester tester, Finder dentroDe) {
      return tester
          .widgetList<DecoratedBox>(find.descendant(of: dentroDe, matching: find.byType(DecoratedBox)))
          .any(
            (caja) =>
                caja.position == DecorationPosition.foreground && (caja.decoration as BoxDecoration).border != null,
          );
    }

    /// Nodo de foco del botón que contiene [elemento] (el que crea su `InkWell`).
    FocusNode focoDelBoton(WidgetTester tester, Finder elemento) => Focus.of(tester.element(elemento.first));

    /// Pide el foco y deja pasar dos fotogramas: el aviso de foco llega tras el
    /// primero y el contorno se dibuja en el segundo.
    Future<void> darFoco(WidgetTester tester, FocusNode nodo) async {
      nodo.requestFocus();
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      'con el teclado, las filas del riel y de la lista y los botones numerados dibujan un contorno de foco',
      (tester) async {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
        addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);

        await montar(tester, tamano: escritorio);
        final filaDelRiel = find.byType(FilaRiel).at(2);
        final filaDeLaLista = find.ancestor(
          of: find.text('Comparar perfiles y elegir con criterio'),
          matching: find.byType(InkWell),
        );
        expect(tieneContornoDeFoco(tester, filaDelRiel), isFalse);

        await darFoco(tester, focoDelBoton(tester, find.descendant(of: filaDelRiel, matching: find.byType(Stack))));
        expect(tieneContornoDeFoco(tester, filaDelRiel), isTrue);

        // Al pasar a otro botón, el contorno anterior desaparece.
        await darFoco(
          tester,
          focoDelBoton(tester, find.descendant(of: filaDeLaLista, matching: find.byType(ConstrainedBox))),
        );
        expect(tieneContornoDeFoco(tester, filaDelRiel), isFalse);
        expect(
          tieneContornoDeFoco(tester, find.ancestor(of: filaDeLaLista, matching: find.byType(ContornoDeFoco)).first),
          isTrue,
        );

        await montar(tester, tamano: telefono);
        final chip = find.ancestor(of: find.text('03'), matching: find.byType(InkWell)).first;
        expect(
          tieneContornoDeFoco(tester, find.ancestor(of: chip, matching: find.byType(ContornoDeFoco)).first),
          isFalse,
        );
        await darFoco(tester, focoDelBoton(tester, find.descendant(of: chip, matching: find.byType(SizedBox))));
        expect(
          tieneContornoDeFoco(tester, find.ancestor(of: chip, matching: find.byType(ContornoDeFoco)).first),
          isTrue,
        );
      },
    );

    testWidgets('con el toque o el ratón no se dibuja el contorno de foco', (tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);

      await montar(tester, tamano: escritorio);
      final filaDelRiel = find.byType(FilaRiel).at(2);

      await darFoco(tester, focoDelBoton(tester, find.descendant(of: filaDelRiel, matching: find.byType(Stack))));

      expect(tieneContornoDeFoco(tester, filaDelRiel), isFalse);
    });

    testWidgets('cada portada anuncia su título y su duración', (tester) async {
      final handle = tester.ensureSemantics();
      await montar(tester, tamano: telefono);

      for (final capitulo in capitulosComoFunciona) {
        await tester.ensureVisible(portadaDe(capitulo.numero));
        await tester.pump();
        expect(
          tester.getSemantics(find.bySemanticsLabel(capitulo.etiquetaReproducir)),
          isSemantics(label: capitulo.etiquetaReproducir, isButton: true, hasTapAction: true),
        );
      }
      expect(
        capitulosComoFunciona[2].etiquetaReproducir,
        'Reproducir video: ¿Cómo funciona la selección?. Duración: 48 segundos.',
      );

      handle.dispose();
    });

    testWidgets('los títulos de capítulo y del encabezado son encabezados para los lectores de pantalla', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await montar(tester, tamano: telefono);

      expect(
        tester.getSemantics(find.text('Cómo funciona ManoLegal')),
        isSemantics(label: 'Cómo funciona ManoLegal', isHeader: true),
      );
      await tester.ensureVisible(find.text(capitulosComoFunciona[0].titulo));
      await tester.pump();
      expect(
        tester.getSemantics(find.text(capitulosComoFunciona[0].titulo)),
        isSemantics(label: capitulosComoFunciona[0].titulo, isHeader: true),
      );

      handle.dispose();
    });

    testWidgets('los botones numerados anuncian el capítulo al que llevan', (tester) async {
      final handle = tester.ensureSemantics();
      await montar(tester, tamano: telefono);

      for (final capitulo in capitulosComoFunciona) {
        expect(
          tester.getSemantics(find.bySemanticsLabel('Ir al capítulo ${capitulo.numero}: ${capitulo.titulo}')),
          isSemantics(
            label: 'Ir al capítulo ${capitulo.numero}: ${capitulo.titulo}',
            isButton: true,
            hasTapAction: true,
          ),
        );
      }

      handle.dispose();
    });

    for (final tamano in [telefono, escritorio]) {
      testWidgets('los blancos táctiles miden al menos 48 dp y tienen etiqueta a ${tamano.width.toInt()} px', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await montar(tester, tamano: tamano);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // También tras desplazarse hasta el último capítulo.
        desplazamiento(tester).jumpTo(desplazamiento(tester).position.maxScrollExtent);
        await tester.pump();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      });
    }

    testWidgets('el riel de pantalla ancha usa filas más bajas si la pantalla es corta', (tester) async {
      await montar(tester, tamano: escritorio);
      expect(tester.widget<RielCapitulos>(find.byType(RielCapitulos)).compacto, isFalse);

      await montar(tester, tamano: const Size(1280, 700));
      expect(tester.widget<RielCapitulos>(find.byType(RielCapitulos)).compacto, isTrue);
      await recorrerHastaElFinal(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el encabezado se adapta: botón y lista solo en pantalla ancha', (tester) async {
      await montar(tester, tamano: telefono);
      expect(find.byType(EncabezadoComoFunciona), findsOneWidget);
      expect(find.text('Empezar por el capítulo 1'), findsNothing);
      expect(find.text('QUÉ VAS A APRENDER'), findsNothing);

      await montar(tester, tamano: escritorio);
      expect(find.text('Empezar por el capítulo 1'), findsOneWidget);
      expect(find.text('QUÉ VAS A APRENDER'), findsOneWidget);
      expect(find.text('Qué es ManoLegal y qué puedes hacer'), findsOneWidget);
      expect(find.text('Qué revisar antes de contactar y cómo usar PQRS'), findsOneWidget);
    });

    testWidgets('el rótulo de la lista va en mayúsculas, con el mismo estilo que "GUÍA EN VIDEO"', (tester) async {
      await montar(tester, tamano: escritorio);

      final guia = tester.widget<Text>(find.text('GUÍA EN VIDEO')).style!;
      final aprender = tester.widget<Text>(find.text('QUÉ VAS A APRENDER')).style!;
      expect(aprender.fontSize, guia.fontSize);
      expect(aprender.fontWeight, guia.fontWeight);
      expect(aprender.letterSpacing, guia.letterSpacing);
      expect(aprender.color, guia.color);
      // El texto ya está escrito en mayúsculas, sin depender de ninguna transformación.
      expect('QUÉ VAS A APRENDER', 'QUÉ VAS A APRENDER'.toUpperCase());
      expect(find.text('Qué vas a aprender'), findsNothing);
    });
  });
}
