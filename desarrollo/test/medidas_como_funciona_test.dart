import 'package:desarrollo/vista/cliente/widgets/como_funciona/medidas_como_funciona.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Las medidas son una función pura del tamaño de la sección: se prueban sin
// montar widgets, en todos los anchos y altos que importan.
// =============================================================================

void main() {
  const anchos = [320.0, 360.0, 412.0, 600.0, 768.0, 900.0, 1024.0, 1100.0, 1280.0, 1440.0, 1920.0, 2560.0];
  const altos = [480.0, 640.0, 720.0, 800.0, 900.0, 1080.0, 1440.0];

  /// Recorre todas las combinaciones de ancho y alto.
  void paraCadaTamano(void Function(double ancho, double alto, MedidasComoFunciona medidas) comprobar) {
    for (final ancho in anchos) {
      for (final alto in altos) {
        comprobar(ancho, alto, MedidasComoFunciona.de(ancho: ancho, alto: alto));
      }
    }
  }

  group('modo según el ancho', () {
    test('compacto por debajo de 600, medio por debajo de 1100 y ancho desde ahí', () {
      for (final (ancho, modo) in [
        (320.0, ModoComoFunciona.compacto),
        (360.0, ModoComoFunciona.compacto),
        (412.0, ModoComoFunciona.compacto),
        (599.9, ModoComoFunciona.compacto),
        (600.0, ModoComoFunciona.medio),
        (768.0, ModoComoFunciona.medio),
        (900.0, ModoComoFunciona.medio),
        (1024.0, ModoComoFunciona.medio),
        (1099.9, ModoComoFunciona.medio),
        (1100.0, ModoComoFunciona.ancho),
        (1280.0, ModoComoFunciona.ancho),
        (1440.0, ModoComoFunciona.ancho),
        (1920.0, ModoComoFunciona.ancho),
        (2560.0, ModoComoFunciona.ancho),
      ]) {
        expect(MedidasComoFunciona.de(ancho: ancho, alto: 800).modo, modo, reason: 'ancho $ancho');
      }
    });

    test('el riel solo existe en el modo ancho', () {
      paraCadaTamano((ancho, alto, medidas) {
        if (medidas.modo == ModoComoFunciona.ancho) {
          expect(medidas.anchoRiel, greaterThan(0));
        } else {
          expect(medidas.anchoRiel, 0, reason: '$ancho×$alto');
          expect(medidas.separacionRiel, 0, reason: '$ancho×$alto');
        }
      });
    });
  });

  group('márgenes y ancho del contenido', () {
    test('el contenido cabe entre los márgenes y nunca queda vacío', () {
      paraCadaTamano((ancho, alto, medidas) {
        expect(medidas.anchoContenido, lessThanOrEqualTo(ancho - 2 * medidas.margen + 0.001), reason: '$ancho×$alto');
        expect(medidas.anchoContenido, greaterThan(0), reason: '$ancho×$alto');
        // El contenido está centrado: lo que sobra a cada lado nunca es menor que el margen.
        expect(medidas.rellenoHorizontal, greaterThanOrEqualTo(medidas.margen - 0.001), reason: '$ancho×$alto');
      });
    });

    test('valores concretos en los anchos de referencia', () {
      final telefono = MedidasComoFunciona.de(ancho: 360, alto: 800);
      expect((telefono.margen, telefono.anchoContenido), (16, 328));

      final tabletaAngosta = MedidasComoFunciona.de(ancho: 600, alto: 960);
      expect((tabletaAngosta.margen, tabletaAngosta.anchoContenido), (24, 552));

      final tableta = MedidasComoFunciona.de(ancho: 1024, alto: 768);
      expect((tableta.margen, tableta.anchoContenido), (32, 800));

      final portatil = MedidasComoFunciona.de(ancho: 1280, alto: 720);
      expect((portatil.margen, portatil.anchoContenido), (32, 1216));

      final monitor = MedidasComoFunciona.de(ancho: 1920, alto: 1080);
      expect((monitor.margen, monitor.anchoContenido), (280, 1360));
    });

    test('el contenido en pantallas muy anchas se detiene en 1360 px', () {
      for (final ancho in [1440.0, 1920.0, 2560.0, 3840.0]) {
        expect(MedidasComoFunciona.de(ancho: ancho, alto: 900).anchoContenido, 1360, reason: 'ancho $ancho');
      }
    });
  });

  group('riel y columna de capítulos', () {
    test('el riel mide 264 con 40 de separación por debajo de 1280 y 280 con 56 desde ahí', () {
      final angosto = MedidasComoFunciona.de(ancho: 1100, alto: 800);
      expect((angosto.anchoRiel, angosto.separacionRiel), (264, 40));
      final ancho = MedidasComoFunciona.de(ancho: 1280, alto: 800);
      expect((ancho.anchoRiel, ancho.separacionRiel), (280, 56));
    });

    test('a cada capítulo le quedan al menos 640 px en modo ancho', () {
      paraCadaTamano((ancho, alto, medidas) {
        if (medidas.modo != ModoComoFunciona.ancho) return;
        expect(medidas.anchoColumna, greaterThanOrEqualTo(640), reason: '$ancho×$alto');
        expect(medidas.anchoColumna, medidas.anchoContenido - medidas.anchoRiel - medidas.separacionRiel);
      });
    });

    test('el riel se compacta en pantallas bajas (menos de 720 px)', () {
      expect(MedidasComoFunciona.de(ancho: 1280, alto: 719.9).rielCompacto, isTrue);
      expect(MedidasComoFunciona.de(ancho: 1280, alto: 720).rielCompacto, isFalse);
      expect(MedidasComoFunciona.de(ancho: 1280, alto: 480).rielCompacto, isTrue);
      expect(MedidasComoFunciona.de(ancho: 1280, alto: 1080).rielCompacto, isFalse);
    });
  });

  group('video horizontal 16:9', () {
    test('nunca pasa de 976 px y cabe con su marco azul', () {
      paraCadaTamano((ancho, alto, medidas) {
        expect(medidas.anchoVideoHorizontal, lessThanOrEqualTo(976), reason: '$ancho×$alto');
        expect(medidas.anchoVideoHorizontal, greaterThan(0), reason: '$ancho×$alto');
        if (medidas.modo == ModoComoFunciona.ancho) {
          expect(medidas.anchoVideoHorizontal, greaterThanOrEqualTo(480), reason: '$ancho×$alto');
          // 24 px de marco azul alrededor del video.
          expect(
            medidas.anchoVideoHorizontal + 24,
            lessThanOrEqualTo(medidas.anchoColumna + 0.001),
            reason: '$ancho×$alto',
          );
        } else {
          // En tarjetas, el video llena el contenido.
          expect(medidas.anchoVideoHorizontal, medidas.anchoContenido, reason: '$ancho×$alto');
        }
      });
    });

    test('en pantallas de 1920 o más ocupa menos del 60% del ancho', () {
      paraCadaTamano((ancho, alto, medidas) {
        if (ancho < 1920) return;
        expect(medidas.anchoVideoHorizontal, lessThan(0.6 * ancho), reason: '$ancho×$alto');
      });
    });

    test('en pantallas bajas se reduce para que quepa junto al texto', () {
      // alto 720 (escalón 720): (720 - 234) * 16 / 9 = 864, menos que el límite de 976.
      expect(MedidasComoFunciona.de(ancho: 1920, alto: 720).anchoVideoHorizontal, closeTo(864, 0.001));
      expect(MedidasComoFunciona.de(ancho: 1920, alto: 1080).anchoVideoHorizontal, 976);
      // En 1280×720 el límite lo pone la columna: 880 - 24.
      expect(MedidasComoFunciona.de(ancho: 1280, alto: 720).anchoVideoHorizontal, 856);
    });
  });

  group('video vertical 9:16', () {
    test('su ancho queda dentro de los límites de cada modo', () {
      paraCadaTamano((ancho, alto, medidas) {
        final razon = '$ancho×$alto';
        final anchoVideo = medidas.anchoVideoVertical;
        switch (medidas.modo) {
          case ModoComoFunciona.compacto:
            expect(anchoVideo, inInclusiveRange(200, 300), reason: razon);
            expect(anchoVideo, lessThanOrEqualTo(medidas.anchoContenido - 48 + 0.001), reason: razon);
            expect(medidas.verticalAlLado, isFalse, reason: razon);
          case ModoComoFunciona.medio:
            if (medidas.verticalAlLado) {
              expect(medidas.anchoContenido, greaterThanOrEqualTo(680), reason: razon);
              expect(medidas.altoVideoVertical, inInclusiveRange(460, 600), reason: razon);
            } else {
              expect(anchoVideo, inInclusiveRange(200, 300), reason: razon);
              expect(anchoVideo, lessThanOrEqualTo(medidas.anchoContenido - 48 + 0.001), reason: razon);
            }
          case ModoComoFunciona.ancho:
            expect(medidas.altoVideoVertical, inInclusiveRange(480, 720), reason: razon);
            expect(medidas.verticalAlLado, isFalse, reason: razon);
        }
        expect(medidas.altoVideoVertical, closeTo(anchoVideo * 16 / 9, 0.001), reason: razon);
      });
    });

    test('en tabletas, el vertical va al lado del texto solo si hay 680 px de contenido', () {
      expect(MedidasComoFunciona.de(ancho: 600, alto: 960).verticalAlLado, isFalse);
      expect(MedidasComoFunciona.de(ancho: 720, alto: 960).verticalAlLado, isFalse);
      expect(MedidasComoFunciona.de(ancho: 744, alto: 960).verticalAlLado, isTrue);
      expect(MedidasComoFunciona.de(ancho: 1024, alto: 768).verticalAlLado, isTrue);
    });

    test('no lanza en pantallas diminutas', () {
      expect(() => MedidasComoFunciona.de(ancho: 200, alto: 300), returnsNormally);
      expect(MedidasComoFunciona.de(ancho: 200, alto: 300).anchoVideoVertical, greaterThan(0));
    });
  });

  group('alto escalonado', () {
    test('se redondea hacia abajo a múltiplos de 80', () {
      for (final (entrada, esperado) in [
        (800.0, 800.0),
        (879.9, 800.0),
        (880.0, 880.0),
        (79.0, 0.0),
        (1079.0, 1040.0),
      ]) {
        expect(MedidasComoFunciona.de(ancho: 1280, alto: entrada).alto, esperado, reason: 'alto $entrada');
      }
    });

    test('un alto no finito se trata como 800', () {
      expect(MedidasComoFunciona.de(ancho: 1280, alto: double.infinity).alto, 800);
      expect(MedidasComoFunciona.de(ancho: 1280, alto: double.nan).alto, 800);
    });

    test('las medidas no se mueven mientras el alto se mantiene en su escalón (barra de direcciones)', () {
      for (final ancho in anchos) {
        for (var base = 480.0; base <= 1440; base += 80) {
          final referencia = MedidasComoFunciona.de(ancho: ancho, alto: base);
          // Hasta 79 px más arriba del escalón (la barra del navegador se esconde).
          for (final desviacion in [1.0, 20.0, 40.0, 79.0]) {
            final medidas = MedidasComoFunciona.de(ancho: ancho, alto: base + desviacion);
            final razon = '$ancho×${base + desviacion}';
            expect(medidas.alto, referencia.alto, reason: razon);
            expect(medidas.anchoVideoHorizontal, referencia.anchoVideoHorizontal, reason: razon);
            expect(medidas.anchoVideoVertical, referencia.anchoVideoVertical, reason: razon);
            expect(medidas.rielCompacto, referencia.rielCompacto, reason: razon);
            expect(medidas.verticalAlLado, referencia.verticalAlLado, reason: razon);
          }
        }
      }
    });
  });

  group('tamaños de texto por modo', () {
    test('título del encabezado 26 / 32 / 40 y lead 14,5 / 16 / 17', () {
      final compacto = MedidasComoFunciona.de(ancho: 360, alto: 800);
      final medio = MedidasComoFunciona.de(ancho: 800, alto: 800);
      final ancho = MedidasComoFunciona.de(ancho: 1440, alto: 900);
      expect([compacto.tamTituloEncabezado, medio.tamTituloEncabezado, ancho.tamTituloEncabezado], [26, 32, 40]);
      expect([compacto.tamLeadEncabezado, medio.tamLeadEncabezado, ancho.tamLeadEncabezado], [14.5, 16, 17]);
    });

    test('título del capítulo 20 / 24 / 30 y descripción 14 / 15 / 16', () {
      final compacto = MedidasComoFunciona.de(ancho: 360, alto: 800);
      final medio = MedidasComoFunciona.de(ancho: 800, alto: 800);
      final ancho = MedidasComoFunciona.de(ancho: 1440, alto: 900);
      expect([compacto.tamTituloCapitulo, medio.tamTituloCapitulo, ancho.tamTituloCapitulo], [20, 24, 30]);
      expect([compacto.tamDescripcion, medio.tamDescripcion, ancho.tamDescripcion], [14, 15, 16]);
    });

    test('numeral fantasma 0 / 64 / 96', () {
      final compacto = MedidasComoFunciona.de(ancho: 360, alto: 800);
      final medio = MedidasComoFunciona.de(ancho: 800, alto: 800);
      final ancho = MedidasComoFunciona.de(ancho: 1440, alto: 900);
      expect([compacto.tamNumeralFantasma, medio.tamNumeralFantasma, ancho.tamNumeralFantasma], [0, 64, 96]);
    });

    test('anchos máximos de lectura: sin tope en teléfono, 620 px en tableta y 520 / 560 px en escritorio', () {
      final compacto = MedidasComoFunciona.de(ancho: 360, alto: 800);
      final medio = MedidasComoFunciona.de(ancho: 800, alto: 800);
      final ancho = MedidasComoFunciona.de(ancho: 1440, alto: 900);
      expect([compacto.anchoMaxLead, medio.anchoMaxLead, ancho.anchoMaxLead], [double.infinity, 620, 520]);
      expect(
        [compacto.anchoMaxDescripcion, medio.anchoMaxDescripcion, ancho.anchoMaxDescripcion],
        [double.infinity, 620, 560],
      );
    });

    test('el tope de 620 px de la tableta vale en todo el modo medio y no cambia con el alto', () {
      for (final ancho in [600.0, 768.0, 900.0, 1024.0, 1099.0]) {
        for (final alto in altos) {
          final medidas = MedidasComoFunciona.de(ancho: ancho, alto: alto);
          expect(medidas.modo, ModoComoFunciona.medio, reason: '$ancho×$alto');
          expect((medidas.anchoMaxLead, medidas.anchoMaxDescripcion), (620, 620), reason: '$ancho×$alto');
        }
      }
    });
  });
}
