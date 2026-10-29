import 'dart:async';

import 'package:desarrollo/controlador/controlador_recorrido.dart';
import 'package:desarrollo/controlador/servicio_estado_recorrido.dart';
import 'package:desarrollo/modelo/modelo_estado_recorrido.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_recorrido.dart';

/// Pasos de un recorrido de otra sección (PQRS), para probar que el motor ya
/// no depende de las marcas de Inicio.
const List<ModeloPasoRecorrido> _pasosPqrs = [
  ModeloPasoRecorrido(
    id: 'bienvenida',
    tipo: TipoPasoRecorrido.bienvenida,
    titulo: 'PQRS',
    descripcion: 'Bienvenida de prueba.',
  ),
  ModeloPasoRecorrido(
    id: 'categorias',
    tipo: TipoPasoRecorrido.resaltado,
    marca: MarcaRecorridoId.pqrsCategorias,
    titulo: 'Categorías',
    descripcion: 'Paso de prueba.',
  ),
  ModeloPasoRecorrido(
    id: 'radicar',
    tipo: TipoPasoRecorrido.resaltado,
    marca: MarcaRecorridoId.pqrsRadicar,
    requiereMarca: MarcaRecorridoId.pqrsCategorias,
    titulo: 'Radicar',
    descripcion: 'Paso que depende de las categorías.',
  ),
  ModeloPasoRecorrido(
    id: 'cierre',
    tipo: TipoPasoRecorrido.cierre,
    titulo: 'Listo',
    descripcion: 'Cierre de prueba.',
  ),
];

/// Servicio cuyo `leer` espera a que la prueba lo suelte: permite cancelar
/// justo mientras se está leyendo.
class _ServicioRetenido implements ServicioEstadoRecorrido {
  final Completer<EstadoRecorrido> lectura = Completer<EstadoRecorrido>();
  int lecturas = 0;

  @override
  Future<EstadoRecorrido> leer(String uid) {
    lecturas++;
    return lectura.future;
  }

  @override
  Future<void> guardar(String uid, EstadoRecorrido estado) async {}

  @override
  Future<void> reiniciar(String uid) async {}
}

