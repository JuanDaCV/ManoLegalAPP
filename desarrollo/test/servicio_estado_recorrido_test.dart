import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/controlador/servicio_estado_recorrido.dart';
import 'package:desarrollo/modelo/modelo_estado_recorrido.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_recorrido.dart';

void main() {
  group('EstadoRecorrido', () {
    test('un valor ausente o desconocido se lee como no visto', () {
      expect(EstadoRecorrido.desdeTexto(null), EstadoRecorrido.noVisto);
      expect(EstadoRecorrido.desdeTexto(''), EstadoRecorrido.noVisto);
      expect(EstadoRecorrido.desdeTexto('algo raro'), EstadoRecorrido.noVisto);
      expect(EstadoRecorrido.desdeTexto('Completado'), EstadoRecorrido.noVisto);
      expect(EstadoRecorrido.desdeTexto('noVisto'), EstadoRecorrido.noVisto);
    });

    test('completado y omitido se reconocen por su texto', () {
      expect(
        EstadoRecorrido.desdeTexto('completado'),
        EstadoRecorrido.completado,
      );
      expect(EstadoRecorrido.desdeTexto('omitido'), EstadoRecorrido.omitido);
    });

    test('solo completado y omitido tienen texto que guardar', () {
      expect(EstadoRecorrido.noVisto.comoTexto, isNull);
      expect(EstadoRecorrido.completado.comoTexto, 'completado');
      expect(EstadoRecorrido.omitido.comoTexto, 'omitido');
    });

    test('el texto guardado vuelve al mismo estado', () {
      for (final estado in EstadoRecorrido.values) {
        expect(EstadoRecorrido.desdeTexto(estado.comoTexto), estado);
      }
    });
  });

  group('ServicioEstadoRecorridoLocal', () {
    // Si esta clave cambia, el recorrido vuelve a aparecer a todos los
    // clientes que ya lo vieron.
    const prefijo = 'manolegal.recorrido.cliente.v1.';

    late AlmacenMemoria almacen;
    late ServicioEstadoRecorridoLocal servicio;

    setUp(() {
      almacen = AlmacenMemoria();
      servicio = ServicioEstadoRecorridoLocal(almacen: almacen);
    });

    test('la clave lleva el prefijo de la versión y el uid', () async {
      expect(ConfiguracionRecorridoCliente.prefijoClave, prefijo);

      await servicio.guardar('uid-a', EstadoRecorrido.completado);

      expect(almacen.datos, {'${prefijo}uid-a': 'completado'});
    });

    test('sin nada guardado, el estado es no visto', () async {
      expect(await servicio.leer('uid-a'), EstadoRecorrido.noVisto);
    });

    test('guardar y leer devuelve el mismo estado', () async {
      await servicio.guardar('uid-a', EstadoRecorrido.completado);
      expect(await servicio.leer('uid-a'), EstadoRecorrido.completado);

      await servicio.guardar('uid-a', EstadoRecorrido.omitido);
      expect(await servicio.leer('uid-a'), EstadoRecorrido.omitido);
    });

    test('cada usuario tiene su propio estado', () async {
      await servicio.guardar('uid-a', EstadoRecorrido.completado);

      expect(await servicio.leer('uid-a'), EstadoRecorrido.completado);
      expect(await servicio.leer('uid-b'), EstadoRecorrido.noVisto);
    });

    test('un valor desconocido en el almacén se lee como no visto', () async {
      almacen.datos['${prefijo}uid-a'] = 'valor de otra versión';

      expect(await servicio.leer('uid-a'), EstadoRecorrido.noVisto);
    });

    test('reiniciar olvida solo al usuario indicado', () async {
      await servicio.guardar('uid-a', EstadoRecorrido.completado);
      await servicio.guardar('uid-b', EstadoRecorrido.omitido);

      await servicio.reiniciar('uid-a');

      expect(await servicio.leer('uid-a'), EstadoRecorrido.noVisto);
      expect(await servicio.leer('uid-b'), EstadoRecorrido.omitido);
    });

    test('guardar «no visto» equivale a reiniciar', () async {
      await servicio.guardar('uid-a', EstadoRecorrido.completado);

      await servicio.guardar('uid-a', EstadoRecorrido.noVisto);

      expect(almacen.datos, isEmpty);
      expect(await servicio.leer('uid-a'), EstadoRecorrido.noVisto);
    });

    test('un error de lectura se propaga: no se confunde con «no visto»', () {
      almacen.fallarLectura = true;

      expect(servicio.leer('uid-a'), throwsStateError);
    });

    test('un error de escritura se propaga a quien guarda', () {
      almacen.fallarEscritura = true;

      expect(
        servicio.guardar('uid-a', EstadoRecorrido.omitido),
        throwsStateError,
      );
    });
  });
}
