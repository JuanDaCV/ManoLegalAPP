import 'package:cloud_firestore/cloud_firestore.dart';
// `modelo_abogado.dart` reexporta `especialidad_abogado.dart`, que es lo que
// mantiene compilando los archivos que solo importan el modelo.
import 'package:desarrollo/modelo/modelo_abogado.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:flutter_test/flutter_test.dart';

/// Documento mínimo tal como lo escribía la versión anterior de la
/// aplicación: sin ninguno de los campos agregados en esta integración.
Map<String, dynamic> _documentoAntiguo() => {
      'nombre': 'Ana',
      'apellido': 'Torres',
      'fechaNacimiento': Timestamp.fromDate(DateTime(1990, 5, 20)),
      'telefono': '+573001112233',
      'correo': 'ana@ejemplo.com',
      'telefonoProfesional': '+573004445566',
      'especialidad': 'civil',
      'aniosExperiencia': 8,
      'descripcion': 'Abogada civil',
      'documentos': {
        'cedulaRuta': 'abogados/a1/documentos/cedula',
        'tarjetaProfesionalRuta': 'abogados/a1/documentos/tarjeta_profesional',
        'certificadoRnaRuta': 'abogados/a1/documentos/certificado_rna',
        'antecedentesRuta': 'abogados/a1/documentos/antecedentes',
      },
      'estado': 'pendiente',
    };

void main() {
  group('tolerancia de fromMap con documentos existentes', () {
    test('un documento sin los campos nuevos se lee con valores por defecto', () {
      // Es el caso real de las cuentas creadas antes de esta integración.
      // Fallar aquí dejaría inaccesible un abogado ya registrado.
      final abogado = ModeloAbogado.fromMap('a1', _documentoAntiguo());

      expect(abogado.uid, 'a1');
      expect(abogado.ubicacionGeneral, isNull);
      expect(abogado.sector, '');
      expect(abogado.direccionProfesional, '');
      expect(abogado.instagram, isNull);
      expect(abogado.experiencia, isEmpty);
      expect(abogado.correoContacto, '');
      expect(abogado.fotoPerfilRuta, '');
      expect(abogado.tarifa, isNull);
    });

    test('un campo estructural ausente sí falla, no se oculta', () {
      // La ausencia de `nombre` indica una corrupción real del documento.
      final incompleto = _documentoAntiguo()..remove('nombre');
      expect(() => ModeloAbogado.fromMap('a1', incompleto), throwsA(isA<TypeError>()));
    });

    test('lee los campos nuevos cuando existen', () {
      final documento = _documentoAntiguo()
        ..['ubicacionGeneral'] = 'surCali'
        ..['sector'] = 'San Fernando'
        ..['direccionProfesional'] = 'Calle 5 #38-25'
        ..['instagram'] = 'https://instagram.com/ana'
        ..['correoContacto'] = 'contacto@ejemplo.com'
        ..['experiencia'] = [
          {'id': 'e1', 'titulo': 'Especialización', 'detalle': 'Icesi', 'anio': '2019'},
        ];

      final abogado = ModeloAbogado.fromMap('a1', documento);

      expect(abogado.ubicacionGeneral, UbicacionCali.surCali);
      expect(abogado.sector, 'San Fernando');
      expect(abogado.experiencia.single.titulo, 'Especialización');
      expect(abogado.correoContacto, 'contacto@ejemplo.com');
    });
  });

  group('especialidad: una sola fuente para todo el sistema', () {
    test('cada valor viaja a Firestore y vuelve intacto', () {
      for (final valor in EspecialidadAbogado.values) {
        expect(especialidadDesdeClave(valor.clave), valor);
      }
    });

    test('una clave desconocida cae en "otra" en vez de romper la lectura', () {
      expect(especialidadDesdeClave('derecho_espacial'), EspecialidadAbogado.otra);
      expect(especialidadDesdeClave(null), EspecialidadAbogado.otra);
      expect(especialidadDesdeClave(42), EspecialidadAbogado.otra);
    });

    test('la especialidad inmobiliaria existe en el modelo', () {
      // La interfaz la ofrecía sin que el modelo la tuviera: ese desajuste es
      // lo que esta integración corrigió.
      expect(EspecialidadAbogado.values, contains(EspecialidadAbogado.inmobiliario));
      expect(EspecialidadAbogado.inmobiliario.textoLegible, 'Derecho inmobiliario');
    });
  });

  group('ubicación', () {
    test('cada zona viaja y vuelve intacta', () {
      for (final valor in UbicacionCali.values) {
        expect(ubicacionDesdeClave(valor.clave), valor);
      }
    });

    test('una zona desconocida devuelve nulo', () {
      expect(ubicacionDesdeClave('medellin'), isNull);
      expect(ubicacionDesdeClave(null), isNull);
    });
  });

  group('proyección al perfil público', () {
    test('no arrastra datos privados', () {
      final abogado = ModeloAbogado.fromMap('a1', _documentoAntiguo());
      final publico = abogado.aPerfilPublico();

      expect(publico.uid, 'a1');
      expect(publico.nombreCompleto, 'Ana Torres');
      // Los agregados nacen en cero y los mantiene la Cloud Function.
      expect(publico.calificacionPromedio, 0);
      expect(publico.cantidadResenas, 0);
      expect(publico.verificado, isFalse);
      // El correo de contacto cae al de la cuenta cuando no se declaró otro.
      expect(publico.correoContacto, 'ana@ejemplo.com');
      // El teléfono publicado es el profesional, nunca el personal.
      expect(publico.telefonoProfesional, '+573004445566');
      expect(publico.telefonoProfesional, isNot('+573001112233'));
    });

    test('un abogado verificado se proyecta como verificado', () {
      final documento = _documentoAntiguo()..['estado'] = 'verificado';
      expect(ModeloAbogado.fromMap('a1', documento).aPerfilPublico().verificado, isTrue);
    });

    test('el nombre de búsqueda queda normalizado', () {
      final documento = _documentoAntiguo()
        ..['nombre'] = 'José'
        ..['apellido'] = 'Muñoz';
      expect(ModeloAbogado.fromMap('a1', documento).aPerfilPublico().nombreBusqueda, 'jose munoz');
    });
  });
}
