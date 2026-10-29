import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desarrollo/modelo/modelo_resena.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validación de una reseña antes de publicarla', () {
    String? validar({
      int calificacion = 4,
      String comentario = 'Muy buena atención.',
      String abogadoUid = 'abogado-1',
      String clienteUid = 'cliente-1',
    }) {
      return validarResena(
        calificacion: calificacion,
        comentario: comentario,
        abogadoUid: abogadoUid,
        clienteUid: clienteUid,
      );
    }

    test('una reseña correcta no devuelve error', () {
      expect(validar(), isNull);
    });

    test('las cinco calificaciones válidas se aceptan', () {
      for (var estrellas = 1; estrellas <= 5; estrellas++) {
        expect(validar(calificacion: estrellas), isNull, reason: 'falló con $estrellas estrellas');
      }
    });

    test('rechaza una calificación de cero', () {
      expect(validar(calificacion: 0), 'Selecciona una calificación de 1 a 5 estrellas.');
    });

    test('rechaza una calificación mayor que cinco', () {
      expect(validar(calificacion: 6), 'Selecciona una calificación de 1 a 5 estrellas.');
    });

    test('rechaza una calificación negativa', () {
      expect(validar(calificacion: -3), 'Selecciona una calificación de 1 a 5 estrellas.');
    });

    test('rechaza un comentario vacío o de solo espacios', () {
      expect(validar(comentario: ''), 'Escribe un comentario para publicar tu reseña.');
      expect(validar(comentario: '     '), 'Escribe un comentario para publicar tu reseña.');
    });

    test('rechaza un comentario de más de 500 caracteres', () {
      expect(
        validar(comentario: 'a' * 501),
        'El comentario no puede superar los 500 caracteres.',
      );
      expect(validar(comentario: 'a' * 500), isNull);
    });

    test('un abogado no puede reseñarse a sí mismo', () {
      expect(
        validar(abogadoUid: 'mismo-uid', clienteUid: 'mismo-uid'),
        'No puedes dejar una reseña en tu propio perfil.',
      );
    });
  });

  group('mapeo de la reseña desde y hacia Firestore', () {
    test('lee un documento completo', () {
      final resena = ModeloResena.fromMap('cliente-7', {
        'abogadoUid': 'abogado-3',
        'autor': 'Carlos Pérez',
        'calificacion': 5,
        'comentario': 'Excelente asesoría.',
        'fecha': Timestamp.fromDate(DateTime(2026, 3, 15)),
      });

      expect(resena.clienteUid, 'cliente-7');
      expect(resena.abogadoUid, 'abogado-3');
      expect(resena.autor, 'Carlos Pérez');
      expect(resena.calificacion, 5);
      expect(resena.fecha, DateTime(2026, 3, 15));
    });

    test('tolera un documento sin campos opcionales', () {
      final resena = ModeloResena.fromMap('cliente-7', {});
      expect(resena.abogadoUid, '');
      expect(resena.autor, '');
      expect(resena.comentario, '');
      expect(resena.fecha, isNotNull);
    });

    test('acota una calificación corrupta al rango visible', () {
      // No "corrige" el dato en la base: solo evita que un valor inválido
      // rompa la interfaz. La Cloud Function lo descarta al promediar.
      expect(ModeloResena.fromMap('c', {'calificacion': 0}).calificacion, 1);
      expect(ModeloResena.fromMap('c', {'calificacion': 99}).calificacion, 5);
    });
  });
}
