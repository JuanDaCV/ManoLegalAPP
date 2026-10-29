import 'dart:async';

import 'package:desarrollo/controlador/controlador_pqrs.dart';
import 'package:desarrollo/modelo/modelo_pqrs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_pqrs.dart';

/// Deja pasar los eventos pendientes del stream.
Future<void> procesarEventos() => Future<void>.delayed(Duration.zero);

void main() {
  late PqrsFalso pqrs;
  late StorageFalso storage;

  setUp(() {
    pqrs = PqrsFalso();
    storage = StorageFalso();
  });

  tearDown(() => pqrs.flujo.close());

  ControladorPqrs crear({String? Function()? obtenerUid, Duration espera = const Duration(seconds: 45)}) {
    final controlador = ControladorPqrs(
      servicioPqrs: pqrs,
      servicioStorage: storage,
      obtenerUid: obtenerUid ?? () => 'uidA',
      obtenerCorreo: () => 'laura@ejemplo.com',
      esperaAntesDeAviso: espera,
    );
    addTearDown(controlador.dispose);
    return controlador;
  }

  test('sin evidencias: crea la PQRS del usuario y muestra el radicado que asigna el backend', () async {
    final controlador = crear()..iniciarNueva(TipoPqrs.peticion);
    expect(controlador.etapa, EtapaPqrs.formulario);
    expect(controlador.tipoInicial, TipoPqrs.peticion);

    await controlador.enviar(tipo: TipoPqrs.peticion, descripcion: '  Necesito un certificado.  ', evidencias: []);

    final creada = pqrs.creadas.single;
    expect(creada.uid, 'uidA');
    expect(creada.tipo, TipoPqrs.peticion);
    expect(creada.descripcion, 'Necesito un certificado.');
    expect(creada.evidencias, isEmpty);
    expect(creada.radicado, isNull, reason: 'Flutter nunca inventa el radicado');
    expect(controlador.etapa, EtapaPqrs.esperandoRadicado);

    pqrs.asignarRadicado('PQ-2026-000007');
    await procesarEventos();

    expect(controlador.etapa, EtapaPqrs.confirmada);
    expect(controlador.pqrs!.radicado, 'PQ-2026-000007');
  });

  test('mientras el documento no tiene radicado, sigue esperando', () async {
    final controlador = crear();
    await controlador.enviar(tipo: TipoPqrs.queja, descripcion: 'Demora.', evidencias: []);

    pqrs.flujo.add(pqrs.creadas.single); // la escritura propia, todavía sin radicado
    await procesarEventos();

    expect(controlador.etapa, EtapaPqrs.esperandoRadicado);
  });

  test('con evidencias: las sube a la carpeta de la PQRS y guarda solo su ruta', () async {
    final controlador = crear();

    await controlador.enviar(
      tipo: TipoPqrs.reclamo,
      descripcion: 'Cobro duplicado.',
      evidencias: [archivoDePrueba('factura.pdf', 'application/pdf'), archivoDePrueba('captura.png', 'image/png')],
    );

    expect(storage.subidas, ['pqrs/uidA/pqrs1/evidencia_1.pdf', 'pqrs/uidA/pqrs1/evidencia_2.png']);
    final evidencias = pqrs.creadas.single.evidencias;
    expect(evidencias.map((e) => e.ruta), storage.subidas);
    expect(evidencias.map((e) => e.nombreArchivo), ['factura.pdf', 'captura.png']);
    expect(evidencias.map((e) => e.tipoContenido), ['application/pdf', 'image/png']);
    expect(storage.eliminadas, isEmpty);
  });

  test('si una evidencia falla, borra las ya subidas y no crea la PQRS', () async {
    storage.fallarEnNumero = 2;
    final controlador = crear()..iniciarNueva();

    await controlador.enviar(
      tipo: TipoPqrs.reclamo,
      descripcion: 'Cobro duplicado.',
      evidencias: [archivoDePrueba('factura.pdf', 'application/pdf'), archivoDePrueba('captura.png', 'image/png')],
    );

    expect(pqrs.creadas, isEmpty);
    expect(storage.eliminadas, ['pqrs/uidA/pqrs1/evidencia_1.pdf']);
    expect(controlador.mensajeError, contains('captura.png'));
    expect(controlador.etapa, EtapaPqrs.formulario);
    expect(controlador.enviando, isFalse);
  });

  test('si falla la creación, borra las evidencias que alcanzaron a subir', () async {
    pqrs.fallarAlCrear = true;
    final controlador = crear()..iniciarNueva();

    await controlador.enviar(
      tipo: TipoPqrs.solicitud,
      descripcion: 'Actualizar mis datos.',
      evidencias: [archivoDePrueba('cedula.jpg', 'image/jpeg')],
    );

    expect(storage.eliminadas, ['pqrs/uidA/pqrs1/evidencia_1.jpg']);
    expect(controlador.mensajeError, contains('permiso'));
    expect(controlador.etapa, EtapaPqrs.formulario);
  });

  test('un segundo envío mientras el primero sigue en curso no hace nada', () async {
    pqrs.retenerCreacion = Completer<void>();
    final controlador = crear();

    final primero = controlador.enviar(tipo: TipoPqrs.queja, descripcion: 'Uno.', evidencias: []);
    expect(controlador.enviando, isTrue);
    await controlador.enviar(tipo: TipoPqrs.queja, descripcion: 'Uno.', evidencias: []);

    pqrs.retenerCreacion!.complete();
    await primero;

    expect(pqrs.creadas, hasLength(1));
    expect(pqrs.idsGenerados, 1);
  });

  test('sin sesión no sube ni crea nada', () async {
    final controlador = crear(obtenerUid: () => null);

    await controlador.enviar(
      tipo: TipoPqrs.peticion,
      descripcion: 'Hola.',
      evidencias: [archivoDePrueba('factura.pdf', 'application/pdf')],
    );

    expect(storage.subidas, isEmpty);
    expect(pqrs.creadas, isEmpty);
    expect(controlador.mensajeError, contains('sesión'));
  });

  test('si el radicado tarda, avisa sin dejar de esperar y lo muestra cuando llega', () async {
    final controlador = crear(espera: const Duration(milliseconds: 20));
    await controlador.enviar(tipo: TipoPqrs.peticion, descripcion: 'Hola.', evidencias: []);

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(controlador.esperaProlongada, isTrue);
    expect(controlador.etapa, EtapaPqrs.esperandoRadicado);

    pqrs.asignarRadicado('PQ-2026-000008');
    await procesarEventos();
    expect(controlador.etapa, EtapaPqrs.confirmada);
    expect(controlador.pqrs!.radicado, 'PQ-2026-000008');
  });

  test('si no se puede consultar el radicado, lo informa sin perder el envío', () async {
    final controlador = crear();
    await controlador.enviar(tipo: TipoPqrs.peticion, descripcion: 'Hola.', evidencias: []);

    pqrs.flujo.addError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
    await procesarEventos();

    expect(controlador.errorEspera, isNotNull);
    expect(pqrs.creadas, hasLength(1));
  });
}
