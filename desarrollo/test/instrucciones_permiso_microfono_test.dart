import 'package:desarrollo/configuracion/configuracion_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/textos_dictado_lexus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String instrucciones(bool esWeb, TargetPlatform plataforma) =>
      instruccionesPermisoMicrofono(esWeb: esWeb, plataforma: plataforma);

  group('instruccionesPermisoMicrofono', () {
    test('web: icono junto a la dirección, permitir y recargar', () {
      final texto = instrucciones(true, TargetPlatform.android);

      expect(texto, contains('junto a la dirección'));
      expect(texto, contains('candado'));
      expect(texto, contains('permite el uso del micrófono'));
      expect(texto, contains('recarga la página'));
      expect(texto, isNot(contains('Ajustes >')));
    });

    test('la web manda sobre la plataforma del sistema', () {
      expect(
        instrucciones(true, TargetPlatform.iOS),
        instrucciones(true, TargetPlatform.android),
      );
    });

    test(
      'Android: Ajustes > Aplicaciones > ManoLegal > Permisos > Micrófono',
      () {
        final texto = instrucciones(false, TargetPlatform.android);

        expect(
          texto,
          contains('Ajustes > Aplicaciones > ManoLegal > Permisos > Micrófono'),
        );
      },
    );

    test('iOS: Ajustes > ManoLegal > Micrófono', () {
      final texto = instrucciones(false, TargetPlatform.iOS);

      expect(texto, contains('Ajustes > ManoLegal > Micrófono'));
      expect(texto, isNot(contains('Aplicaciones')));
    });

    test('otras plataformas: ajustes de privacidad del sistema', () {
      for (final plataforma in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          instrucciones(false, plataforma),
          contains('ajustes de privacidad'),
          reason: plataforma.name,
        );
      }
    });

    test('siempre recuerda que se puede seguir escribiendo', () {
      for (final esWeb in [true, false]) {
        for (final plataforma in TargetPlatform.values) {
          expect(
            instrucciones(esWeb, plataforma),
            contains('puedes seguir escribiendo tu consulta'),
            reason: '$esWeb / ${plataforma.name}',
          );
        }
      }
    });
  });

  group('TextosDictadoLexus.cuentaAtras', () {
    test('formatea minutos y segundos', () {
      expect(
        TextosDictadoLexus.cuentaAtras(const Duration(minutes: 2)),
        '2:00',
      );
      expect(
        TextosDictadoLexus.cuentaAtras(const Duration(minutes: 1, seconds: 45)),
        '1:45',
      );
      expect(
        TextosDictadoLexus.cuentaAtras(const Duration(seconds: 9)),
        '0:09',
      );
      expect(TextosDictadoLexus.cuentaAtras(Duration.zero), '0:00');
    });

    test('redondea hacia arriba: 0:00 solo aparece al terminar', () {
      expect(
        TextosDictadoLexus.cuentaAtras(const Duration(milliseconds: 400)),
        '0:01',
      );
      expect(
        TextosDictadoLexus.cuentaAtras(const Duration(milliseconds: 119500)),
        '2:00',
      );
    });

    test('el máximo configurado se muestra como 2:00', () {
      expect(
        TextosDictadoLexus.cuentaAtras(ConfiguracionLexus.duracionMaximaAudio),
        '2:00',
      );
    });
  });
}
