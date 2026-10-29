import 'dart:async';

import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/controlador/controlador_recorrido.dart';
import 'package:desarrollo/controlador/servicio_estado_recorrido.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_recorrido.dart';

const _claveUid1 = 'manolegal.recorrido.cliente.v1.uid-1';

/// Un controlador con su almacén y su vista falsos. Las esperas son de unos
/// pocos milisegundos para que las pruebas con tiempo real sean rápidas.
class _Banco {
  _Banco({
    this.uid = 'uid-1',
    Set<MarcaRecorridoId>? marcas,
    AlmacenMemoria? almacen,
    List<ModeloPasoRecorrido>? pasos,
    Duration esperaBuscador = const Duration(milliseconds: 5),
    Duration esperaResultados = const Duration(milliseconds: 5),
  }) : almacen = almacen ?? AlmacenMemoria() {
    vista.disponibles.addAll(marcas ?? marcasDeInicioConAbogados());
    controlador = ControladorRecorrido(
      pasos: pasos ?? ConfiguracionRecorridoCliente.pasos,
      servicio: ServicioEstadoRecorridoLocal(almacen: this.almacen),
      vista: vista,
      obtenerUid: () => uid,
      esperaBuscador: esperaBuscador,
      esperaResultados: esperaResultados,
      intervaloSondeo: const Duration(milliseconds: 1),
    );
    controlador.addListener(() => notificaciones++);
  }

  String? uid;
  final AlmacenMemoria almacen;
  final PuenteVistaFalso vista = PuenteVistaFalso();
  late final ControladorRecorrido controlador;
  int notificaciones = 0;
  bool desechado = false;

  void desechar() {
    desechado = true;
    controlador.dispose();
  }

  /// Muestra la bienvenida y pulsa «Comenzar».
  Future<void> comenzar() async {
    await controlador.iniciarSiCorresponde();
    await controlador.comenzar();
  }

  List<String> get idsActivos =>
      controlador.pasosActivos.map((p) => p.id).toList();
}

