/// Enlaces externos de la landing web. Todo valor `null` se muestra como
/// "pendiente" o "próximamente": la landing nunca inventa una URL.
abstract final class ConfiguracionLanding {
  // Descargas públicas del APK. Para dejar una como "Enlace pendiente",
  // cámbiala a `static const String? ... = null;`.
  static const String descargaGoogleDrive =
      'https://drive.google.com/file/d/1Mn1K6JlC_oL4Nu9yCxFZe-8AgwrQUvkH/view?usp=sharing';
  static const String descargaMediaFire =
      'https://www.mediafire.com/file/znogbtl2g9bo508/ManoLegal-APP.apk/file';
  static const String descargaMega =
      'https://mega.nz/file/5YIFQD4I#DZXJH_tr-PgUW8jsccfceSw6d-mLY0XBrrb-w_y7AHg';

  // Redes oficiales. Para dejar una como "Próximamente", cámbiala a
  // `static const String? ... = null;`.
  static const String instagram = 'https://www.instagram.com/mano.legalapp';
  static const String facebook =
      'https://www.facebook.com/profile.php?id=61595188107866';
  static const String tiktok = 'https://www.tiktok.com/@mano.legal_app';
  static const String x = 'https://x.com/ManoLegalAPP';

  // PENDIENTE: correo oficial de contacto. null = no se muestra.
  static const String? correoContacto = null;

  /// Solo se abren enlaces `https` con host: nunca `http`, `javascript:` ni
  /// una cadena vacía.
  static bool esUrlValida(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static List<OpcionEnlace> opcionesDescarga({
    String? googleDrive = descargaGoogleDrive,
    String? mediaFire = descargaMediaFire,
    String? mega = descargaMega,
  }) {
    return [
      OpcionEnlace(TipoEnlace.googleDrive, 'Google Drive', googleDrive),
      OpcionEnlace(TipoEnlace.mediaFire, 'MediaFire', mediaFire),
      OpcionEnlace(TipoEnlace.mega, 'MEGA', mega),
    ];
  }

  static List<OpcionEnlace> redesSociales({
    String? instagram = ConfiguracionLanding.instagram,
    String? facebook = ConfiguracionLanding.facebook,
    String? tiktok = ConfiguracionLanding.tiktok,
    String? x = ConfiguracionLanding.x,
  }) {
    return [
      OpcionEnlace(TipoEnlace.instagram, 'Instagram', instagram),
      OpcionEnlace(TipoEnlace.facebook, 'Facebook', facebook),
      OpcionEnlace(TipoEnlace.tiktok, 'TikTok', tiktok),
      OpcionEnlace(TipoEnlace.x, 'X', x),
    ];
  }
}

enum TipoEnlace { googleDrive, mediaFire, mega, instagram, facebook, tiktok, x }

class OpcionEnlace {
  const OpcionEnlace(this.tipo, this.nombre, this.url);

  final TipoEnlace tipo;
  final String nombre;
  final String? url;

  bool get disponible => ConfiguracionLanding.esUrlValida(url);
}
