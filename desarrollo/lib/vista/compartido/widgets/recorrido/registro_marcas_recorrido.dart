import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../controlador/controlador_recorrido.dart';
import '../../../../modelo/modelo_paso_recorrido.dart';
import 'pintor_foco_recorrido.dart';

/// Duración del desplazamiento hacia un paso y de su restauración al terminar.
const Duration _duracionDesplazamiento = Duration(milliseconds: 300);

/// Espacio que se intenta dejar libre debajo de la marca para la tarjeta
/// explicativa: lo que ocupa en un teléfono con su texto más largo.
const double _espacioParaTarjeta = 300;

class _Entrada {
  _Entrada({
    required this.propietario,
    required this.contexto,
    required this.visible,
  });

  /// Quién registró la marca (el `State` de su registrador): permite saber si
  /// quien libera sigue siendo el dueño.
  final Object propietario;
  final BuildContext contexto;
  final bool visible;
}

/// Dónde está cada elemento que el recorrido puede señalar.
///
/// Los `MarcaRecorrido` de la interfaz se registran aquí y el recorrido los
/// consulta para saber si están a la vista, dónde están y cómo desplazarse
/// hasta ellos. Es un mapa simple y a propósito NO es un `Listenable`: las
/// marcas se registran durante el build, y notificar entonces provocaría un
/// `setState` en pleno build.
///
/// Un mismo id puede estar registrado por varios elementos a la vez (uno por
/// dueño): el panel monta todas sus pestañas, y un mismo componente puede
/// aparecer en dos de ellas. Manda el registrado más recientemente de los que
/// están a la vista, para que una copia en una pestaña oculta nunca tape a la
/// que se ve.
class RegistroMarcasRecorrido implements PuenteVistaRecorrido {
  /// Entradas de cada id en orden de registro: la última es la más reciente.
  final Map<MarcaRecorridoId, List<_Entrada>> _entradas = {};
  final Map<MarcaRecorridoId, int> _versiones = {};

  /// Dueño de la entrada que manda en cada id, para saber cuándo cambia.
  final Map<MarcaRecorridoId, Object> _duenos = {};

  ScrollPosition? _posicionGuardada;
  double? _pixelesGuardados;
  MarcaRecorridoId? _marcaGuardada;

  /// Registra [contexto] como la marca [id] de [propietario]. Si ese
  /// propietario ya la tenía, solo actualiza el contexto y [visible]; si no,
  /// agrega una entrada nueva. [version] sube si cambia la entrada que manda.
  void registrar(
    MarcaRecorridoId id,
    BuildContext contexto, {
    required Object propietario,
    required bool visible,
  }) {
    final entradas = _entradas.putIfAbsent(id, () => []);
    final nueva = _Entrada(
      propietario: propietario,
      contexto: contexto,
      visible: visible,
    );
    final indice = entradas.indexWhere(
      (e) => identical(e.propietario, propietario),
    );
    if (indice == -1) {
      entradas.add(nueva);
    } else {
      entradas[indice] = nueva;
    }
    _actualizarVersion(id);
  }

  /// Quita la marca [id] de [propietario], si la tiene.
  ///
  /// La identidad importa: al cruzar el ancho de escritorio las secciones se
  /// montan de nuevo, y la marca nueva se registra (durante el build) ANTES de
  /// que la vieja se libere (al final del cuadro). Sin esta comprobación, la
  /// vieja borraría a la nueva.
  void liberar(MarcaRecorridoId id, Object propietario) {
    final entradas = _entradas[id];
    if (entradas == null) return;
    entradas.removeWhere((e) => identical(e.propietario, propietario));
    if (entradas.isEmpty) _entradas.remove(id);
    _actualizarVersion(id);
  }

  /// Cuántas veces cambió la entrada que manda en la marca [id]. Si sube, el
  /// elemento se recreó (o lo reemplazó otro) y quien lo estaba señalando
  /// debe volver a desplazarse hasta él.
  int version(MarcaRecorridoId id) => _versiones[id] ?? 0;

  /// La entrada que manda según lo declarado al registrarse: la más reciente
  /// de las visibles o, si ninguna lo es, la más reciente. No mira si ya
  /// tiene tamaño, porque las marcas se registran durante el build, antes del
  /// layout.
  _Entrada? _entradaPreferida(MarcaRecorridoId id) {
    final entradas = _entradas[id];
    if (entradas == null || entradas.isEmpty) return null;
    for (final entrada in entradas.reversed) {
      if (entrada.visible) return entrada;
    }
    return entradas.last;
  }

  void _actualizarVersion(MarcaRecorridoId id) {
    final dueno = _entradaPreferida(id)?.propietario;
    if (dueno == null) {
      // Sin entradas: la próxima que llegue, sea quien sea, es un elemento
      // nuevo.
      _duenos.remove(id);
      return;
    }
    if (!identical(_duenos[id], dueno)) {
      _versiones[id] = version(id) + 1;
      _duenos[id] = dueno;
    }
  }

  /// Contexto de la marca [id] si está montada, visible y con tamaño. Si hay
  /// varias, el de la registrada más recientemente que cumpla las tres.
  ///
  /// Visible según `Visibility.of`: un `IndexedStack` mantiene dibujadas (y
  /// con tamaño) las pestañas ocultas, pero las reporta como no visibles.
  BuildContext? contextoDisponible(MarcaRecorridoId id) {
    final entradas = _entradas[id];
    if (entradas == null) return null;
    for (final entrada in entradas.reversed) {
      if (!entrada.visible) continue;
      final contexto = entrada.contexto;
      if (!contexto.mounted) continue;
      final caja = contexto.findRenderObject();
      if (caja is! RenderBox || !caja.attached || !caja.hasSize) continue;
      return contexto;
    }
    return null;
  }

