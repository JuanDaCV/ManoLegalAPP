import 'dart:convert';

import 'package:desarrollo/configuracion/configuracion_lexus.dart';
import 'package:desarrollo/modelo/error_lexus.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_respuesta_lexus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_lexus.dart';

void main() {
  Matcher esInvalida() => throwsA(
    isA<ErrorLexus>().having(
      (e) => e.tipo,
      'tipo',
      TipoErrorLexus.respuestaInvalida,
    ),
  );

  group('desdeJson', () {
    test('interpreta una respuesta válida completa', () {
      final respuesta = ModeloRespuestaLexus.desdeJson(
        jsonLexus(
          respuesta: '  Cuéntame más.  ',
          area: 'laboral',
          urgente: true,
          sugerir: true,
          preguntas: ['¿Cuánto tiempo llevas?'],
        ),
      );

      expect(respuesta.respuesta, 'Cuéntame más.');
      expect(respuesta.ambito, AmbitoLexus.juridico);
      expect(respuesta.areaProbable, EspecialidadAbogado.laboral);
      expect(respuesta.urgente, isTrue);
      expect(respuesta.sugerirAbogados, isTrue);
      expect(respuesta.preguntasPendientes, ['¿Cuánto tiempo llevas?']);
    });

    test('acepta el JSON dentro de una cerca de código', () {
      final json = jsonLexus(respuesta: 'Hola.');

      expect(
        ModeloRespuestaLexus.desdeJson('```json\n$json\n```').respuesta,
        'Hola.',
      );
      expect(
        ModeloRespuestaLexus.desdeJson('```\n$json\n```').respuesta,
        'Hola.',
      );
    });

    test('rechaza JSON inválido y lo que no es un objeto', () {
      expect(() => ModeloRespuestaLexus.desdeJson('no es json'), esInvalida());
      expect(() => ModeloRespuestaLexus.desdeJson(''), esInvalida());
      expect(() => ModeloRespuestaLexus.desdeJson('[1, 2]'), esInvalida());
      expect(() => ModeloRespuestaLexus.desdeJson('"texto"'), esInvalida());
    });

    test('rechaza una respuesta ausente, no textual o en blanco cuando debe haber texto', () {
      expect(
        () => ModeloRespuestaLexus.desdeJson(jsonLexus(respuesta: null)),
        esInvalida(),
      );
      expect(
        () => ModeloRespuestaLexus.desdeJson(jsonLexus(respuesta: '   ')),
        esInvalida(),
      );
      expect(
        () => ModeloRespuestaLexus.desdeJson(
          jsonEncode({'respuesta': 5, 'ambito': 'manolegal'}),
        ),
        esInvalida(),
      );
    });

    test('fuera de alcance y manipulación no necesitan texto', () {
      for (final ambito in ['fuera_de_alcance', 'intento_de_manipulacion']) {
        final respuesta = ModeloRespuestaLexus.desdeJson(
          jsonLexus(respuesta: null, ambito: ambito),
        );
        expect(respuesta.respuesta, isEmpty, reason: ambito);
      }
    });

    test('rechaza un ámbito ausente o desconocido', () {
      expect(
        () => ModeloRespuestaLexus.desdeJson(jsonLexus(ambito: 'otro')),
        esInvalida(),
      );
      expect(
        () =>
            ModeloRespuestaLexus.desdeJson(jsonEncode({'respuesta': 'Hola.'})),
        esInvalida(),
      );
      expect(
        () => ModeloRespuestaLexus.desdeJson(
          jsonEncode({'respuesta': 'Hola.', 'ambito': 3}),
        ),
        esInvalida(),
      );
    });

    test('un área desconocida, vacía o no textual es nula y no "otra"', () {
      expect(
        ModeloRespuestaLexus.desdeJson(jsonLexus(area: 'astrologia'))
            .areaProbable,
        isNull,
      );
      expect(
        ModeloRespuestaLexus.desdeJson(jsonLexus(area: '')).areaProbable,
        isNull,
      );
      expect(
        ModeloRespuestaLexus.desdeJson(jsonLexus(area: null)).areaProbable,
        isNull,
      );
      expect(
        ModeloRespuestaLexus.desdeJson(
          jsonEncode({
            'respuesta': 'Hola.',
            'ambito': 'juridico',
            'area_probable': 7,
          }),
        ).areaProbable,
        isNull,
      );
      expect(
        ModeloRespuestaLexus.desdeJson(jsonLexus(area: 'otra')).areaProbable,
        EspecialidadAbogado.otra,
      );
    });

    test('las banderas que no son booleanas valen falso', () {
      final respuesta = ModeloRespuestaLexus.desdeJson(
        jsonEncode({
          'respuesta': 'Hola.',
          'ambito': 'juridico',
          'urgente': 'sí',
          'sugerir_abogados': 1,
        }),
      );

      expect(respuesta.urgente, isFalse);
      expect(respuesta.sugerirAbogados, isFalse);
    });

    test(
      'filtra las preguntas en blanco o no textuales y conserva como máximo 3',
      () {
        final respuesta = ModeloRespuestaLexus.desdeJson(
          jsonEncode({
            'respuesta': 'Hola.',
            'ambito': 'juridico',
            'preguntas_pendientes': [
              'Uno',
              '  ',
              4,
              'Dos',
              null,
              'Tres',
              'Cuatro',
            ],
          }),
        );

        expect(respuesta.preguntasPendientes, ['Uno', 'Dos', 'Tres']);
        expect(
          ModeloRespuestaLexus.desdeJson(
            jsonEncode({
              'respuesta': 'Hola.',
              'ambito': 'juridico',
              'preguntas_pendientes': 'no es lista',
            }),
          ).preguntasPendientes,
          isEmpty,
        );
      },
    );

    test('recorta una respuesta demasiado larga en una palabra y agrega puntos suspensivos', () {
      final larga = List.filled(2000, 'palabra').join(' ');

      final respuesta = ModeloRespuestaLexus.desdeJson(
        jsonLexus(respuesta: larga),
      ).respuesta;

      expect(
        respuesta.length,
        lessThanOrEqualTo(ConfiguracionLexus.largoMaximoRespuesta),
      );
      expect(respuesta, endsWith('palabra…'));
      expect(
        respuesta.length,
        greaterThan(ConfiguracionLexus.largoMaximoRespuesta - 20),
      );
    });

    test('no recorta una respuesta que cabe', () {
      final justa = 'a' * ConfiguracionLexus.largoMaximoRespuesta;

      expect(
        ModeloRespuestaLexus.desdeJson(jsonLexus(respuesta: justa)).respuesta,
        justa,
      );
    });
  });

  test('AmbitoLexus.desdeClave reconoce las cuatro claves y nada más', () {
    expect(AmbitoLexus.desdeClave('juridico'), AmbitoLexus.juridico);
    expect(AmbitoLexus.desdeClave('manolegal'), AmbitoLexus.manolegal);
    expect(
      AmbitoLexus.desdeClave('fuera_de_alcance'),
      AmbitoLexus.fueraDeAlcance,
    );
    expect(
      AmbitoLexus.desdeClave('intento_de_manipulacion'),
      AmbitoLexus.intentoDeManipulacion,
    );
    expect(AmbitoLexus.desdeClave('Juridico'), isNull);
    expect(AmbitoLexus.desdeClave(null), isNull);
    expect(AmbitoLexus.desdeClave(1), isNull);
  });
}
