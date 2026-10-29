import 'dart:io';

import 'package:desarrollo/configuracion/configuracion_recorrido_abogado.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_pqrs.dart';
import 'package:desarrollo/controlador/almacen_local.dart';
import 'package:desarrollo/controlador/servicio_estado_recorrido.dart';
import 'package:desarrollo/modelo/modelo_estado_recorrido.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_recorrido.dart';

void main() {
  group('prefijo de la clave', () {
    test('por defecto conserva la clave del recorrido de Inicio del cliente', () async {
      final almacen = AlmacenMemoria();
      final servicio = ServicioEstadoRecorridoLocal(almacen: almacen);

      await servicio.guardar('uid-1', EstadoRecorrido.omitido);

      expect(servicio.prefijoClave, 'manolegal.recorrido.cliente.v1.');
      expect(almacen.datos, {'manolegal.recorrido.cliente.v1.uid-1': 'omitido'});
    });

    test('dos prefijos sobre el mismo almacén no se pisan', () async {
      final almacen = AlmacenMemoria();
      final inicio = ServicioEstadoRecorridoLocal(almacen: almacen);
      final pqrs = ServicioEstadoRecorridoLocal(
        almacen: almacen,
        prefijoClave: ConfiguracionRecorridoPqrs.pqrs.prefijoClave,
      );

      await inicio.guardar('uid-1', EstadoRecorrido.completado);

      expect(await inicio.leer('uid-1'), EstadoRecorrido.completado);
      expect(await pqrs.leer('uid-1'), EstadoRecorrido.noVisto);

      await pqrs.guardar('uid-1', EstadoRecorrido.omitido);
      await inicio.reiniciar('uid-1');

      expect(await inicio.leer('uid-1'), EstadoRecorrido.noVisto);
      expect(await pqrs.leer('uid-1'), EstadoRecorrido.omitido);
    });

    test('cada recorrido tiene una clave distinta con la forma acordada', () {
      final recorridos = [
        ConfiguracionRecorridoCliente.inicio,
        ConfiguracionRecorridoCliente.comoFunciona,
        ConfiguracionRecorridoCliente.lexus,
        ConfiguracionRecorridoPqrs.pqrs,
        ConfiguracionRecorridoAbogado.inicio,
        ConfiguracionRecorridoAbogado.miPerfil,
        ConfiguracionRecorridoAbogado.panel,
      ];

      expect(
        recorridos.map((r) => r.prefijoClave).toSet(),
        hasLength(recorridos.length),
      );
      expect(recorridos.map((r) => r.id).toSet(), hasLength(recorridos.length));
      expect(
        ConfiguracionRecorridoCliente.inicio.prefijoClave,
        ConfiguracionRecorridoCliente.prefijoClave,
      );
      for (final r in recorridos.skip(1)) {
        expect(r.prefijoClave, 'manolegal.recorrido.${r.id}.v1.', reason: r.id);
      }
    });
  });

  group('almacén en archivo compartido', () {
    late Directory directorio;

    setUp(() {
      directorio = Directory.systemTemp.createTempSync('recorridos_prefijos_');
    });

    tearDown(() {
      if (directorio.existsSync()) directorio.deleteSync(recursive: true);
    });

    test('dos servicios sobre el mismo archivo guardan los dos', () async {
      final almacen = AlmacenLocalArchivo(directorio: () async => directorio);
      final lexus = ServicioEstadoRecorridoLocal(
        almacen: almacen,
        prefijoClave: ConfiguracionRecorridoCliente.lexus.prefijoClave,
      );
      final pqrs = ServicioEstadoRecorridoLocal(
        almacen: almacen,
        prefijoClave: ConfiguracionRecorridoPqrs.pqrs.prefijoClave,
      );

      // A la vez, como dos recorridos que terminan casi juntos.
      await Future.wait([
        lexus.guardar('uid-1', EstadoRecorrido.completado),
        pqrs.guardar('uid-1', EstadoRecorrido.omitido),
      ]);

      final relectura = AlmacenLocalArchivo(directorio: () async => directorio);
      expect(
        await relectura.leer('${ConfiguracionRecorridoCliente.lexus.prefijoClave}uid-1'),
        'completado',
      );
      expect(
        await relectura.leer('${ConfiguracionRecorridoPqrs.pqrs.prefijoClave}uid-1'),
        'omitido',
      );
    });

    test('crearAlmacenLocal devuelve siempre la misma instancia', () {
      expect(identical(crearAlmacenLocal(), crearAlmacenLocal()), isTrue);
    });
  });
}
