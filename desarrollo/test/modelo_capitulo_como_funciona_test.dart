import 'dart:io';

import 'package:desarrollo/modelo/modelo_capitulo_como_funciona.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Los seis videos y sus portadas son archivos reales. Estas pruebas leen sus
// cabeceras (nunca el archivo completo) para comprobar que cada ficha del
// modelo corresponde al archivo que dice: la duración y el tamaño salen del
// propio MP4, así que un capítulo con el video cambiado de lugar falla aquí.
// =============================================================================

/// Lo que importa de un MP4: el orden de sus cajas de primer nivel, su
/// duración y el tamaño de su pista de video.
class _InfoMp4 {
  final List<String> cajas;
  final double segundos;
  final int ancho;
  final int alto;

  const _InfoMp4(this.cajas, this.segundos, this.ancho, this.alto);
}

/// Una caja del formato ISO BMFF: tipo y rango de su contenido.
class _Caja {
  final String tipo;
  final int inicio;
  final int fin;

  const _Caja(this.tipo, this.inicio, this.fin);
}

List<_Caja> _cajasEn(Uint8List datos, [int desde = 0, int? hasta]) {
  final limite = hasta ?? datos.length;
  final vista = ByteData.sublistView(datos);
  final cajas = <_Caja>[];
  var posicion = desde;
  while (posicion + 8 <= limite) {
    var tamano = vista.getUint32(posicion);
    final tipo = String.fromCharCodes(datos.sublist(posicion + 4, posicion + 8));
    var cabecera = 8;
    if (tamano == 1) {
      tamano = vista.getUint64(posicion + 8);
      cabecera = 16;
    } else if (tamano == 0) {
      tamano = limite - posicion;
    }
    if (tamano < cabecera) break;
    cajas.add(_Caja(tipo, posicion + cabecera, posicion + tamano));
    posicion += tamano;
  }
  return cajas;
}

_InfoMp4 _leerMp4(String ruta) {
  final archivo = File(ruta).openSync();
  try {
    final total = archivo.lengthSync();
    final orden = <String>[];
    Uint8List? moov;
    var posicion = 0;
    // Solo se leen las cabeceras de las cajas de primer nivel y el contenido
    // de `moov`: `mdat` (el video en sí) se salta sin leerlo.
    while (posicion + 8 <= total) {
      archivo.setPositionSync(posicion);
      final cabecera = Uint8List.fromList(archivo.readSync(16));
      final vista = ByteData.sublistView(cabecera);
      var tamano = vista.getUint32(0);
      final tipo = String.fromCharCodes(cabecera.sublist(4, 8));
      var largoCabecera = 8;
      if (tamano == 1) {
        tamano = vista.getUint64(8);
        largoCabecera = 16;
      } else if (tamano == 0) {
        tamano = total - posicion;
      }
      orden.add(tipo);
      if (tipo == 'moov') {
        archivo.setPositionSync(posicion + largoCabecera);
        moov = Uint8List.fromList(archivo.readSync(tamano - largoCabecera));
      }
      posicion += tamano;
    }
    if (moov == null) throw StateError('$ruta no tiene caja moov');

    final vista = ByteData.sublistView(moov);
    double? segundos;
    int? ancho;
    int? alto;
    for (final caja in _cajasEn(moov)) {
      if (caja.tipo == 'mvhd') {
        final version = moov[caja.inicio];
        final base = caja.inicio + 4;
        if (version == 1) {
          final escala = vista.getUint32(base + 16);
          segundos = vista.getUint64(base + 20) / escala;
        } else {
          final escala = vista.getUint32(base + 8);
          segundos = vista.getUint32(base + 12) / escala;
        }
      } else if (caja.tipo == 'trak') {
        for (final hija in _cajasEn(moov, caja.inicio, caja.fin)) {
          if (hija.tipo != 'tkhd') continue;
          final base = hija.inicio;
          final desplazamiento = moov[base] == 1 ? 88 : 76;
          // Ancho y alto vienen en punto fijo 16.16. La pista de audio los
          // trae en cero: solo la de video cuenta.
          final anchoPista = vista.getUint32(base + desplazamiento) >> 16;
          final altoPista = vista.getUint32(base + desplazamiento + 4) >> 16;
          if (anchoPista > 0 && altoPista > 0) {
            ancho = anchoPista;
            alto = altoPista;
          }
        }
      }
    }
    return _InfoMp4(orden, segundos!, ancho!, alto!);
  } finally {
    archivo.closeSync();
  }
}