  @override
  bool estaDisponible(MarcaRecorridoId marca) =>
      contextoDisponible(marca) != null;

  /// Rectángulo de la marca [id] en coordenadas globales (de pantalla), o
  /// `null` si no está disponible o no se ve nada de ella.
  ///
  /// Se recorta al área visible del desplazamiento que la contiene, para que
  /// el hueco del recorrido nunca deje ver una barra de la app.
  Rect? rectoGlobal(MarcaRecorridoId id) {
    final contexto = contextoDisponible(id);
    if (contexto == null) return null;
    final caja = contexto.findRenderObject()! as RenderBox;
    var rect = _rectoGlobalDe(caja);

    final area = Scrollable.maybeOf(contexto)?.context.findRenderObject();
    if (area is RenderBox && area.attached && area.hasSize) {
      // El pintor agranda el hueco en su holgura: se recorta con ese margen
      // para que, ya agrandado, no se salga del área visible ni deje ver la
      // barra superior (pasa con elementos más altos que la pantalla, como el
      // panel de filtros de escritorio).
      rect = rect.intersect(
        _rectoGlobalDe(area).deflate(PintorFocoRecorrido.holgura),
      );
    }
    return rect.isEmpty ? null : rect;
  }

  Rect _rectoGlobalDe(RenderBox caja) {
    return MatrixUtils.transformRect(
      caja.getTransformTo(null),
      Offset.zero & caja.size,
    );
  }

  /// Deja la marca [marca] a la vista con espacio para la tarjeta explicativa.
  ///
  /// Se busca dejar [_espacioParaTarjeta] libres debajo de la marca: en
  /// pantallas altas eso la deja un poco por encima del centro (como mucho al
  /// 35 %), y en teléfonos bajos la sube hasta arriba. Una marca más alta que
  /// el 70 % del área visible (el panel de filtros de escritorio) se alinea
  /// arriba y la tarjeta va a su costado.
  @override
  Future<void> prepararPaso(MarcaRecorridoId marca) async {
    final contexto = contextoDisponible(marca);
    if (contexto == null) return;

    final caja = contexto.findRenderObject()! as RenderBox;
    final posicion = Scrollable.maybeOf(contexto)?.position;
    var alineacion = 0.35;
    if (posicion != null && posicion.hasViewportDimension) {
      final visible = posicion.viewportDimension;
      final alto = caja.size.height;
      if (alto > 0.7 * visible) {
        alineacion = 0;
      } else {
        // Con la marca alineada en `a`, debajo quedan (1 - a) * (visible -
        // alto) píxeles: se elige el mayor `a` (hasta 0,35) que deje el
        // espacio buscado.
        final libre = visible - alto;
        alineacion = libre <= 0
            ? 0
            : (1 - _espacioParaTarjeta / libre).clamp(0.0, 0.35);
      }
    }
    final reducirMovimiento =
        MediaQuery.maybeDisableAnimationsOf(contexto) ?? false;

    try {
      await Scrollable.ensureVisible(
        contexto,
        alignment: alineacion,
        duration: reducirMovimiento ? Duration.zero : _duracionDesplazamiento,
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {
      // Si no se pudo desplazar, el paso se muestra donde esté la marca.
    }
  }

  @override
  void capturarDesplazamiento(MarcaRecorridoId marca) {
    final contexto = contextoDisponible(marca);
    final posicion = contexto == null
        ? null
        : Scrollable.maybeOf(contexto)?.position;
    if (posicion == null || !posicion.hasPixels) {
      _olvidarDesplazamiento();
      return;
    }
    _posicionGuardada = posicion;
    _pixelesGuardados = posicion.pixels;
    _marcaGuardada = marca;
  }

  /// Devuelve el desplazamiento guardado, pero solo si la pantalla sigue
  /// siendo la misma: si las secciones se volvieron a montar, esa posición ya
  /// no existe y mover la nueva sería desplazar algo que el usuario no vio.
  ///
  /// Se busca a través de la misma marca con la que se capturó: cada sección
  /// tiene su propio desplazamiento.
  @override
  void restaurarDesplazamiento() {
    final guardada = _posicionGuardada;
    final pixeles = _pixelesGuardados;
    final marca = _marcaGuardada;
    _olvidarDesplazamiento();
    if (guardada == null || pixeles == null || marca == null) return;

    final contexto = contextoDisponible(marca);
    final actual = contexto == null
        ? null
        : Scrollable.maybeOf(contexto)?.position;
    if (contexto == null || actual == null) return;
    if (!identical(actual, guardada) ||
        !actual.hasPixels ||
        !actual.hasContentDimensions) {
      return;
    }

    final destino = pixeles.clamp(
      actual.minScrollExtent,
      actual.maxScrollExtent,
    );
    if (destino == actual.pixels) return;
    if (MediaQuery.maybeDisableAnimationsOf(contexto) ?? false) {
      actual.jumpTo(destino);
    } else {
      unawaited(
        actual.animateTo(
          destino,
          duration: _duracionDesplazamiento,
          curve: Curves.easeInOutCubic,
        ),
      );
    }
  }

  void _olvidarDesplazamiento() {
    _posicionGuardada = null;
    _pixelesGuardados = null;
    _marcaGuardada = null;
  }
}