void main() {
  _Banco crear({
    String? uid = 'uid-1',
    Set<MarcaRecorridoId>? marcas,
    AlmacenMemoria? almacen,
    List<ModeloPasoRecorrido>? pasos,
    Duration esperaBuscador = const Duration(milliseconds: 5),
    Duration esperaResultados = const Duration(milliseconds: 5),
  }) {
    final banco = _Banco(
      uid: uid,
      marcas: marcas,
      almacen: almacen,
      pasos: pasos,
      esperaBuscador: esperaBuscador,
      esperaResultados: esperaResultados,
    );
    addTearDown(() {
      if (!banco.desechado) banco.controlador.dispose();
    });
    return banco;
  }

  group('primer ingreso', () {
    test('muestra la bienvenida si el usuario no la ha visto', () async {
      final b = crear();

      await b.controlador.iniciarSiCorresponde();

      final c = b.controlador;
      expect(c.visible, isTrue);
      expect(c.preparando, isFalse);
      expect(c.pasoActual?.id, 'bienvenida');
      expect(c.pasoActual?.tipo, TipoPasoRecorrido.bienvenida);
      expect(c.numeroDePaso, isNull);
      expect(c.puedeRetroceder, isFalse);
      expect(c.totalPasos, 5);
      expect(b.notificaciones, 1);
    });

    test('al empezar recuerda el desplazamiento del buscador', () async {
      final b = crear();

      await b.controlador.iniciarSiCorresponde();

      expect(b.vista.capturas, 1);
      expect(b.vista.marcaCapturada, MarcaRecorridoId.buscador);
    });

    test('no se muestra si ya lo completó', () async {
      final almacen = AlmacenMemoria()..datos[_claveUid1] = 'completado';
      final b = crear(almacen: almacen);

      await b.controlador.iniciarSiCorresponde();

      expect(b.controlador.visible, isFalse);
      expect(b.vista.capturas, 0);
      expect(b.almacen.escrituras, isEmpty);
    });

    test('no se muestra si ya lo omitió', () async {
      final almacen = AlmacenMemoria()..datos[_claveUid1] = 'omitido';
      final b = crear(almacen: almacen);

      await b.controlador.iniciarSiCorresponde();

      expect(b.controlador.visible, isFalse);
      expect(b.vista.capturas, 0);
    });

    test(
      'cada usuario tiene su propio estado en el mismo dispositivo',
      () async {
        final almacen = AlmacenMemoria();
        final primero = crear(almacen: almacen);
        await primero.controlador.iniciarSiCorresponde();
        await primero.controlador.omitir();

        final mismoUsuario = crear(almacen: almacen);
        await mismoUsuario.controlador.iniciarSiCorresponde();
        final otroUsuario = crear(uid: 'uid-2', almacen: almacen);
        await otroUsuario.controlador.iniciarSiCorresponde();

        expect(mismoUsuario.controlador.visible, isFalse);
        expect(otroUsuario.controlador.visible, isTrue);
      },
    );

    test('sin usuario no se muestra y ni siquiera se lee el almacén', () async {
      final b = crear(uid: null);

      await b.controlador.iniciarSiCorresponde();

      expect(b.controlador.visible, isFalse);
      expect(b.almacen.lecturas, 0);
    });

    test('si no puede leer el estado, no se muestra (falla cerrado)', () async {
      final almacen = AlmacenMemoria()..fallarLectura = true;
      final b = crear(almacen: almacen);

      await b.controlador.iniciarSiCorresponde();

      expect(b.controlador.visible, isFalse);
      expect(b.vista.capturas, 0);
      expect(b.almacen.escrituras, isEmpty);
    });

    test(
      'si el buscador nunca está a la vista, no se muestra y no guarda nada',
      () async {
        final b = crear(marcas: {});

        await b.controlador.iniciarSiCorresponde();

        expect(b.controlador.visible, isFalse);
        expect(b.vista.consultas[MarcaRecorridoId.buscador], greaterThan(1));
        expect(b.vista.capturas, 0);
        expect(b.almacen.escrituras, isEmpty);
      },
    );

    test(
      'espera a que el buscador esté a la vista y entonces empieza',
      () async {
        final b = crear(
          marcas: {},
          esperaBuscador: const Duration(milliseconds: 100),
        );
        var consultas = 0;
        b.vista.alConsultar = (marca) {
          if (marca == MarcaRecorridoId.buscador && ++consultas == 4) {
            b.vista.disponibles.add(marca);
          }
        };

        await b.controlador.iniciarSiCorresponde();

        expect(b.controlador.visible, isTrue);
        expect(consultas, 4);
      },
    );

    test(
      'iniciar dos veces a la vez solo muestra el recorrido una vez',
      () async {
        final b = crear();

        await Future.wait([
          b.controlador.iniciarSiCorresponde(),
          b.controlador.iniciarSiCorresponde(),
        ]);

        expect(b.controlador.visible, isTrue);
        expect(b.vista.capturas, 1);
        expect(b.almacen.lecturas, 1);
        expect(b.notificaciones, 1);
      },
    );

    test(
      'una vez terminado no vuelve a empezar con la misma instancia',
      () async {
        final b = crear();
        await b.controlador.iniciarSiCorresponde();
        await b.controlador.omitir();
        b.almacen.datos.clear();

        await b.controlador.iniciarSiCorresponde();

        expect(b.controlador.visible, isFalse);
      },
    );

    test('un recorrido sin pasos no se muestra', () async {
      final b = crear(pasos: const []);

      await b.controlador.iniciarSiCorresponde();

      expect(b.controlador.visible, isFalse);
    });
  });

  group('pasos', () {
    test('antes de comenzar cuenta los cinco pasos que señalan algo', () async {
      final b = crear();

      await b.controlador.iniciarSiCorresponde();

      expect(b.controlador.pasosActivos, hasLength(7));
      expect(b.controlador.totalPasos, 5);
    });

    test(
      'con todas las marcas son 5 pasos y empieza por el buscador',
      () async {
        final b = crear();

        await b.comenzar();

        final c = b.controlador;
        expect(b.idsActivos, [
          'bienvenida',
          'buscador',
          'filtros',
          'tarjeta',
          'verPerfil',
          'verificacion',
          'cierre',
        ]);
        expect(c.totalPasos, 5);
        expect(c.pasoActual?.id, 'buscador');
        expect(c.numeroDePaso, 1);
        expect(c.marcaPresente, isTrue);
        expect(c.preparando, isFalse);
        expect(c.puedeRetroceder, isFalse);
        expect(b.vista.preparados, [MarcaRecorridoId.buscador]);
      },
    );

    test('sin tarjetas son 3 pasos y la verificación va sin marca', () async {
      final b = crear(
        marcas: {MarcaRecorridoId.buscador, MarcaRecorridoId.filtros},
      );

      await b.comenzar();

      final c = b.controlador;
      expect(b.idsActivos, [
        'bienvenida',
        'buscador',
        'filtros',
        'verificacion',
        'cierre',
      ]);
      expect(c.totalPasos, 3);

      await c.siguiente();
      await c.siguiente();
      expect(c.pasoActual?.id, 'verificacion');
      expect(c.numeroDePaso, 3);
      expect(c.marcaPresente, isFalse);
      expect(b.vista.preparados, [
        MarcaRecorridoId.buscador,
        MarcaRecorridoId.filtros,
      ]);
      final paso = c.pasoActual!;
      expect(
        paso.descripcionPara(esMovil: false, conMarca: c.marcaPresente),
        paso.descripcionSinMarca,
      );
    });

    test('sin la marca de los filtros, ese paso se omite', () async {
      final b = crear(marcas: {MarcaRecorridoId.buscador});

      await b.comenzar();

      expect(b.idsActivos, [
        'bienvenida',
        'buscador',
        'verificacion',
        'cierre',
      ]);
      expect(b.controlador.totalPasos, 2);
    });

    test('«Ver perfil» se omite sin tarjeta aunque su marca exista', () async {
      final b = crear(
        marcas: {
          MarcaRecorridoId.buscador,
          MarcaRecorridoId.filtros,
          MarcaRecorridoId.verPerfil,
        },
      );

      await b.comenzar();

      expect(b.idsActivos, isNot(contains('verPerfil')));
      expect(b.idsActivos, isNot(contains('tarjeta')));
    });

    test(
      'espera a que terminen de cargarse los resultados antes de decidir',
      () async {
        final b = crear(
          marcas: {
            MarcaRecorridoId.buscador,
            MarcaRecorridoId.filtros,
            MarcaRecorridoId.cargandoResultados,
          },
          esperaResultados: const Duration(milliseconds: 100),
        );
        var consultas = 0;
        b.vista.alConsultar = (marca) {
          if (marca == MarcaRecorridoId.cargandoResultados &&
              ++consultas == 3) {
            // Llegan los abogados: se va el indicador y aparecen las tarjetas.
            b.vista.disponibles
              ..remove(marca)
              ..addAll({
                MarcaRecorridoId.tarjeta,
                MarcaRecorridoId.verPerfil,
                MarcaRecorridoId.insignia,
              });
          }
        };

        await b.comenzar();

        expect(consultas, 3);
        expect(b.controlador.totalPasos, 5);
        expect(b.idsActivos, contains('tarjeta'));
      },
    );

    test('si la carga no termina, sigue con lo que haya a la vista', () async {
      final b = crear(
        marcas: {
          MarcaRecorridoId.buscador,
          MarcaRecorridoId.filtros,
          MarcaRecorridoId.cargandoResultados,
        },
      );

      await b.comenzar();

      expect(b.controlador.totalPasos, 3);
      expect(b.controlador.pasoActual?.id, 'buscador');
      expect(b.controlador.preparando, isFalse);
    });

    test(
      'mientras espera los resultados sigue en la bienvenida, preparando',
      () async {
        final b = crear(
          marcas: {
            MarcaRecorridoId.buscador,
            MarcaRecorridoId.cargandoResultados,
          },
          esperaResultados: const Duration(milliseconds: 100),
        );
        await b.controlador.iniciarSiCorresponde();
        var consultas = 0;
        final enEspera = Completer<void>();
        b.vista.alConsultar = (marca) {
          if (marca != MarcaRecorridoId.cargandoResultados) return;
          consultas++;
          if (consultas == 3) {
            // En plena espera: todavía en la bienvenida y preparando.
            expect(b.controlador.pasoActual?.id, 'bienvenida');
            expect(b.controlador.preparando, isTrue);
            b.vista.disponibles.remove(marca);
            enEspera.complete();
          }
        };

        await b.controlador.comenzar();

        expect(enEspera.isCompleted, isTrue);
        expect(b.controlador.pasoActual?.id, 'buscador');
        expect(b.controlador.preparando, isFalse);
      },
    );

    test('recorre los pasos con su número y termina en el cierre', () async {
      final b = crear();
      await b.comenzar();
      final c = b.controlador;

      final ids = <String>[];
      final numeros = <int?>[];
      while (c.pasoActual!.tipo != TipoPasoRecorrido.cierre) {
        ids.add(c.pasoActual!.id);
        numeros.add(c.numeroDePaso);
        await c.siguiente();
      }

      expect(ids, [
        'buscador',
        'filtros',
        'tarjeta',
        'verPerfil',
        'verificacion',
      ]);
      expect(numeros, [1, 2, 3, 4, 5]);
      expect(c.pasoActual?.id, 'cierre');
      expect(c.numeroDePaso, isNull);
      expect(c.puedeRetroceder, isTrue);
      expect(b.vista.preparados, [
        MarcaRecorridoId.buscador,
        MarcaRecorridoId.filtros,
        MarcaRecorridoId.tarjeta,
        MarcaRecorridoId.verPerfil,
        MarcaRecorridoId.insignia,
      ]);
    });

    test('en el cierre «siguiente» no hace nada', () async {
      final b = crear();
      await b.comenzar();
      final c = b.controlador;
      while (c.pasoActual!.tipo != TipoPasoRecorrido.cierre) {
        await c.siguiente();
      }

      await c.siguiente();

      expect(c.visible, isTrue);
      expect(c.pasoActual?.id, 'cierre');
      expect(b.almacen.escrituras, isEmpty);
    });

    test(
      'retrocede paso a paso, sin pasar del primero ni volver a la bienvenida',
      () async {
        final b = crear();
        await b.comenzar();
        final c = b.controlador;
        while (c.pasoActual!.tipo != TipoPasoRecorrido.cierre) {
          await c.siguiente();
        }

        final ids = <String>[];
        while (c.puedeRetroceder) {
          await c.anterior();
          ids.add(c.pasoActual!.id);
        }

        expect(ids, [
          'verificacion',
          'verPerfil',
          'tarjeta',
          'filtros',
          'buscador',
        ]);
        expect(c.numeroDePaso, 1);
        expect(c.puedeRetroceder, isFalse);

        await c.anterior();
        expect(c.pasoActual?.id, 'buscador');
      },
    );

    test('desde la bienvenida no se puede retroceder', () async {
      final b = crear();
      await b.controlador.iniciarSiCorresponde();

      await b.controlador.anterior();

      expect(b.controlador.pasoActual?.id, 'bienvenida');
    });

    test('«siguiente» en la bienvenida equivale a comenzar', () async {
      final b = crear();
      await b.controlador.iniciarSiCorresponde();

      await b.controlador.siguiente();

      expect(b.controlador.pasoActual?.id, 'buscador');
    });

    test('comenzar fuera de la bienvenida no hace nada', () async {
      final b = crear();
      await b.comenzar();
      await b.controlador.siguiente();
      expect(b.controlador.pasoActual?.id, 'filtros');

      await b.controlador.comenzar();

      expect(b.controlador.pasoActual?.id, 'filtros');
    });

    test(
      'mientras se prepara un paso, siguiente y anterior se ignoran',
      () async {
        final b = crear();
        await b.controlador.iniciarSiCorresponde();
        final desplazamiento = Completer<void>();
        b.vista.retenerPreparacion = desplazamiento;
        final c = b.controlador;

        final comenzando = c.comenzar();
        await Future<void>.delayed(Duration.zero);
        expect(c.preparando, isTrue);
        expect(c.pasoActual?.id, 'buscador');

        await c.siguiente();
        await c.anterior();
        expect(c.pasoActual?.id, 'buscador');

        desplazamiento.complete();
        await comenzando;
        expect(c.preparando, isFalse);
        await c.siguiente();
        expect(c.pasoActual?.id, 'filtros');
      },
    );

    test('si no se puede desplazar, el paso se muestra igual', () async {
      final b = crear();
      await b.controlador.iniciarSiCorresponde();
      b.vista.fallarAlPreparar = StateError('sin desplazamiento');

      await b.controlador.comenzar();

      expect(b.controlador.pasoActual?.id, 'buscador');
      expect(b.controlador.preparando, isFalse);
    });

    test(
      'si la marca desaparece antes de llegar, el paso se muestra sin ella',
      () async {
        final b = crear();
        await b.comenzar();
        b.vista.disponibles.remove(MarcaRecorridoId.filtros);

        await b.controlador.siguiente();

        final c = b.controlador;
        expect(c.pasoActual?.id, 'filtros');
        expect(c.marcaPresente, isFalse);
        expect(c.preparando, isFalse);
        expect(b.vista.preparados, [MarcaRecorridoId.buscador]);
      },
    );

    test('«reprepararPasoActual» vuelve a pedir el desplazamiento', () async {
      final b = crear();
      await b.comenzar();
      b.vista.preparados.clear();
      var preparandoVisto = false;
      b.controlador.addListener(() {
        preparandoVisto = preparandoVisto || b.controlador.preparando;
      });

      await b.controlador.reprepararPasoActual();

      expect(b.vista.preparados, [MarcaRecorridoId.buscador]);
      expect(preparandoVisto, isTrue);
      expect(b.controlador.preparando, isFalse);
      expect(b.controlador.pasoActual?.id, 'buscador');
    });

    test('reprepararlo detecta una marca que apareció después', () async {
      final b = crear(
        marcas: {MarcaRecorridoId.buscador, MarcaRecorridoId.filtros},
      );
      await b.comenzar();
      await b.controlador.siguiente();
      await b.controlador.siguiente();
      final c = b.controlador;
      expect(c.pasoActual?.id, 'verificacion');
      expect(c.marcaPresente, isFalse);

      // Llegan los abogados mientras el cliente está en este paso.
      b.vista.disponibles.add(MarcaRecorridoId.insignia);
      await c.reprepararPasoActual();

      expect(c.marcaPresente, isTrue);
      expect(b.vista.preparados.last, MarcaRecorridoId.insignia);
    });

    test('reprepararlo en la bienvenida o el cierre no hace nada', () async {
      final b = crear();
      await b.controlador.iniciarSiCorresponde();

      await b.controlador.reprepararPasoActual();
      expect(b.vista.preparados, isEmpty);

      await b.controlador.comenzar();
      while (b.controlador.pasoActual!.tipo != TipoPasoRecorrido.cierre) {
        await b.controlador.siguiente();
      }
      b.vista.preparados.clear();
      await b.controlador.reprepararPasoActual();
      expect(b.vista.preparados, isEmpty);
    });

    test(
      'sin cierre en la lista, el último paso resaltado termina el recorrido',
      () async {
        final b = crear(
          pasos: ConfiguracionRecorridoCliente.pasos.sublist(0, 2),
        );
        await b.comenzar();
        expect(b.controlador.pasoActual?.id, 'buscador');

        await b.controlador.siguiente();

        expect(b.controlador.visible, isFalse);
        expect(b.almacen.datos[_claveUid1], 'completado');
      },
    );

    test('sin ningún paso resaltado va directo al cierre', () async {
      final pasos = ConfiguracionRecorridoCliente.pasos;
      final b = crear(pasos: [pasos.first, pasos.last]);

      await b.comenzar();

      expect(b.controlador.pasoActual?.id, 'cierre');
      expect(b.controlador.totalPasos, 0);
    });
  });

  group('terminar', () {
    test(
      'omitir lo recuerda como omitido y devuelve el desplazamiento',
      () async {
        final b = crear();
        await b.comenzar();

        await b.controlador.omitir();

        expect(b.controlador.visible, isFalse);
        expect(b.controlador.pasoActual, isNull);
        expect(b.vista.restauraciones, 1);
        expect(b.almacen.datos, {_claveUid1: 'omitido'});
      },
    );

    test('finalizar lo recuerda como completado', () async {
      final b = crear();
      await b.comenzar();

      await b.controlador.finalizar();

      expect(b.controlador.visible, isFalse);
      expect(b.vista.restauraciones, 1);
      expect(b.almacen.datos, {_claveUid1: 'completado'});
    });

    test('terminar dos veces solo guarda y restaura una vez', () async {
      final b = crear();
      await b.comenzar();

      await b.controlador.omitir();
      await b.controlador.omitir();
      await b.controlador.finalizar();

      expect(b.almacen.escrituras, hasLength(1));
      expect(b.vista.restauraciones, 1);
    });

    test(
      'cerrar desde la bienvenida o un paso intermedio cuenta como omitir',
      () async {
        final bienvenida = crear();
        await bienvenida.controlador.iniciarSiCorresponde();
        await bienvenida.controlador.cerrarPorUsuario();

        final intermedio = crear();
        await intermedio.comenzar();
        await intermedio.controlador.siguiente();
        await intermedio.controlador.cerrarPorUsuario();

        expect(bienvenida.almacen.datos[_claveUid1], 'omitido');
        expect(intermedio.almacen.datos[_claveUid1], 'omitido');
      },
    );

    test('cerrar en el último paso cuenta como terminar', () async {
      final b = crear();
      await b.comenzar();
      while (b.controlador.pasoActual!.tipo != TipoPasoRecorrido.cierre) {
        await b.controlador.siguiente();
      }

      await b.controlador.cerrarPorUsuario();

      expect(b.controlador.visible, isFalse);
      expect(b.almacen.datos[_claveUid1], 'completado');
    });

    test(
      'cerrar mientras espera los resultados también guarda omitido',
      () async {
        final b = crear(
          marcas: {
            MarcaRecorridoId.buscador,
            MarcaRecorridoId.cargandoResultados,
          },
          // Tras cerrar, la espera sigue sondeando hasta su límite: con un
          // límite corto la prueba termina enseguida.
          esperaResultados: const Duration(milliseconds: 20),
        );
        await b.controlador.iniciarSiCorresponde();
        var consultas = 0;
        b.vista.alConsultar = (marca) {
          if (marca == MarcaRecorridoId.cargandoResultados &&
              ++consultas == 3) {
            unawaited(b.controlador.cerrarPorUsuario());
          }
        };

        await b.controlador.comenzar();

        expect(b.controlador.visible, isFalse);
        expect(b.almacen.datos[_claveUid1], 'omitido');
        // No llegó a ningún paso: se cerró durante la espera.
        expect(b.vista.preparados, isEmpty);
      },
    );

    test('un fallo al guardar no rompe nada', () async {
      final b = crear();
      await b.comenzar();
      b.almacen.fallarEscritura = true;

      await b.controlador.omitir();

      expect(b.controlador.visible, isFalse);
      expect(b.vista.restauraciones, 1);
    });

    test('ocultar el recorrido no espera a un almacenamiento lento', () async {
      final b = crear();
      await b.comenzar();
      final lento = Completer<void>();
      b.almacen.retenerEscritura = lento;

      final guardando = b.controlador.omitir();

      expect(b.controlador.visible, isFalse);
      expect(b.almacen.escrituras, isEmpty);

      lento.complete();
      await guardando;
      expect(b.almacen.datos[_claveUid1], 'omitido');
    });

    test('desechar a mitad del recorrido no guarda nada', () async {
      final b = crear();
      await b.comenzar();
      await b.controlador.siguiente();

      b.desechar();
      await Future<void>.delayed(Duration.zero);

      expect(b.almacen.escrituras, isEmpty);
      expect(b.vista.restauraciones, 0);
    });

    test('desechar antes de terminar de leer no muestra nada', () async {
      final b = crear();

      final iniciando = b.controlador.iniciarSiCorresponde();
      b.desechar();
      await iniciando;

      expect(b.controlador.visible, isFalse);
      expect(b.vista.capturas, 0);
    });

    test('desechar mientras espera al buscador no muestra nada', () async {
      final b = crear(
        marcas: {},
        esperaBuscador: const Duration(milliseconds: 100),
      );

      final iniciando = b.controlador.iniciarSiCorresponde();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      b.desechar();
      await iniciando;

      expect(b.controlador.visible, isFalse);
      expect(b.vista.capturas, 0);
    });

    test('desechar mientras se prepara un paso no notifica ni lanza', () async {
      final b = crear();
      await b.controlador.iniciarSiCorresponde();
      final desplazamiento = Completer<void>();
      b.vista.retenerPreparacion = desplazamiento;
      final comenzando = b.controlador.comenzar();
      await Future<void>.delayed(Duration.zero);
      final antes = b.notificaciones;

      b.desechar();
      desplazamiento.complete();
      await comenzando;

      expect(b.notificaciones, antes);
    });
  });

  group('configuración de los pasos', () {
    final pasos = ConfiguracionRecorridoCliente.pasos;
    ModeloPasoRecorrido paso(String id) => pasos.firstWhere((p) => p.id == id);

    test('son siete, en este orden, con su tipo y su marca', () {
      expect(pasos.map((p) => (p.id, p.tipo, p.marca)).toList(), [
        ('bienvenida', TipoPasoRecorrido.bienvenida, null),
        ('buscador', TipoPasoRecorrido.resaltado, MarcaRecorridoId.buscador),
        ('filtros', TipoPasoRecorrido.resaltado, MarcaRecorridoId.filtros),
        ('tarjeta', TipoPasoRecorrido.resaltado, MarcaRecorridoId.tarjeta),
        ('verPerfil', TipoPasoRecorrido.resaltado, MarcaRecorridoId.verPerfil),
        (
          'verificacion',
          TipoPasoRecorrido.resaltado,
          MarcaRecorridoId.insignia,
        ),
        ('cierre', TipoPasoRecorrido.cierre, null),
      ]);
    });

    test('solo la verificación se muestra centrada cuando falta su marca', () {
      for (final p in pasos) {
        expect(
          p.siFaltaMarca,
          p.id == 'verificacion' ? SiFaltaMarca.centrar : SiFaltaMarca.omitir,
          reason: p.id,
        );
      }
    });

    test('los textos son los acordados', () {
      expect(paso('bienvenida').titulo, 'Bienvenido a ManoLegal');
      expect(
        paso('bienvenida').descripcion,
        'Te mostraremos rápidamente cómo encontrar y conocer abogados dentro de la plataforma.',
      );
      expect(paso('buscador').titulo, 'Busca abogados');
      expect(
        paso('buscador').descripcion,
        'Aquí puedes buscar abogados por nombre, especialidad o ubicación, según la necesidad legal que tengas.',
      );
      expect(paso('filtros').titulo, 'Filtra los resultados');
      expect(
        paso('filtros').descripcion,
        'Utiliza los filtros para encontrar opciones que se ajusten mejor a tu búsqueda: especialidad, ubicación, calificación mínima y solo abogados verificados.',
      );
      expect(
        paso('filtros').descripcionMovil,
        'Toca «Filtros» para elegir especialidad, ubicación, calificación mínima y si ver solo abogados verificados.',
      );
      expect(paso('tarjeta').titulo, 'Conoce a cada abogado');
      expect(
        paso('tarjeta').descripcion,
        'Aquí puedes consultar rápidamente la información principal de cada abogado: especialidad, calificación, ubicación y tarifa, si la publica.',
      );
      expect(paso('verPerfil').titulo, 'Ver perfil');
      expect(
        paso('verPerfil').descripcion,
        'Desde aquí puedes consultar el perfil completo del abogado.',
      );
      expect(paso('verificacion').titulo, 'Abogados verificados');
      expect(
        paso('verificacion').descripcion,
        'Los abogados que aparecen como verificados han pasado por el proceso de verificación administrado por ManoLegal. Es una revisión de sus documentos, no una recomendación.',
      );
      expect(
        paso('verificacion').descripcionSinMarca,
        'Los abogados que aparecen como verificados han pasado por el proceso de verificación administrado por ManoLegal. Los reconocerás por la insignia «Verificado» junto a su nombre en los resultados.',
      );
      expect(paso('cierre').titulo, 'Listo');
      expect(
        paso('cierre').descripcion,
        'Ya conoces las funciones principales para comenzar a utilizar ManoLegal.',
      );
    });

    test('los textos usan «tú», nunca voseo', () {
      const voseo = {
        'tenés',
        'querés',
        'podés',
        'sabés',
        'elegí',
        'buscá',
        'tocá',
        'mirá',
        'hacé',
        'usá',
        'vos',
      };
      for (final p in pasos) {
        final textos = [
          p.titulo,
          p.descripcion,
          ?p.descripcionMovil,
          ?p.descripcionSinMarca,
        ];
        for (final texto in textos) {
          final palabras = texto
              .toLowerCase()
              .split(RegExp(r'[^\wáéíóúüñ]+'))
              .toSet();
          expect(palabras.intersection(voseo), isEmpty, reason: texto);
        }
      }
    });

    test('«descripcionPara» elige el texto según el layout y la marca', () {
      final filtros = paso('filtros');
      expect(
        filtros.descripcionPara(esMovil: true, conMarca: true),
        filtros.descripcionMovil,
      );
      expect(
        filtros.descripcionPara(esMovil: false, conMarca: true),
        filtros.descripcion,
      );

      final verificacion = paso('verificacion');
      expect(
        verificacion.descripcionPara(esMovil: true, conMarca: false),
        verificacion.descripcionSinMarca,
      );
      expect(
        verificacion.descripcionPara(esMovil: false, conMarca: false),
        verificacion.descripcionSinMarca,
      );
      expect(
        verificacion.descripcionPara(esMovil: true, conMarca: true),
        verificacion.descripcion,
      );

      final buscador = paso('buscador');
      expect(
        buscador.descripcionPara(esMovil: true, conMarca: false),
        buscador.descripcion,
      );
    });

    test('las esperas por defecto son de 8 s, 5 s y 150 ms', () {
      expect(
        ConfiguracionRecorridoCliente.esperaBuscador,
        const Duration(seconds: 8),
      );
      expect(
        ConfiguracionRecorridoCliente.esperaResultados,
        const Duration(seconds: 5),
      );
      expect(
        ConfiguracionRecorridoCliente.intervaloSondeo,
        const Duration(milliseconds: 150),
      );
    });
  });
}
