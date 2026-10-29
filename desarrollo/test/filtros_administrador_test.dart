import 'package:desarrollo/controlador/filtros_administrador.dart';
import 'package:desarrollo/modelo/modelo_abogado.dart';
import 'package:desarrollo/modelo/modelo_documento_abogado.dart';
import 'package:flutter_test/flutter_test.dart';

ModeloAbogado _abogado({
  String uid = 'uid-000000000000',
  String nombre = 'Ana',
  String apellido = 'Torres',
  String correo = 'ana@ejemplo.com',
  String telefono = '+573001112233',
  EspecialidadAbogado especialidad = EspecialidadAbogado.civil,
  String estado = 'pendiente',
  String? diploma,
  String cedula = 'abogados/x/documentos/cedula',
  String antecedentes = 'abogados/x/documentos/antecedentes',
}) {
  return ModeloAbogado(
    uid: uid,
    nombre: nombre,
    apellido: apellido,
    fechaNacimiento: DateTime(1990, 1, 1),
    telefono: telefono,
    correo: correo,
    telefonoProfesional: '+573004445566',
    especialidad: especialidad,
    aniosExperiencia: 5,
    descripcion: '',
    fotoPerfilRuta: '',
    documentos: ModeloDocumentoAbogado(
      cedulaRuta: cedula,
      tarjetaProfesionalRuta: 'abogados/x/documentos/tarjeta_profesional',
      certificadoRnaRuta: 'abogados/x/documentos/certificado_rna',
      diplomaRuta: diploma,
      antecedentesRuta: antecedentes,
    ),
    estado: estado,
  );
}

