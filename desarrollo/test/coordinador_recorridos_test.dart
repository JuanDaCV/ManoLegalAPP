import 'dart:async';

import 'package:desarrollo/controlador/coordinador_recorridos.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/modelo/modelo_recorrido.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_recorrido.dart';

/// Un recorrido mínimo de prueba: bienvenida, un paso sobre [marca] y cierre.
ModeloRecorrido _recorrido(
  String id,
  MarcaRecorridoId marca, {
  Duration espera = const Duration(milliseconds: 200),
}) {
  return ModeloRecorrido(
    id: id,
    prefijoClave: 'prueba.$id.',
    pasos: [
      const ModeloPasoRecorrido(
        id: 'bienvenida',
        tipo: TipoPasoRecorrido.bienvenida,
        titulo: 'Hola',
        descripcion: 'Prueba.',
      ),
      ModeloPasoRecorrido(
        id: 'paso',
        tipo: TipoPasoRecorrido.resaltado,
        marca: marca,
        titulo: 'Paso',
        descripcion: 'Prueba.',
      ),
      const ModeloPasoRecorrido(
        id: 'cierre',
        tipo: TipoPasoRecorrido.cierre,
        titulo: 'Listo',
        descripcion: 'Prueba.',
      ),
    ],
    marcaInicial: marca,
    esperaInicial: espera,
    esperaCarga: const Duration(milliseconds: 5),
  );
}

final _inicio = _recorrido('inicio', MarcaRecorridoId.buscador);
final _pqrs = _recorrido('pqrs', MarcaRecorridoId.pqrsCategorias);

/// Espera a que terminen las lecturas y unas cuantas consultas a la vista.
Future<void> _dejarCorrer() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late PuenteVistaFalso vista;
  late AlmacenMemoria almacen;
  late CoordinadorRecorridos coordinador;
  var desechado = false;

  setUp(() {
    vista = PuenteVistaFalso();
    almacen = AlmacenMemoria();
    desechado = false;
    coordinador = CoordinadorRecorridos(
      // Sección 2 sin recorrido.
      recorridos: [_inicio, _pqrs, null],
      vista: vista,
      obtenerUid: () => 'uid-1',
      almacen: almacen,
      intervaloSondeo: const Duration(milliseconds: 1),
    );
  });

  tearDown(() {
    if (!desechado) coordinador.dispose();
  });

  test('al entrar en una sección muestra su recorrido y lo activa', () async {
    vista.disponibles.add(MarcaRecorridoId.buscador);
    var avisos = 0;
    coordinador.addListener(() => avisos++);

    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();

    final activo = coordinador.controladorActivo;
    expect(activo.visible, isTrue);
    expect(activo.pasoActual?.id, 'bienvenida');
    expect(coordinador.seccionActiva, 0);
    expect(avisos, 1);
  });

  test('solo hay un recorrido visible a la vez', () async {
    vista.disponibles.addAll({
      MarcaRecorridoId.buscador,
      MarcaRecorridoId.pqrsCategorias,
    });
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();
    final deInicio = coordinador.controladorActivo;

    // Con el de Inicio en pantalla, cambiar de sección se ignora.
    coordinador.alEntrarEnSeccion(1);
    await _dejarCorrer();

    expect(coordinador.hayRecorridoVisible, isTrue);
    expect(identical(coordinador.controladorActivo, deInicio), isTrue);
    expect(coordinador.seccionActiva, 0);
    expect(almacen.lecturas, 1);
  });

  test('cambiar de sección cancela el inicio pendiente de la anterior', () async {
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();
    final deInicio = coordinador.controladorActivo;

    coordinador.alEntrarEnSeccion(1);
    // El buscador aparece tarde (por ejemplo, al volver a dibujarse Inicio):
    // su recorrido ya no debe salir, porque el usuario está en PQRS.
    vista.disponibles.add(MarcaRecorridoId.buscador);
    await _dejarCorrer();

    expect(deInicio.visible, isFalse);
    expect(coordinador.controladorActivo.visible, isFalse);
    expect(vista.capturas, 0);
  });

  test('al volver a la sección se intenta de nuevo', () async {
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();
    coordinador.alEntrarEnSeccion(1);
    await _dejarCorrer();

    vista.disponibles.add(MarcaRecorridoId.buscador);
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();

    expect(coordinador.controladorActivo.visible, isTrue);
    expect(vista.marcaCapturada, MarcaRecorridoId.buscador);
  });

  test('un recorrido terminado no se relanza en la sesión, aunque no se haya guardado', () async {
    vista.disponibles.addAll({
      MarcaRecorridoId.buscador,
      MarcaRecorridoId.pqrsCategorias,
    });
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();
    // Almacenamiento lento: el «omitido» todavía no está escrito.
    almacen.retenerEscritura = Completer<void>();
    unawaited(coordinador.controladorActivo.omitir());

    coordinador.alEntrarEnSeccion(1);
    await _dejarCorrer();
    expect(coordinador.controladorActivo.visible, isTrue);
    unawaited(coordinador.controladorActivo.finalizar());
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();

    expect(coordinador.hayRecorridoVisible, isFalse);
    expect(coordinador.terminados, {'inicio', 'pqrs'});
    expect(vista.capturas, 2);

    almacen.retenerEscritura!.complete();
    await _dejarCorrer();
    expect(almacen.datos, {
      'prueba.inicio.uid-1': 'omitido',
      'prueba.pqrs.uid-1': 'completado',
    });
  });

  test('un recorrido ya guardado como visto no aparece', () async {
    almacen.datos['prueba.pqrs.uid-1'] = 'completado';
    vista.disponibles.add(MarcaRecorridoId.pqrsCategorias);

    coordinador.alEntrarEnSeccion(1);
    await _dejarCorrer();

    expect(coordinador.controladorActivo.visible, isFalse);
    expect(vista.capturas, 0);
  });

  test('una sección sin recorrido activa un controlador inerte', () async {
    vista.disponibles.add(MarcaRecorridoId.buscador);

    coordinador.alEntrarEnSeccion(2);
    await _dejarCorrer();

    expect(coordinador.controladorActivo.visible, isFalse);
    expect(coordinador.controladorActivo.pasosActivos, isEmpty);
    expect(almacen.lecturas, 0);
  });

  test('si un recorrido que no es el activo aparece, pasa a ser el activo', () async {
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();
    final deInicio = coordinador.controladorActivo;
    coordinador.alEntrarEnSeccion(2);
    expect(identical(coordinador.controladorActivo, deInicio), isFalse);

    // Por defensa: se fuerza un inicio del recorrido que no es el activo.
    vista.disponibles.add(MarcaRecorridoId.buscador);
    await deInicio.iniciarSiCorresponde();

    expect(deInicio.visible, isTrue);
    expect(identical(coordinador.controladorActivo, deInicio), isTrue);
  });

  test('desechar quita sus oyentes y desecha los controladores', () async {
    coordinador.alEntrarEnSeccion(0);
    await _dejarCorrer();
    final deInicio = coordinador.controladorActivo;
    var avisos = 0;
    coordinador.addListener(() => avisos++);

    desechado = true;
    coordinador.dispose();

    // Un controlador desechado ya no admite oyentes.
    expect(() => deInicio.addListener(() {}), throwsFlutterError);
    // Su inicio pendiente terminó sin mostrar nada, aunque llegue la marca.
    vista.disponibles.add(MarcaRecorridoId.buscador);
    await _dejarCorrer();
    expect(deInicio.visible, isFalse);
    expect(vista.capturas, 0);
    expect(avisos, 0);
  });
}
