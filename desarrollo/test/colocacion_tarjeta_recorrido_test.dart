import 'dart:math' as math;

import 'package:desarrollo/vista/compartido/widgets/recorrido/colocacion_tarjeta_recorrido.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rectángulo de la tarjeta para un alto de contenido dado: nunca más alto que
/// el máximo de la colocación (lo demás se desplaza dentro de la tarjeta).
Rect _rectoDeLaTarjeta(ColocacionTarjetaRecorrido colocacion, double alto) {
  final tamano = Size(colocacion.ancho, math.min(alto, colocacion.altoMaximo));
  return colocacion.posicionPara(tamano) & tamano;
}

bool _estaDentro(Rect recto, Rect area) {
  const tolerancia = 0.5;
  return recto.left >= area.left - tolerancia &&
      recto.top >= area.top - tolerancia &&
      recto.right <= area.right + tolerancia &&
      recto.bottom <= area.bottom + tolerancia;
}

void main() {
  group('tabla de pantallas', () {
    const anchos = [
      320.0,
      375.0,
      390.0,
      430.0,
      600.0,
      768.0,
      1024.0,
      1280.0,
      1440.0,
      1920.0,
    ];
    const altos = [568.0, 800.0, 1080.0];
    const altosDeTarjeta = [180.0, 320.0, 520.0];
    const rellenos = {
      'sin áreas del sistema': EdgeInsets.zero,
      'con barra de estado y de gestos': EdgeInsets.only(top: 24, bottom: 34),
    };

    /// Elementos a resaltar: un campo ancho arriba, al medio y abajo, y el
    /// panel alto de filtros de escritorio cuando la pantalla es lo bastante
    /// alta para alojarlo.
    List<(String, Rect?)> huecosPara(Size pantalla, EdgeInsets relleno) {
      final ancho = math.min(pantalla.width - 32, 800.0);
      final izquierda = (pantalla.width - ancho) / 2;
      return [
        ('sin hueco', null),
        ('arriba', Rect.fromLTWH(izquierda, relleno.top + 24, ancho, 72)),
        (
          'al medio',
          Rect.fromLTWH(izquierda, pantalla.height / 2 - 40, ancho, 80),
        ),
        (
          'abajo',
          Rect.fromLTWH(
            izquierda,
            pantalla.height - relleno.bottom - 104,
            ancho,
            80,
          ),
        ),
        if (pantalla.height >= 1000)
          ('panel alto', const Rect.fromLTWH(24, 60, 280, 900)),
      ];
    }

    for (final ancho in anchos) {
      for (final alto in altos) {
        for (final relleno in rellenos.entries) {
          test(
            '${ancho.toInt()}×${alto.toInt()} ${relleno.key}: la tarjeta cabe y no tapa el hueco',
            () {
              final pantalla = Size(ancho, alto);

              for (final (nombre, hueco) in huecosPara(
                pantalla,
                relleno.value,
              )) {
                final colocacion = calcularColocacion(
                  pantalla: pantalla,
                  relleno: relleno.value,
                  hueco: hueco,
                );

                for (final altoDeTarjeta in altosDeTarjeta) {
                  final razon =
                      '$nombre, tarjeta de $altoDeTarjeta, ${colocacion.lado.name}';
                  final recto = _rectoDeLaTarjeta(colocacion, altoDeTarjeta);

                  expect(
                    _estaDentro(recto, colocacion.areaSegura),
                    isTrue,
                    reason: '$razon: $recto fuera de ${colocacion.areaSegura}',
                  );
                  if (hueco == null) {
                    expect(
                      colocacion.lado,
                      LadoTarjetaRecorrido.centro,
                      reason: razon,
                    );
                    continue;
                  }
                  const sinTaparElHueco = {
                    LadoTarjetaRecorrido.abajo,
                    LadoTarjetaRecorrido.arriba,
                    LadoTarjetaRecorrido.derecha,
                    LadoTarjetaRecorrido.izquierda,
                  };
                  if (sinTaparElHueco.contains(colocacion.lado)) {
                    expect(
                      recto.overlaps(hueco),
                      isFalse,
                      reason: '$razon: $recto tapa $hueco',
                    );
                  }
                }

                if (nombre == 'panel alto' && ancho >= 768) {
                  expect(
                    colocacion.lado,
                    LadoTarjetaRecorrido.derecha,
                    reason: 'el panel alto deja la tarjeta a su derecha',
                  );
                }
              }
            },
          );
        }
      }
    }
  });

  group('sin hueco', () {
    test('la tarjeta va centrada en el área segura', () {
      final colocacion = calcularColocacion(
        pantalla: const Size(390, 844),
        relleno: EdgeInsets.zero,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.centro);
      expect(colocacion.hueco, isNull);
      expect(colocacion.areaSegura, const Rect.fromLTRB(16, 16, 374, 828));
      expect(colocacion.ancho, 358);
      expect(colocacion.altoMaximo, 812);
      expect(
        colocacion.posicionPara(const Size(358, 300)),
        const Offset(16, 272),
      );
    });

    test('el ancho es el menor entre 400 y el ancho útil', () {
      final angosta = calcularColocacion(
        pantalla: const Size(320, 568),
        relleno: EdgeInsets.zero,
      );
      final ancha = calcularColocacion(
        pantalla: const Size(1920, 1080),
        relleno: EdgeInsets.zero,
      );

      expect(angosta.ancho, 288);
      expect(ancha.ancho, 400);
    });

    test('respeta las áreas del sistema, también a los lados', () {
      final colocacion = calcularColocacion(
        pantalla: const Size(844, 390),
        relleno: const EdgeInsets.fromLTRB(44, 24, 44, 21),
      );

      expect(colocacion.areaSegura, const Rect.fromLTRB(60, 40, 784, 353));
    });
  });

  group('con hueco pequeño', () {
    const pantalla = Size(390, 844);

    test('hueco arriba: la tarjeta va debajo, a 14 px', () {
      const hueco = Rect.fromLTWH(16, 100, 358, 72);
      final colocacion = calcularColocacion(
        pantalla: pantalla,
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.abajo);
      expect(colocacion.altoMaximo, 828 - (172 + 14));
      expect(colocacion.posicionPara(const Size(358, 300)).dy, 172 + 14);
    });

    test('hueco abajo: la tarjeta va encima, a 14 px', () {
      const hueco = Rect.fromLTWH(16, 650, 358, 72);
      final colocacion = calcularColocacion(
        pantalla: pantalla,
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.arriba);
      expect(colocacion.altoMaximo, 650 - 14 - 16);
      final posicion = colocacion.posicionPara(const Size(358, 300));
      expect(posicion.dy + 300, 650 - 14);
    });

    test('con el mismo espacio arriba y abajo, gana abajo', () {
      const hueco = Rect.fromLTWH(16, 386, 358, 72);
      final colocacion = calcularColocacion(
        pantalla: pantalla,
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.abajo);
    });

    test('se centra sobre el hueco y se acota al área segura', () {
      final izquierda = calcularColocacion(
        pantalla: pantalla,
        relleno: EdgeInsets.zero,
        hueco: const Rect.fromLTWH(16, 100, 44, 44),
      );
      final derecha = calcularColocacion(
        pantalla: pantalla,
        relleno: EdgeInsets.zero,
        hueco: const Rect.fromLTWH(330, 100, 44, 44),
      );
      final centro = calcularColocacion(
        pantalla: const Size(1280, 800),
        relleno: EdgeInsets.zero,
        hueco: const Rect.fromLTWH(600, 100, 80, 40),
      );

      expect(izquierda.posicionPara(const Size(200, 200)).dx, 16);
      expect(derecha.posicionPara(const Size(200, 200)).dx, 374 - 200);
      expect(centro.posicionPara(const Size(400, 200)).dx, 640 - 200);
    });

    test('un hueco pequeño en un teléfono bajo deja la tarjeta en el lado con más espacio', () {
      const hueco = Rect.fromLTWH(16, 165, 288, 72);
      final colocacion = calcularColocacion(
        pantalla: const Size(320, 568),
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.abajo);
      expect(colocacion.altoMaximo, greaterThanOrEqualTo(150));
    });
  });

  group('con hueco alto', () {
    test('el panel de filtros a la izquierda deja la tarjeta a su derecha', () {
      const hueco = Rect.fromLTWH(152, 60, 280, 700);
      final colocacion = calcularColocacion(
        pantalla: const Size(1440, 900),
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.derecha);
      expect(colocacion.ancho, 400);
      expect(colocacion.altoMaximo, 868);
      final posicion = colocacion.posicionPara(const Size(400, 350));
      expect(posicion.dx, 432 + 14);
      expect(posicion.dy, 60);
    });

    test('un panel a la derecha deja la tarjeta a su izquierda', () {
      const hueco = Rect.fromLTWH(1100, 60, 280, 700);
      final colocacion = calcularColocacion(
        pantalla: const Size(1440, 900),
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.izquierda);
      final posicion = colocacion.posicionPara(const Size(400, 350));
      expect(posicion.dx + 400, 1100 - 14);
    });

    test('el ancho lateral es el espacio que hay si es menor que 400', () {
      // Espacio a la derecha: 1024 - 16 - (304 + 14) = 690 en una pantalla
      // ancha; aquí, con 700 de ancho, quedan 366.
      const hueco = Rect.fromLTWH(24, 60, 280, 700);
      final colocacion = calcularColocacion(
        pantalla: const Size(700, 900),
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.derecha);
      expect(colocacion.ancho, 700 - 16 - (304 + 14));
    });

    test('sin 300 px a los lados no va al costado: busca arriba o abajo', () {
      // Hueco alto pero con mucho aire debajo: 0.55 de 828 son 455.
      const hueco = Rect.fromLTWH(16, 16, 358, 460);
      final colocacion = calcularColocacion(
        pantalla: const Size(390, 844),
        relleno: EdgeInsets.zero,
        hueco: hueco,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.abajo);
      expect(colocacion.altoMaximo, 828 - (476 + 14));
    });

    test(
      'sin espacio en ningún lado, la tarjeta se superpone apoyada abajo',
      () {
        const hueco = Rect.fromLTWH(24, 60, 280, 900);
        final colocacion = calcularColocacion(
          pantalla: const Size(390, 1080),
          relleno: EdgeInsets.zero,
          hueco: hueco,
        );

        expect(colocacion.lado, LadoTarjetaRecorrido.superpuesta);
        expect(colocacion.altoMaximo, closeTo(0.6 * (1064 - 16), 0.001));
        final posicion = colocacion.posicionPara(const Size(358, 400));
        expect(posicion.dy + 400, colocacion.areaSegura.bottom);
      },
    );
  });

  group('tarjeta más grande que el área', () {
    test('queda pegada al borde inicial en lugar de lanzar', () {
      final colocacion = calcularColocacion(
        pantalla: const Size(390, 844),
        relleno: EdgeInsets.zero,
      );

      expect(
        colocacion.posicionPara(const Size(500, 2000)),
        const Offset(16, 16),
      );
    });

    test('una pantalla diminuta no lanza', () {
      final colocacion = calcularColocacion(
        pantalla: const Size(20, 20),
        relleno: EdgeInsets.zero,
        hueco: const Rect.fromLTWH(2, 2, 10, 10),
      );

      expect(colocacion.ancho, greaterThanOrEqualTo(0));
      expect(colocacion.altoMaximo, greaterThanOrEqualTo(0));
      expect(colocacion.posicionPara(Size.zero), isA<Offset>());
    });
  });

  group('alto mínimo de la tarjeta', () {
    // Hueco casi tan alto como la pantalla y sin 300 px a los lados: no hay
    // espacio útil en ningún lado.
    const hueco = Rect.fromLTWH(24, 60, 280, 900);

    test('superpuesta recibe lo que necesita aunque pase del 60 %', () {
      final colocacion = calcularColocacion(
        pantalla: const Size(390, 1080),
        relleno: EdgeInsets.zero,
        hueco: hueco,
        altoMinimoUtil: 800,
      );

      expect(colocacion.lado, LadoTarjetaRecorrido.superpuesta);
      expect(colocacion.altoMaximo, 800);
    });

    test('superpuesta nunca pasa del área segura', () {
      final colocacion = calcularColocacion(
        pantalla: const Size(390, 1080),
        relleno: EdgeInsets.zero,
        hueco: hueco,
        altoMinimoUtil: 5000,
      );

      expect(colocacion.altoMaximo, 1064 - 16);
    });
  });

  group('DisposicionTarjetaRecorrido', () {
    const claveTarjeta = Key('tarjeta');

    /// Una «tarjeta» de alto fijo: su alto mínimo intrínseco es ese alto.
    Future<RenderDisposicionTarjetaRecorrido> montar(
      WidgetTester tester, {
      required double altoTarjeta,
      Rect? hueco,
      EdgeInsets relleno = EdgeInsets.zero,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DisposicionTarjetaRecorrido(
            relleno: relleno,
            hueco: hueco,
            child: SizedBox(key: claveTarjeta, height: altoTarjeta),
          ),
        ),
      );
      return tester.renderObject<RenderDisposicionTarjetaRecorrido>(
        find.byType(DisposicionTarjetaRecorrido),
      );
    }

    testWidgets('con espacio junto al hueco, la tarjeta va ahí con su ancho', (
      tester,
    ) async {
      final disposicion = await montar(
        tester,
        altoTarjeta: 200,
        hueco: const Rect.fromLTWH(16, 100, 358, 72),
      );

      expect(disposicion.colocacion!.lado, LadoTarjetaRecorrido.abajo);
      expect(
        tester.getRect(find.byKey(claveTarjeta)),
        const Rect.fromLTWH(16, 172 + 14, 358, 200),
      );
    });

    testWidgets(
      'mide la tarjeta: si no le alcanza ningún lado, se superpone entera',
      (tester) async {
        // Abajo quedan 828 - (500 + 14) = 314 y arriba 300 - 14 - 16 = 270:
        // alcanza para una tarjeta de 250, no para una de 400.
        const hueco = Rect.fromLTWH(16, 300, 358, 200);
        var disposicion = await montar(tester, altoTarjeta: 250, hueco: hueco);
        expect(disposicion.colocacion!.lado, LadoTarjetaRecorrido.abajo);

        // Mismo hueco: lo que cambia es la tarjeta, y se vuelve a medir.
        disposicion = await montar(tester, altoTarjeta: 400, hueco: hueco);
        expect(disposicion.colocacion!.lado, LadoTarjetaRecorrido.superpuesta);
        expect(
          tester.getRect(find.byKey(claveTarjeta)),
          const Rect.fromLTWH(16, 828 - 400, 358, 400),
        );
      },
    );

    testWidgets(
      'vuelve a colocarla si cambian el hueco o las áreas del sistema',
      (tester) async {
        double arriba() => tester.getTopLeft(find.byKey(claveTarjeta)).dy;

        await montar(
          tester,
          altoTarjeta: 200,
          hueco: const Rect.fromLTWH(16, 100, 358, 72),
        );
        expect(arriba(), 172 + 14);

        await montar(
          tester,
          altoTarjeta: 200,
          hueco: const Rect.fromLTWH(16, 120, 358, 72),
        );
        expect(arriba(), 192 + 14);

        // Sin hueco va centrada en el área segura, que el relleno achica.
        await montar(tester, altoTarjeta: 200);
        expect(arriba(), (16 + 828) / 2 - 100);

        await montar(
          tester,
          altoTarjeta: 200,
          relleno: const EdgeInsets.only(top: 40),
        );
        expect(arriba(), (56 + 828) / 2 - 100);
      },
    );
  });
}