void main() {
  group('resumen de verificación', () {
    test('sin abogados todo vale cero', () {
      final resumen = calcularResumen(const []);
      expect(resumen.total, 0);
      expect(resumen.verificados, 0);
      expect(resumen.pendientes, 0);
      expect(resumen.proporcionVerificados, 0);
      expect(resumen.porcentajes, (0, 0));
    });

    test('cuenta verificados y pendientes', () {
      final resumen = calcularResumen([
        _abogado(estado: 'verificado'),
        _abogado(estado: 'verificado'),
        _abogado(estado: 'pendiente'),
      ]);
      expect(resumen.total, 3);
      expect(resumen.verificados, 2);
      expect(resumen.pendientes, 1);
    });

    test('un estado desconocido cuenta como pendiente, nunca como verificado', () {
      final resumen = calcularResumen([_abogado(estado: 'rechazado'), _abogado(estado: 'VERIFICADO')]);
      expect(resumen.verificados, 0);
      expect(resumen.pendientes, 2);
    });
  });

  group('porcentajes del gráfico', () {
    (int, int) porcentajes(int verificados, int total) =>
        ResumenVerificacion(total: total, verificados: verificados).porcentajes;

    test('siempre suman 100', () {
      for (final (verificados, total) in [(1, 3), (2, 3), (1, 7), (5, 9), (13, 17)]) {
        final (v, p) = porcentajes(verificados, total);
        expect(v + p, 100, reason: '$verificados de $total');
      }
    });

    test('redondea normalmente cuando no hay extremos', () {
      expect(porcentajes(1, 3), (33, 67));
      expect(porcentajes(1, 2), (50, 50));
    });

    test('una categoría presente nunca aparece como 0 %', () {
      expect(porcentajes(1, 300), (1, 99));
      expect(porcentajes(299, 300), (99, 1));
    });

    test('100 % solo cuando es la única categoría', () {
      expect(porcentajes(300, 300), (100, 0));
      expect(porcentajes(0, 5), (0, 100));
    });
  });

  group('filtros del listado', () {
    final lista = [
      _abogado(uid: 'aaaa1111', nombre: 'José', apellido: 'Muñoz', correo: 'jose@ley.co', estado: 'verificado'),
      _abogado(
        uid: 'bbbb2222',
        nombre: 'Ana',
        apellido: 'Torres',
        especialidad: EspecialidadAbogado.penal,
      ),
      _abogado(uid: 'cccc3333', nombre: 'Luis', apellido: 'Gómez', especialidad: EspecialidadAbogado.laboral),
    ];

    test('sin criterios devuelve todo', () {
      expect(filtrarAbogados(lista).length, 3);
    });

    test('busca por nombre sin tildes ni mayúsculas', () {
      expect(filtrarAbogados(lista, texto: 'MUNOZ').map((a) => a.uid), ['aaaa1111']);
      expect(filtrarAbogados(lista, texto: 'josé').map((a) => a.uid), ['aaaa1111']);
    });

    test('busca por correo, UID y especialidad', () {
      expect(filtrarAbogados(lista, texto: 'ley.co').map((a) => a.uid), ['aaaa1111']);
      expect(filtrarAbogados(lista, texto: 'bbbb').map((a) => a.uid), ['bbbb2222']);
      expect(filtrarAbogados(lista, texto: 'laboral').map((a) => a.uid), ['cccc3333']);
    });

    test('filtra por estado', () {
      expect(filtrarAbogados(lista, estado: FiltroEstadoAbogado.verificados).length, 1);
      expect(filtrarAbogados(lista, estado: FiltroEstadoAbogado.pendientes).length, 2);
    });

    test('filtra por especialidad', () {
      expect(filtrarAbogados(lista, especialidad: EspecialidadAbogado.penal).map((a) => a.uid), ['bbbb2222']);
    });

    test('los criterios se combinan con Y lógico', () {
      final resultado = filtrarAbogados(
        lista,
        texto: 'ana',
        estado: FiltroEstadoAbogado.verificados,
      );
      expect(resultado, isEmpty);
    });

    test('un texto de solo espacios no filtra', () {
      expect(filtrarAbogados(lista, texto: '   ').length, 3);
    });
  });

  group('orden para la revisión', () {
    test('pendientes primero y luego por apellido', () {
      final ordenados = ordenarParaRevision([
        _abogado(uid: '1', apellido: 'Zapata', estado: 'verificado'),
        _abogado(uid: '2', apellido: 'Álvarez', estado: 'verificado'),
        _abogado(uid: '3', apellido: 'Rojas'),
        _abogado(uid: '4', apellido: 'Díaz'),
      ]);
      expect(ordenados.map((a) => a.uid), ['4', '3', '2', '1']);
    });

    test('no modifica la lista original', () {
      final original = [_abogado(uid: '1', apellido: 'B'), _abogado(uid: '2', apellido: 'A')];
      ordenarParaRevision(original);
      expect(original.map((a) => a.uid), ['1', '2']);
    });
  });

  group('documentación registrada', () {
    test('los cinco documentos en el orden del registro, solo el diploma es opcional', () {
      final documentos = documentosDeVerificacion(_abogado());
      expect(documentos.map((d) => d.etiqueta), [
        'Cédula de ciudadanía',
        'Tarjeta profesional',
        'Certificado de vigencia RNA',
        'Diploma de pregrado',
        'Antecedentes disciplinarios',
      ]);
      expect(documentos.where((d) => !d.obligatorio).single.etiqueta, 'Diploma de pregrado');
    });

    test('completa sin diploma', () {
      final estado = estadoDocumentacion(_abogado());
      expect(estado.completa, isTrue);
      expect(estado.diplomaCargado, isFalse);
      expect(estado.resumen, '4/4');
    });

    test('completa con diploma', () {
      final estado = estadoDocumentacion(_abogado(diploma: 'abogados/x/documentos/diploma'));
      expect(estado.resumen, '4/4 · +Diploma');
    });

    test('una ruta vacía o de espacios cuenta como no cargada', () {
      final estado = estadoDocumentacion(_abogado(cedula: '', antecedentes: '   ', diploma: ''));
      expect(estado.obligatoriosCargados, 2);
      expect(estado.completa, isFalse);
      expect(estado.diplomaCargado, isFalse);
      expect(estado.resumen, '2/4');
    });
  });

  group('formatos cortos', () {
    test('abrevia el UID a ocho caracteres', () {
      expect(abreviarUid('AbCdEfGh12345678'), 'AbCdEfGh…');
      expect(abreviarUid('corto'), 'corto');
    });

    test('formatea tamaños con coma decimal', () {
      expect(formatearTamanio(512), '512 B');
      expect(formatearTamanio(850 * 1024), '850 KB');
      expect(formatearTamanio((1.25 * 1024 * 1024).round()), '1,3 MB');
    });
  });
}
