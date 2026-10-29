import 'package:desarrollo/controlador/filtros_abogados.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_perfil_publico_abogado.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:flutter_test/flutter_test.dart';

ModeloPerfilPublicoAbogado _perfil({
  required String uid,
  required String nombreCompleto,
  EspecialidadAbogado especialidad = EspecialidadAbogado.civil,
  UbicacionCali? ubicacion,
  String sector = '',
  bool verificado = true,
  double calificacion = 0,
  int cantidadResenas = 0,
  double? tarifa,
}) {
  return ModeloPerfilPublicoAbogado(
    uid: uid,
    nombreCompleto: nombreCompleto,
    nombreBusqueda: normalizarTexto(nombreCompleto),
    especialidad: especialidad,
    aniosExperiencia: 5,
    ubicacionGeneral: ubicacion,
    sector: sector,
    verificado: verificado,
    calificacionPromedio: calificacion,
    cantidadResenas: cantidadResenas,
    telefonoProfesional: '+573001112233',
    correoContacto: 'contacto@ejemplo.com',
    tarifa: tarifa,
  );
}

void main() {
  final ana = _perfil(
    uid: 'a1',
    nombreCompleto: 'Ana Muñoz',
    especialidad: EspecialidadAbogado.laboral,
    ubicacion: UbicacionCali.norteCali,
    sector: 'Granada',
  );
  final jose = _perfil(
    uid: 'a2',
    nombreCompleto: 'José Pérez',
    especialidad: EspecialidadAbogado.penal,
    ubicacion: UbicacionCali.surCali,
  );
  final sinZona = _perfil(uid: 'a3', nombreCompleto: 'Carla Díaz');

  group('normalización de texto para la búsqueda', () {
    test('quita tildes, pasa a minúsculas y colapsa espacios', () {
      expect(normalizarTexto('  José   MUÑOZ  '), 'jose munoz');
      expect(normalizarTexto('Jamundí'), 'jamundi');
      expect(normalizarTexto('ÁÉÍÓÚü'), 'aeiouu');
    });

    test('un texto ya normalizado no cambia', () {
      expect(normalizarTexto('ana torres'), 'ana torres');
    });
  });

  group('filtros locales sobre resultados reales', () {
    test('una lista vacía sigue vacía: nunca se rellena con ejemplos', () {
      expect(aplicarFiltrosLocales(const []), isEmpty);
      expect(aplicarFiltrosLocales(const [], texto: 'ana'), isEmpty);
    });

    test('sin filtros devuelve todo tal cual', () {
      expect(aplicarFiltrosLocales([ana, jose, sinZona]).length, 3);
    });

    test('filtra por una zona', () {
      final resultado = aplicarFiltrosLocales(
        [ana, jose, sinZona],
        ubicaciones: [UbicacionCali.norteCali],
      );
      expect(resultado.map((p) => p.uid), ['a1']);
    });

    test('filtra por varias zonas a la vez', () {
      final resultado = aplicarFiltrosLocales(
        [ana, jose, sinZona],
        ubicaciones: [UbicacionCali.norteCali, UbicacionCali.surCali],
      );
      expect(resultado.map((p) => p.uid), ['a1', 'a2']);
    });

    test('un abogado sin zona queda fuera cuando se filtra por zona', () {
      final resultado = aplicarFiltrosLocales([sinZona], ubicaciones: [UbicacionCali.norteCali]);
      expect(resultado, isEmpty);
    });

    test('busca por nombre ignorando tildes y mayúsculas', () {
      expect(aplicarFiltrosLocales([ana, jose], texto: 'muñoz').map((p) => p.uid), ['a1']);
      expect(aplicarFiltrosLocales([ana, jose], texto: 'MUNOZ').map((p) => p.uid), ['a1']);
      expect(aplicarFiltrosLocales([ana, jose], texto: 'jose').map((p) => p.uid), ['a2']);
      expect(aplicarFiltrosLocales([ana, jose], texto: 'José').map((p) => p.uid), ['a2']);
    });

    test('busca por especialidad y por sector', () {
      expect(aplicarFiltrosLocales([ana, jose], texto: 'penal').map((p) => p.uid), ['a2']);
      expect(aplicarFiltrosLocales([ana, jose], texto: 'granada').map((p) => p.uid), ['a1']);
    });

    test('busca por el nombre de la zona', () {
      expect(aplicarFiltrosLocales([ana, jose], texto: 'sur de cali').map((p) => p.uid), ['a2']);
    });

    test('un texto sin coincidencias devuelve vacío', () {
      expect(aplicarFiltrosLocales([ana, jose], texto: 'notario'), isEmpty);
    });

    test('un texto de solo espacios no filtra nada', () {
      expect(aplicarFiltrosLocales([ana, jose], texto: '   ').length, 2);
    });

    test('la zona y el texto se combinan con Y lógico', () {
      final resultado = aplicarFiltrosLocales(
        [ana, jose],
        ubicaciones: [UbicacionCali.norteCali],
        texto: 'jose',
      );
      expect(resultado, isEmpty);
    });
  });

  group('conversión al modelo de la tarjeta del buscador', () {
    test('traslada los datos y el agregado de reputación', () {
      final conResenas = _perfil(
        uid: 'a4',
        nombreCompleto: 'Luis Gómez',
        especialidad: EspecialidadAbogado.inmobiliario,
        ubicacion: UbicacionCali.jamundi,
        calificacion: 4.5,
        cantidadResenas: 12,
        tarifa: 150000,
      );

      final tarjeta = aResultadoBusqueda(conResenas);

      expect(tarjeta.uid, 'a4');
      expect(tarjeta.especialidad, 'Derecho inmobiliario');
      expect(tarjeta.ubicacion, 'Jamundí');
      expect(tarjeta.calificacion, 4.5);
      expect(tarjeta.cantidadResenas, 12);
      expect(tarjeta.tieneResenas, isTrue);
      expect(tarjeta.tarifaDesde, 150000);
    });

    test('sin reseñas la tarjeta lo declara en vez de mostrar una nota falsa', () {
      final tarjeta = aResultadoBusqueda(sinZona);
      expect(tarjeta.cantidadResenas, 0);
      expect(tarjeta.tieneResenas, isFalse);
      expect(tarjeta.calificacion, 0);
    });

    test('sin tarifa el campo queda nulo, no en cero', () {
      // Mostrar "$0" sería anunciar un precio que el abogado no publicó.
      expect(aResultadoBusqueda(sinZona).tarifaDesde, isNull);
    });

    test('sin zona la tarjeta muestra un texto explícito', () {
      expect(aResultadoBusqueda(sinZona).ubicacion, 'Ubicación no indicada');
    });
  });

  group('lectura del perfil público desde Firestore', () {
    test('un documento vacío no rompe la lectura', () {
      final perfil = ModeloPerfilPublicoAbogado.fromMap('a9', {});
      expect(perfil.uid, 'a9');
      expect(perfil.nombreCompleto, '');
      expect(perfil.especialidad, EspecialidadAbogado.otra);
      expect(perfil.calificacionPromedio, 0);
      expect(perfil.cantidadResenas, 0);
      expect(perfil.verificado, isFalse);
      expect(perfil.experiencia, isEmpty);
    });

    test('deriva el nombre de búsqueda si el documento no lo trae', () {
      final perfil = ModeloPerfilPublicoAbogado.fromMap('a9', {'nombreCompleto': 'José Muñoz'});
      expect(perfil.nombreBusqueda, 'jose munoz');
    });
  });
}