/// Tamaño de un JPEG leído de su marcador SOF.
({int ancho, int alto}) _tamanoJpeg(Uint8List bytes) {
  var i = 2;
  while (i + 9 < bytes.length) {
    if (bytes[i] != 0xFF) {
      i++;
      continue;
    }
    final marcador = bytes[i + 1];
    if (marcador == 0xFF) {
      i++;
      continue;
    }
    final esSof = marcador >= 0xC0 && marcador <= 0xCF && marcador != 0xC4 && marcador != 0xC8 && marcador != 0xCC;
    if (esSof) {
      return (ancho: (bytes[i + 7] << 8) | bytes[i + 8], alto: (bytes[i + 5] << 8) | bytes[i + 6]);
    }
    final largo = (bytes[i + 2] << 8) | bytes[i + 3];
    i += 2 + largo;
  }
  throw StateError('JPEG sin marcador SOF');
}

ModeloCapituloComoFunciona _conDuracion(Duration duracion) {
  return ModeloCapituloComoFunciona(
    numero: 1,
    titulo: 'Prueba',
    descripcion: '',
    temas: const [],
    rutaVideo: '',
    rutaPortada: '',
    duracion: duracion,
    anchoPx: 1920,
    altoPx: 1080,
  );
}

void main() {
  const titulos = [
    '¿Qué es ManoLegal?',
    '¿Cómo encontrar un abogado?',
    '¿Cómo funciona la selección?',
    '¿Qué significa que un abogado esté verificado?',
    '¿Cómo funciona el contacto?',
    '¿Qué debe tener en cuenta un cliente?',
  ];

  group('ficha de los capítulos', () {
    test('son seis, numerados del 1 al 6 y con los títulos exactos en orden', () {
      expect(capitulosComoFunciona, hasLength(6));
      expect(capitulosComoFunciona.map((c) => c.numero), [1, 2, 3, 4, 5, 6]);
      expect(capitulosComoFunciona.map((c) => c.titulo), titulos);
    });

    test('cada capítulo trae tres temas y una descripción', () {
      for (final capitulo in capitulosComoFunciona) {
        expect(capitulo.temas, hasLength(3), reason: capitulo.titulo);
        expect(capitulo.descripcion.trim(), isNotEmpty, reason: capitulo.titulo);
      }
    });

    test('las rutas son únicas y siguen el patrón video_0N_…', () {
      final videos = capitulosComoFunciona.map((c) => c.rutaVideo).toSet();
      final portadas = capitulosComoFunciona.map((c) => c.rutaPortada).toSet();
      expect(videos, hasLength(6));
      expect(portadas, hasLength(6));

      for (final capitulo in capitulosComoFunciona) {
        final nombre = RegExp('^video/como_funciona/(video_0${capitulo.numero}_[a-z0-9_]+)\\.mp4\$');
        final coincidencia = nombre.firstMatch(capitulo.rutaVideo);
        expect(coincidencia, isNotNull, reason: capitulo.rutaVideo);
        // La portada lleva el mismo nombre base que su video.
        expect(capitulo.rutaPortada, 'video/como_funciona/portadas/${coincidencia!.group(1)}.jpg');
      }
    });

    test('solo el capítulo 2 es vertical', () {
      expect(capitulosComoFunciona.where((c) => c.esVertical).map((c) => c.numero), [2]);
      expect(capitulosComoFunciona[0].proporcion, closeTo(16 / 9, 0.001));
      expect(capitulosComoFunciona[1].proporcion, closeTo(9 / 16, 0.001));
    });

    test('la duración total ronda los cinco minutos', () {
      expect(duracionTotalComoFunciona, const Duration(milliseconds: 311440));
    });
  });

  group('textos derivados', () {
    test('numeroTexto lleva siempre dos cifras', () {
      expect(capitulosComoFunciona.map((c) => c.numeroTexto), ['01', '02', '03', '04', '05', '06']);
    });

    test('duracionTexto redondea al segundo más cercano', () {
      expect(capitulosComoFunciona.map((c) => c.duracionTexto), ['0:25', '0:50', '0:48', '0:53', '1:03', '1:13']);
      expect(_conDuracion(const Duration(milliseconds: 59600)).duracionTexto, '1:00');
      expect(_conDuracion(const Duration(milliseconds: 9400)).duracionTexto, '0:09');
    });

    test('duracionHablada dice minutos y segundos con palabras', () {
      expect(capitulosComoFunciona.map((c) => c.duracionHablada), [
        '25 segundos',
        '50 segundos',
        '48 segundos',
        '53 segundos',
        '1 minuto y 3 segundos',
        '1 minuto y 13 segundos',
      ]);
    });

    test('duracionHablada respeta el singular', () {
      expect(_conDuracion(const Duration(seconds: 1)).duracionHablada, '1 segundo');
      expect(_conDuracion(const Duration(seconds: 60)).duracionHablada, '1 minuto');
      expect(_conDuracion(const Duration(seconds: 61)).duracionHablada, '1 minuto y 1 segundo');
      expect(_conDuracion(const Duration(seconds: 120)).duracionHablada, '2 minutos');
      expect(_conDuracion(const Duration(seconds: 125)).duracionHablada, '2 minutos y 5 segundos');
    });

    test('etiquetaReproducir incluye el título y la duración', () {
      expect(
        capitulosComoFunciona[2].etiquetaReproducir,
        'Reproducir video: ¿Cómo funciona la selección?. Duración: 48 segundos.',
      );
      expect(
        capitulosComoFunciona[4].etiquetaReproducir,
        'Reproducir video: ¿Cómo funciona el contacto?. Duración: 1 minuto y 3 segundos.',
      );
    });
  });

  group('archivos reales', () {
    test('cada video y cada portada existen en disco', () {
      for (final capitulo in capitulosComoFunciona) {
        expect(File(capitulo.rutaVideo).existsSync(), isTrue, reason: capitulo.rutaVideo);
        expect(File(capitulo.rutaPortada).existsSync(), isTrue, reason: capitulo.rutaPortada);
      }
    });

    test('el MP4 es "faststart" y su duración y tamaño coinciden con la ficha', () {
      for (final capitulo in capitulosComoFunciona) {
        final info = _leerMp4(capitulo.rutaVideo);
        expect(
          info.cajas.indexOf('moov'),
          lessThan(info.cajas.indexOf('mdat')),
          reason: '${capitulo.rutaVideo}: moov va antes de mdat',
        );
        expect(info.segundos, closeTo(capitulo.duracion.inMilliseconds / 1000, 0.5), reason: capitulo.rutaVideo);
        // Si dos videos estuvieran cambiados de capítulo, el tamaño no coincidiría.
        expect((info.ancho, info.alto), (capitulo.anchoPx, capitulo.altoPx), reason: capitulo.rutaVideo);
      }
    });

    test('cada portada es un JPEG del tamaño del video', () {
      for (final capitulo in capitulosComoFunciona) {
        final bytes = File(capitulo.rutaPortada).readAsBytesSync();
        expect(bytes.sublist(0, 2), [0xFF, 0xD8], reason: '${capitulo.rutaPortada} debe empezar con la firma JPEG');
        final tamano = _tamanoJpeg(bytes);
        expect((tamano.ancho, tamano.alto), (capitulo.anchoPx, capitulo.altoPx), reason: capitulo.rutaPortada);
      }
    });

    test('pubspec declara los doce archivos, y el video pesado no', () {
      final lineas = File('pubspec.yaml').readAsLinesSync();
      // Solo las líneas de la lista de assets, sin comentarios.
      final declarados = [
        for (final linea in lineas)
          if (RegExp(r'^\s+-\s+(video/\S+|img/\S+)').firstMatch(linea) case final coincidencia?) coincidencia.group(1)!,
      ];
      for (final capitulo in capitulosComoFunciona) {
        expect(declarados, contains(capitulo.rutaVideo));
        expect(declarados, contains(capitulo.rutaPortada));
      }
      expect(declarados, isNot(contains('video/01-QueEsManoLegal.mp4')));
      expect(declarados.where((ruta) => ruta.startsWith('video/como_funciona/')), hasLength(12));
    });

    testWidgets('el paquete de assets lista los doce archivos y no el video pesado', (tester) async {
      final manifiesto = await tester.runAsync(() => AssetManifest.loadFromAssetBundle(rootBundle));
      final assets = manifiesto!.listAssets();
      for (final capitulo in capitulosComoFunciona) {
        expect(assets, contains(capitulo.rutaVideo));
        expect(assets, contains(capitulo.rutaPortada));
      }
      expect(assets, isNot(contains('video/01-QueEsManoLegal.mp4')));
    });
  });

  group('redacción', () {
    // Español neutro con "tú": ninguna forma del voseo rioplatense.
    const voseo = [
      'podés',
      'revisá',
      'tenés',
      'querés',
      'elegí',
      'mirá',
      'hacé',
      'ingresá',
      'abrí',
      'desplazate',
      'fijate',
      'contactá',
      'buscá',
      'usá',
      'guardá',
      'tocá',
      'presioná',
      'seleccioná',
      'escribí',
      'volvé',
      'pedí',
      'sabés',
    ];
    final patronVoseo = RegExp('(?<!\\p{L})(${voseo.join('|')})(?!\\p{L})', caseSensitive: false, unicode: true);
    final patronProhibido = RegExp('en desarrollo|próximamente', caseSensitive: false);

    List<String> textosDelModelo() => [
      for (final capitulo in capitulosComoFunciona) ...[
        capitulo.titulo,
        capitulo.descripcion,
        ...capitulo.temas,
        capitulo.etiquetaReproducir,
      ],
    ];

    List<File> archivosFuente() => [
      ...Directory('lib/vista/cliente/widgets/como_funciona')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('lib/vista/cliente/seccion_como_funciona.dart'),
      File('lib/modelo/modelo_capitulo_como_funciona.dart'),
      File('lib/controlador/controlador_como_funciona.dart'),
      File('lib/controlador/servicio_pantalla.dart'),
    ];

    test('el patrón detecta el voseo (la prueba no es vacía)', () {
      expect(patronVoseo.hasMatch('Revisá el perfil'), isTrue);
      expect(patronVoseo.hasMatch('Ya podés escribirle'), isTrue);
      expect(patronVoseo.hasMatch('Revisa el perfil y usa PQRS'), isFalse);
      expect(patronVoseo.hasMatch('Elegir un abogado'), isFalse);
    });

    test('los textos del modelo no usan voseo ni anuncian funciones pendientes', () {
      for (final texto in textosDelModelo()) {
        expect(patronVoseo.hasMatch(texto), isFalse, reason: texto);
        expect(patronProhibido.hasMatch(texto), isFalse, reason: texto);
      }
    });

    test('el código de la sección no usa voseo ni anuncia funciones pendientes', () {
      final archivos = archivosFuente();
      expect(archivos.length, greaterThan(10));
      for (final archivo in archivos) {
        final codigo = archivo.readAsStringSync();
        expect(patronVoseo.firstMatch(codigo)?.group(0), isNull, reason: archivo.path);
        expect(patronProhibido.firstMatch(codigo)?.group(0), isNull, reason: archivo.path);
      }
    });
  });
}
