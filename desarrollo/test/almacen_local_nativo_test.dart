import 'dart:convert';
import 'dart:io';

import 'package:desarrollo/controlador/almacen_local_nativo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directorio;

  setUp(() {
    directorio = Directory.systemTemp.createTempSync('almacen_local_prueba_');
  });

  tearDown(() {
    if (directorio.existsSync()) directorio.deleteSync(recursive: true);
  });

  /// Siempre sobre la carpeta temporal: `getApplicationSupportDirectory`
  /// necesita el plugin de la plataforma, que no existe en las pruebas.
  AlmacenLocalArchivo crear() {
    return AlmacenLocalArchivo(directorio: () async => directorio);
  }

  File archivo() {
    return File(
      '${directorio.path}${Platform.pathSeparator}${AlmacenLocalArchivo.nombreArchivo}',
    );
  }

  test('sin archivo no hay nada guardado y leer no lo crea', () async {
    final almacen = crear();

    expect(await almacen.leer('clave'), isNull);
    expect(archivo().existsSync(), isFalse);
  });

  test('lo que se escribe se puede leer', () async {
    final almacen = crear();

    await almacen.escribir('clave', 'valor');

    expect(await almacen.leer('clave'), 'valor');
  });

  test('se guarda como un único JSON con todos los pares', () async {
    final almacen = crear();

    await almacen.escribir('a', '1');
    await almacen.escribir('b', '2');

    expect(jsonDecode(archivo().readAsStringSync()), {'a': '1', 'b': '2'});
  });

  test('otra instancia sobre la misma carpeta ve lo ya guardado', () async {
    await crear().escribir('clave', 'valor');

    expect(await crear().leer('clave'), 'valor');
  });

  test('escribir una clave existente la reemplaza', () async {
    final almacen = crear();

    await almacen.escribir('clave', 'uno');
    await almacen.escribir('clave', 'dos');

    expect(await almacen.leer('clave'), 'dos');
  });

  test('borrar quita solo esa clave', () async {
    final almacen = crear();
    await almacen.escribir('a', '1');
    await almacen.escribir('b', '2');

    await almacen.borrar('a');

    expect(await almacen.leer('a'), isNull);
    expect(await almacen.leer('b'), '2');
  });

  test('borrar una clave inexistente no falla ni crea el archivo', () async {
    final almacen = crear();

    await almacen.borrar('no-existe');

    expect(archivo().existsSync(), isFalse);
  });

  test('no deja el archivo temporal de la escritura', () async {
    await crear().escribir('clave', 'valor');

    expect(File('${archivo().path}.tmp').existsSync(), isFalse);
  });

  test('crea la carpeta si todavía no existe', () async {
    final anidada = Directory(
      '${directorio.path}${Platform.pathSeparator}a${Platform.pathSeparator}b',
    );
    final almacen = AlmacenLocalArchivo(directorio: () async => anidada);

    await almacen.escribir('clave', 'valor');

    expect(await almacen.leer('clave'), 'valor');
  });

  group('archivo ilegible', () {
    test('un JSON corrupto cuenta como vacío', () async {
      archivo().writeAsStringSync('esto { no es JSON');

      expect(await crear().leer('clave'), isNull);
    });

    test('un archivo vacío cuenta como vacío', () async {
      archivo().writeAsStringSync('');

      expect(await crear().leer('clave'), isNull);
    });

    test('un JSON que no es un mapa cuenta como vacío', () async {
      archivo().writeAsStringSync('[1, 2, 3]');

      expect(await crear().leer('clave'), isNull);
    });

    test('los valores que no son texto se ignoran', () async {
      archivo().writeAsStringSync('{"numero": 1, "texto": "hola"}');
      final almacen = crear();

      expect(await almacen.leer('numero'), isNull);
      expect(await almacen.leer('texto'), 'hola');
    });

    test('escribir sobre un archivo corrupto lo repara', () async {
      archivo().writeAsStringSync('esto { no es JSON');
      final almacen = crear();

      await almacen.escribir('clave', 'valor');

      expect(await almacen.leer('clave'), 'valor');
      expect(jsonDecode(archivo().readAsStringSync()), {'clave': 'valor'});
    });
  });

  group('operaciones simultáneas', () {
    test('veinte escrituras a la vez no se pisan entre sí', () async {
      final almacen = crear();

      await Future.wait([
        for (var i = 0; i < 20; i++) almacen.escribir('clave$i', 'valor$i'),
      ]);

      final otra = crear();
      for (var i = 0; i < 20; i++) {
        expect(await otra.leer('clave$i'), 'valor$i', reason: 'clave$i');
      }
    });

    test('una lectura pedida después de una escritura la ve', () async {
      final almacen = crear();

      final escritura = almacen.escribir('clave', 'valor');
      final lectura = almacen.leer('clave');
      await escritura;

      expect(await lectura, 'valor');
    });

    test('una escritura y un borrado se aplican en el orden pedido', () async {
      final almacen = crear();

      final escritura = almacen.escribir('clave', 'valor');
      final borrado = almacen.borrar('clave');
      await Future.wait([escritura, borrado]);

      expect(await almacen.leer('clave'), isNull);
    });
  });

  group('fallos del directorio', () {
    test('leer propaga el fallo: no se confunde con «sin datos»', () {
      final almacen = AlmacenLocalArchivo(
        directorio: () async => throw const FileSystemException('sin acceso'),
      );

      expect(almacen.leer('clave'), throwsA(isA<FileSystemException>()));
    });

    test('escribir y borrar no lanzan: son de mejor esfuerzo', () async {
      final almacen = AlmacenLocalArchivo(
        directorio: () async => throw const FileSystemException('sin acceso'),
      );

      await almacen.escribir('clave', 'valor');
      await almacen.borrar('clave');
    });

    test('un fallo no deja la cola bloqueada para lo siguiente', () async {
      var llamadas = 0;
      final almacen = AlmacenLocalArchivo(
        directorio: () async {
          if (llamadas++ == 0) throw const FileSystemException('sin acceso');
          return directorio;
        },
      );

      await expectLater(
        almacen.leer('clave'),
        throwsA(isA<FileSystemException>()),
      );
      await almacen.escribir('clave', 'valor');

      expect(await almacen.leer('clave'), 'valor');
    });
  });
}
