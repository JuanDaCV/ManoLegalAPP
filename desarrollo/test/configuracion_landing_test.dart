import 'package:desarrollo/configuracion/configuracion_landing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'los enlaces oficiales son https válidos y el correo sigue sin publicar',
    () {
      for (final url in [
        ConfiguracionLanding.descargaGoogleDrive,
        ConfiguracionLanding.descargaMediaFire,
        ConfiguracionLanding.descargaMega,
        ConfiguracionLanding.instagram,
        ConfiguracionLanding.facebook,
        ConfiguracionLanding.tiktok,
        ConfiguracionLanding.x,
      ]) {
        expect(ConfiguracionLanding.esUrlValida(url), isTrue, reason: url);
      }
      expect(ConfiguracionLanding.correoContacto, isNull);
    },
  );

  group('esUrlValida', () {
    test('rechaza nulos, vacíos y esquemas distintos de https', () {
      expect(ConfiguracionLanding.esUrlValida(null), isFalse);
      expect(ConfiguracionLanding.esUrlValida(''), isFalse);
      expect(ConfiguracionLanding.esUrlValida('   '), isFalse);
      expect(ConfiguracionLanding.esUrlValida('http://x.com'), isFalse);
      expect(ConfiguracionLanding.esUrlValida('ftp://x'), isFalse);
      expect(ConfiguracionLanding.esUrlValida('javascript:alert(1)'), isFalse);
      expect(ConfiguracionLanding.esUrlValida('https://'), isFalse);
    });

    test('acepta https con host', () {
      expect(
        ConfiguracionLanding.esUrlValida('https://drive.google.com/abc'),
        isTrue,
      );
    });
  });

  group('opcionesDescarga', () {
    test('devuelve Drive, MediaFire y MEGA, todas disponibles', () {
      final opciones = ConfiguracionLanding.opcionesDescarga();
      expect(opciones.map((o) => o.tipo), [
        TipoEnlace.googleDrive,
        TipoEnlace.mediaFire,
        TipoEnlace.mega,
      ]);
      expect(opciones.map((o) => o.nombre), [
        'Google Drive',
        'MediaFire',
        'MEGA',
      ]);
      expect(opciones.every((o) => o.disponible), isTrue);
    });

    test(
      'solo una URL https válida queda disponible; null queda pendiente',
      () {
        final opciones = ConfiguracionLanding.opcionesDescarga(
          googleDrive: 'https://drive.google.com/abc',
          mediaFire: 'http://inseguro.com',
          mega: null,
        );
        expect(opciones.map((o) => o.disponible), [true, false, false]);
      },
    );
  });

  test('redesSociales devuelve Instagram, Facebook, TikTok y X', () {
    final redes = ConfiguracionLanding.redesSociales();
    expect(redes.map((r) => r.nombre), [
      'Instagram',
      'Facebook',
      'TikTok',
      'X',
    ]);
    expect(redes.every((r) => r.disponible), isTrue);
    expect(
      ConfiguracionLanding.redesSociales(x: null).last.disponible,
      isFalse,
    );
  });
}
