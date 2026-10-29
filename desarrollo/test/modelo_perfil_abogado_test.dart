import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_experiencia_profesional.dart';
import 'package:desarrollo/modelo/modelo_perfil_abogado.dart';
import 'package:desarrollo/modelo/modelo_perfil_publico_abogado.dart';
import 'package:desarrollo/modelo/modelo_resena.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:flutter_test/flutter_test.dart';

/// Construye un perfil mínimo y permite sobrescribir lo que cada prueba
/// necesita, para que cada caso muestre solo el dato que está comprobando.
ModeloPerfilAbogado _perfil({
  DateTime? fechaNacimiento,
  List<ModeloResena> resenas = const [],
  double calificacion = 0,
  int cantidadResenas = 0,
  String sobreMi = '',
  List<ModeloExperienciaProfesional> experiencia = const [],
  String direccion = '',
  String? instagram,
  String? fotoUrl,
  String nombreCompleto = 'Ana Torres',
}) {
  return ModeloPerfilAbogado(
    uid: 'abogado-1',
    nombreCompleto: nombreCompleto,
    fechaNacimiento: fechaNacimiento,
    especialidad: 'Derecho civil',
    verificado: false,
    ubicacionGeneral: '',
    sector: '',
    direccion: direccion,
    sobreMi: sobreMi,
    experiencia: experiencia,
    instagram: instagram,
    resenas: resenas,
    fotoUrl: fotoUrl,
    tarifa: null,
    telefonoContacto: '+573001112233',
    correoContacto: 'ana@ejemplo.com',
    calificacion: calificacion,
    cantidadResenas: cantidadResenas,
  );
}

ModeloResena _resena(int calificacion) => ModeloResena(
      abogadoUid: 'abogado-1',
      clienteUid: 'cliente-$calificacion',
      autor: 'Cliente',
      calificacion: calificacion,
      comentario: 'Comentario',
      fecha: DateTime(2026, 1, 1),
    );

void main() {
  group('edad derivada de la fecha de nacimiento', () {
    // Las fechas se construyen relativas a hoy para que las pruebas no
    // caduquen con el paso del tiempo.
    final ahora = DateTime.now();

    test('cumple años hoy: la edad ya está cumplida', () {
      final perfil = _perfil(fechaNacimiento: DateTime(ahora.year - 30, ahora.month, ahora.day));
      expect(perfil.edad, 30);
    });

    test('el cumpleaños ya pasó este año', () {
      final perfil = _perfil(fechaNacimiento: DateTime(ahora.year - 30, ahora.month, ahora.day - 1));
      expect(perfil.edad, 30);
    });

    test('el cumpleaños todavía no llega: resta un año', () {
      final perfil = _perfil(fechaNacimiento: DateTime(ahora.year - 30, ahora.month, ahora.day + 1));
      expect(perfil.edad, 29);
    });

    test('nacido un 29 de febrero: no falla y da una edad coherente', () {
      final perfil = _perfil(fechaNacimiento: DateTime(2000, 2, 29));
      final esperada = ahora.year - 2000;
      expect(perfil.edad, anyOf(esperada, esperada - 1));
    });

    test('sin fecha de nacimiento la edad es nula, no cero', () {
      // El perfil público no publica la fecha de nacimiento a propósito. Un
      // cero aquí se mostraría como "0 años".
      expect(_perfil().edad, isNull);
    });
  });

  group('calificación y cantidad de reseñas', () {
    test('sin reseñas la calificación es 0 y tieneResenas es falso', () {
      final perfil = _perfil();
      expect(perfil.calificacion, 0);
      expect(perfil.cantidadResenas, 0);
      expect(perfil.tieneResenas, isFalse);
    });

    test('la calificación viene del agregado, no del promedio de la lista', () {
      // Regresión importante: la lista mostrada puede estar incompleta, así
      // que promediarla daría un número distinto al que guarda Firestore.
      final perfil = _perfil(
        resenas: [_resena(1), _resena(1)],
        calificacion: 4.5,
        cantidadResenas: 20,
      );
      expect(perfil.calificacion, 4.5);
      expect(perfil.cantidadResenas, 20);
      expect(perfil.tieneResenas, isTrue);
    });
  });

  group('porcentaje de completitud', () {
    test('un perfil vacío está al 0 %', () {
      expect(_perfil().porcentajeCompletitud, 0);
    });

    test('cada campo completado suma un quinto', () {
      final perfil = _perfil(
        fotoUrl: 'https://ejemplo/foto.jpg',
        sobreMi: 'Abogada civil',
        direccion: 'Calle 1',
      );
      expect(perfil.porcentajeCompletitud, closeTo(3 / 5, 0.0001));
    });

    test('una red social con cadena vacía no cuenta como completada', () {
      // Al borrar el texto, el formulario envía '' y no null.
      expect(_perfil(instagram: '   ').tieneAlgunaRed, isFalse);
      expect(_perfil(instagram: 'https://instagram.com/ana').tieneAlgunaRed, isTrue);
    });
  });

  group('iniciales del avatar', () {
    test('toma la primera y la última palabra', () {
      expect(_perfil(nombreCompleto: 'Ana María Torres').iniciales, 'AT');
    });

    test('con un solo nombre toma una sola letra', () {
      expect(_perfil(nombreCompleto: 'Ana').iniciales, 'A');
    });

    test('con el nombre vacío no falla', () {
      expect(_perfil(nombreCompleto: '   ').iniciales, '');
    });
  });

  group('construcción desde el perfil público', () {
    test('no expone fecha de nacimiento y conserva el agregado', () {
      final publico = ModeloPerfilPublicoAbogado(
        uid: 'abogado-1',
        nombreCompleto: 'Ana Torres',
        especialidad: EspecialidadAbogado.inmobiliario,
        aniosExperiencia: 8,
        ubicacionGeneral: UbicacionCali.surCali,
        verificado: true,
        calificacionPromedio: 4.25,
        cantidadResenas: 4,
        telefonoProfesional: '+573001112233',
        correoContacto: 'ana@ejemplo.com',
      );

      final perfil = ModeloPerfilAbogado.desdePerfilPublico(publico);

      expect(perfil.fechaNacimiento, isNull);
      expect(perfil.edad, isNull);
      expect(perfil.calificacion, 4.25);
      expect(perfil.cantidadResenas, 4);
      expect(perfil.verificado, isTrue);
      expect(perfil.especialidad, 'Derecho inmobiliario');
      expect(perfil.ubicacionGeneral, 'Sur de Cali');
    });
  });

  group('conversión de ubicación desde su texto legible', () {
    test('reconoce una zona conocida sin importar mayúsculas', () {
      expect(ubicacionDesdeTextoLegible('norte de cali'), UbicacionCali.norteCali);
      expect(ubicacionDesdeTextoLegible('Jamundí'), UbicacionCali.jamundi);
    });

    test('devuelve nulo para un texto desconocido o vacío', () {
      expect(ubicacionDesdeTextoLegible(''), isNull);
      expect(ubicacionDesdeTextoLegible('Bogotá'), isNull);
    });
  });
}