void main() {
  late PuenteVistaFalso vista;
  late AlmacenMemoria almacen;
  final creados = <ControladorRecorrido>[];

  setUp(() {
    vista = PuenteVistaFalso();
    almacen = AlmacenMemoria();
  });

  tearDown(() {
    for (final c in creados) {
      c.dispose();
    }
    creados.clear();
  });

  ControladorRecorrido crear({
    List<ModeloPasoRecorrido> pasos = _pasosPqrs,
    MarcaRecorridoId marcaInicial = MarcaRecorridoId.pqrsCategorias,
    MarcaRecorridoId? marcaCargando,
    ServicioEstadoRecorrido? servicio,
    Duration esperaInicial = const Duration(milliseconds: 5),
    Duration esperaCarga = const Duration(milliseconds: 5),
  }) {
    final controlador = ControladorRecorrido(
      pasos: pasos,
      servicio:
          servicio ??
          ServicioEstadoRecorridoLocal(
            almacen: almacen,
            prefijoClave: 'manolegal.recorrido.compartido.pqrs.v1.',
          ),
      vista: vista,
      obtenerUid: () => 'uid-1',
      marcaInicial: marcaInicial,
      marcaCargando: marcaCargando,
      esperaBuscador: esperaInicial,
      esperaResultados: esperaCarga,
      intervaloSondeo: const Duration(milliseconds: 1),
    );
    creados.add(controlador);
    return controlador;
  }

  group('marca inicial y de carga', () {
    test(
      'espera su propia marca inicial y captura su desplazamiento',
      () async {
        vista.disponibles.add(MarcaRecorridoId.pqrsCategorias);
        final c = crear();

        await c.iniciarSiCorresponde();

        expect(c.visible, isTrue);
        expect(vista.capturas, 1);
        expect(vista.marcaCapturada, MarcaRecorridoId.pqrsCategorias);
        // Nunca pregunta por el buscador de Inicio.
        expect(vista.consultas[MarcaRecorridoId.buscador], isNull);
      },
    );

    test('sin su marca inicial no se muestra, aunque esté el buscador', () async {
      vista.disponibles.add(MarcaRecorridoId.buscador);
      final c = crear();

      await c.iniciarSiCorresponde();

      expect(c.visible, isFalse);
      expect(vista.capturas, 0);
    });

    test('sin marca de carga, comenzar no espera nada', () async {
      vista.disponibles.addAll({
        MarcaRecorridoId.pqrsCategorias,
        MarcaRecorridoId.pqrsRadicar,
        // Aunque estuviera el indicador de Inicio, no se consulta.
        MarcaRecorridoId.cargandoResultados,
      });
      final c = crear(esperaCarga: const Duration(seconds: 30));
      await c.iniciarSiCorresponde();

      await c.comenzar();

      expect(c.pasoActual?.id, 'categorias');
      expect(vista.consultas[MarcaRecorridoId.cargandoResultados], isNull);
    });

    test('con marca de carga propia, espera a que desaparezca', () async {
      vista.disponibles.addAll({
        MarcaRecorridoId.lexusAviso,
        MarcaRecorridoId.lexusCargando,
      });
      final c = crear(
        pasos: const [
          ModeloPasoRecorrido(
            id: 'bienvenida',
            tipo: TipoPasoRecorrido.bienvenida,
            titulo: 'Lexus',
            descripcion: 'Prueba.',
          ),
          ModeloPasoRecorrido(
            id: 'sugerencias',
            tipo: TipoPasoRecorrido.resaltado,
            marca: MarcaRecorridoId.lexusSugerencias,
            titulo: 'Sugerencias',
            descripcion: 'Prueba.',
          ),
          ModeloPasoRecorrido(
            id: 'cierre',
            tipo: TipoPasoRecorrido.cierre,
            titulo: 'Listo',
            descripcion: 'Prueba.',
          ),
        ],
        marcaInicial: MarcaRecorridoId.lexusAviso,
        marcaCargando: MarcaRecorridoId.lexusCargando,
        esperaCarga: const Duration(milliseconds: 200),
      );
      var consultas = 0;
      vista.alConsultar = (marca) {
        if (marca == MarcaRecorridoId.lexusCargando && ++consultas == 3) {
          // Termina de cargar la conversación y aparece la introducción.
          vista.disponibles
            ..remove(marca)
            ..add(MarcaRecorridoId.lexusSugerencias);
        }
      };
      await c.iniciarSiCorresponde();

      await c.comenzar();

      expect(consultas, 3);
      expect(c.pasoActual?.id, 'sugerencias');
    });
  });

  group('requiereMarca', () {
    test('sin la marca requerida el paso se omite, aunque la suya esté', () async {
      vista.disponibles.addAll({
        MarcaRecorridoId.pqrsCategorias,
        MarcaRecorridoId.pqrsRadicar,
      });
      final c = crear();
      await c.iniciarSiCorresponde();
      vista.disponibles.remove(MarcaRecorridoId.pqrsCategorias);

      await c.comenzar();

      expect(c.pasosActivos.map((p) => p.id), ['bienvenida', 'cierre']);
    });

    test('con la marca requerida el paso se muestra', () async {
      vista.disponibles.addAll({
        MarcaRecorridoId.pqrsCategorias,
        MarcaRecorridoId.pqrsRadicar,
      });
      final c = crear();
      await c.iniciarSiCorresponde();

      await c.comenzar();

      expect(c.pasosActivos.map((p) => p.id), [
        'bienvenida',
        'categorias',
        'radicar',
        'cierre',
      ]);
    });
  });

  group('cancelarInicio', () {
    test('cancelar mientras se lee el estado no muestra nada', () async {
      vista.disponibles.add(MarcaRecorridoId.pqrsCategorias);
      final servicio = _ServicioRetenido();
      final c = crear(servicio: servicio);

      final iniciando = c.iniciarSiCorresponde();
      c.cancelarInicio();
      servicio.lectura.complete(EstadoRecorrido.noVisto);
      await iniciando;

      expect(c.visible, isFalse);
      expect(vista.capturas, 0);
    });

    test(
      'cancelar durante la espera: aunque la marca aparezca después, no se muestra',
      () async {
        final c = crear(esperaInicial: const Duration(milliseconds: 500));

        final iniciando = c.iniciarSiCorresponde();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final consultasAntes = vista.consultas[MarcaRecorridoId.pqrsCategorias];
        c.cancelarInicio();
        vista.disponibles.add(MarcaRecorridoId.pqrsCategorias);
        await iniciando;
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(c.visible, isFalse);
        expect(vista.capturas, 0);
        // La espera vieja se detuvo al cancelar: no siguió consultando.
        expect(
          vista.consultas[MarcaRecorridoId.pqrsCategorias],
          consultasAntes,
        );
      },
    );

    test('cancelar e iniciar de nuevo: una sola captura y una sola muestra', () async {
      final c = crear(esperaInicial: const Duration(milliseconds: 500));
      var notificaciones = 0;
      c.addListener(() => notificaciones++);

      final primero = c.iniciarSiCorresponde();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      c.cancelarInicio();
      final segundo = c.iniciarSiCorresponde();
      vista.disponibles.add(MarcaRecorridoId.pqrsCategorias);
      await Future.wait([primero, segundo]);

      expect(c.visible, isTrue);
      expect(vista.capturas, 1);
      expect(notificaciones, 1);
      expect(almacen.lecturas, 2);
    });

    test('con el recorrido visible, cancelar no hace nada', () async {
      vista.disponibles.add(MarcaRecorridoId.pqrsCategorias);
      final c = crear();
      await c.iniciarSiCorresponde();

      c.cancelarInicio();
      await c.iniciarSiCorresponde();

      expect(c.visible, isTrue);
      expect(c.pasoActual?.id, 'bienvenida');
      expect(vista.capturas, 1);
      expect(almacen.lecturas, 1);
    });

    test('tras cancelar sin haber empezado, se puede volver a intentar', () async {
      final c = crear();
      await c.iniciarSiCorresponde();
      expect(c.visible, isFalse);

      c.cancelarInicio();
      vista.disponibles.add(MarcaRecorridoId.pqrsCategorias);
      await c.iniciarSiCorresponde();

      expect(c.visible, isTrue);
    });
  });

  test('desechar durante la espera no deja temporizadores vivos', () async {
    final c = crear(esperaInicial: const Duration(seconds: 30));

    final iniciando = c.iniciarSiCorresponde();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    creados.remove(c);
    c.dispose();

    // Si la espera no se interrumpiera, esto tardaría 30 s.
    await iniciando.timeout(const Duration(seconds: 1));
    expect(c.visible, isFalse);
  });
}
