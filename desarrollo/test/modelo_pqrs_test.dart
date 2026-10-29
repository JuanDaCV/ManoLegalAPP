import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desarrollo/controlador/servicio_storage.dart';
import 'package:desarrollo/modelo/modelo_evidencia_pqrs.dart';
import 'package:desarrollo/modelo/modelo_pqrs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TipoPqrs', () {
    test('guarda exactamente los valores que aceptan las reglas', () {
      expect(TipoPqrs.values.map((tipo) => tipo.valor), ['peticion', 'queja', 'reclamo', 'solicitud']);
    });

    test('muestra los cuatro tipos con su nombre', () {
      expect(TipoPqrs.values.map((tipo) => tipo.etiqueta), ['Petición', 'Queja', 'Reclamo', 'Solicitud']);
    });

    test('reconoce los valores guardados y rechaza los desconocidos', () {
      expect(TipoPqrs.desdeValor('queja'), TipoPqrs.queja);
      expect(TipoPqrs.desdeValor('otro'), isNull);
      expect(TipoPqrs.desdeValor(null), isNull);
    });
  });

  group('ModeloPqrs', () {
    const evidencia = ModeloEvidenciaPqrs(
      nombreArchivo: 'factura.pdf',
      ruta: 'pqrs/uidA/p1/evidencia_1.pdf',
      tipoContenido: 'application/pdf',
      tamanio: 2048,
    );

    test('al crearla solo lleva los campos que el usuario puede escribir', () {
      const pqrs = ModeloPqrs(
        id: 'p1',
        uid: 'uidA',
        tipo: TipoPqrs.queja,
        descripcion: 'La cita no se cumplió.',
        evidencias: [evidencia],
        // Aunque el modelo los tuviera, nunca viajan al crear.
        radicado: 'PQ-2026-000001',
        estado: 'recibida',
      );

      final mapa = pqrs.toMapCreacion();

      expect(mapa.keys.toSet(), {'uid', 'tipo', 'descripcion', 'evidencias', 'creadoEn', 'actualizadoEn'});
      expect(mapa['tipo'], 'queja');
      expect(mapa['creadoEn'], isA<FieldValue>());
      expect(mapa['actualizadoEn'], isA<FieldValue>());
      expect(mapa['evidencias'], [
        {
          'nombreArchivo': 'factura.pdf',
          'ruta': 'pqrs/uidA/p1/evidencia_1.pdf',
          'tipoContenido': 'application/pdf',
          'tamanio': 2048,
        },
      ]);
    });

    test('lee el radicado y el estado que escribe la Cloud Function', () {
      final creada = DateTime.utc(2026, 9, 27, 15, 30);
      final pqrs = ModeloPqrs.fromMap('p1', {
        'uid': 'uidA',
        'tipo': 'reclamo',
        'descripcion': 'Cobro duplicado.',
        'evidencias': [
          // Según la plataforma, Firestore entrega los mapas anidados sin
          // el tipo genérico exacto.
          <Object?, Object?>{
            'nombreArchivo': 'captura.png',
            'ruta': 'pqrs/uidA/p1/evidencia_1.png',
            'tipoContenido': 'image/png',
            'tamanio': 512,
          },
        ],
        'radicado': 'PQ-2026-000123',
        'estado': 'recibida',
        'creadoEn': Timestamp.fromDate(creada),
      });

      expect(pqrs.tipo, TipoPqrs.reclamo);
      expect(pqrs.radicado, 'PQ-2026-000123');
      expect(pqrs.estado, 'recibida');
      // toDate() devuelve hora local: se compara el instante, no la zona.
      expect(pqrs.creadoEn!.isAtSameMomentAs(creada), isTrue);
      expect(pqrs.evidencias.single.ruta, 'pqrs/uidA/p1/evidencia_1.png');
      expect(pqrs.evidencias.single.tipoContenido, 'image/png');
    });

    test('tolera un documento incompleto sin romper la interfaz', () {
      final pqrs = ModeloPqrs.fromMap('p1', {});

      expect(pqrs.radicado, isNull);
      expect(pqrs.evidencias, isEmpty);
      expect(pqrs.creadoEn, isNull);
    });
  });

  group('validaciones del formulario', () {
    test('el tipo es obligatorio', () {
      expect(validarTipoPqrs(null), 'Selecciona el tipo de PQRS.');
      expect(validarTipoPqrs(TipoPqrs.solicitud), isNull);
    });

    test('la descripción es obligatoria y no puede ser solo espacios', () {
      expect(validarDescripcionPqrs(null), 'Describe tu solicitud.');
      expect(validarDescripcionPqrs('   \n  '), 'Describe tu solicitud.');
      expect(validarDescripcionPqrs('Necesito un certificado.'), isNull);
    });

    test('la descripción respeta el máximo de las reglas', () {
      expect(validarDescripcionPqrs('a' * longitudMaximaDescripcionPqrs), isNull);
      expect(validarDescripcionPqrs('a' * (longitudMaximaDescripcionPqrs + 1)), isNotNull);
    });
  });

  group('ruta de una evidencia en Storage', () {
    test('usa la carpeta de la PQRS y la extensión que exigen las reglas', () {
      expect(ServicioStorage.rutaEvidenciaPqrs('uidA', 'p1', 1, 'application/pdf'), 'pqrs/uidA/p1/evidencia_1.pdf');
      expect(ServicioStorage.rutaEvidenciaPqrs('uidA', 'p1', 2, 'image/png'), 'pqrs/uidA/p1/evidencia_2.png');
      expect(ServicioStorage.rutaEvidenciaPqrs('uidA', 'p1', 3, 'image/jpeg'), 'pqrs/uidA/p1/evidencia_3.jpg');
    });

    test('rechaza un tipo de archivo no admitido', () {
      expect(() => ServicioStorage.rutaEvidenciaPqrs('uidA', 'p1', 1, 'text/plain'), throwsArgumentError);
    });
  });
}
