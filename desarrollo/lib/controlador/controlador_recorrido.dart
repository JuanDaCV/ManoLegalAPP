import 'dart:async';

import 'package:flutter/foundation.dart';

import '../configuracion/configuracion_recorrido_cliente.dart';
import '../modelo/modelo_estado_recorrido.dart';
import '../modelo/modelo_paso_recorrido.dart';
import 'servicio_estado_recorrido.dart';

/// Lo que el controlador necesita saber de la pantalla, sin conocer widgets:
/// qué elementos hay a la vista y cómo dejarlos a la vista. Lo implementa el
/// registro de marcas de la vista (`RegistroMarcasRecorrido`).
abstract interface class PuenteVistaRecorrido {
  /// Si [marca] está montada, dibujada y visible. Una marca en una pestaña
  /// oculta no cuenta.
  bool estaDisponible(MarcaRecorridoId marca);

  /// Deja [marca] a la vista, desplazando la pantalla si hace falta. Termina
  /// cuando acaba el desplazamiento.
  Future<void> prepararPaso(MarcaRecorridoId marca);

  /// Recuerda el desplazamiento de la pantalla que contiene a [marca], para
  /// devolverlo al terminar el recorrido.
  void capturarDesplazamiento(MarcaRecorridoId marca);

  /// Devuelve la pantalla al desplazamiento capturado, si sigue siendo la
  /// misma.
  void restaurarDesplazamiento();
}

/// Lleva el recorrido guiado: si hay que mostrarlo, en qué paso va y qué
/// guardar al terminar. No conoce widgets ni `BuildContext`; la vista lo
/// observa y le pide cada acción.
///
/// El recorrido solo se muestra la primera vez de cada usuario en el
/// dispositivo. Ante cualquier duda (uid desconocido, almacenamiento ilegible,
/// pantalla que no está lista) prefiere no mostrarse a molestar de más.
class ControladorRecorrido extends ChangeNotifier {
  ControladorRecorrido({
    required List<ModeloPasoRecorrido> pasos,
    required this._servicio,
    required this._vista,
    required this._obtenerUid,
    this.marcaInicial = MarcaRecorridoId.buscador,
    this.marcaCargando = MarcaRecorridoId.cargandoResultados,
    this.esperaBuscador = ConfiguracionRecorridoCliente.esperaBuscador,
    this.esperaResultados = ConfiguracionRecorridoCliente.esperaResultados,
    this.intervaloSondeo = ConfiguracionRecorridoCliente.intervaloSondeo,
  }) : _pasos = List.unmodifiable(pasos),
       _pasosActivos = List.unmodifiable(pasos);

  final List<ModeloPasoRecorrido> _pasos;
  final ServicioEstadoRecorrido _servicio;
  final PuenteVistaRecorrido _vista;
  final String? Function() _obtenerUid;

  /// Elemento cuya presencia indica que la sección está a la vista y lista.
  /// Su desplazamiento es el que se recuerda y se devuelve al terminar. Por
  /// defecto, el buscador de Inicio.
  final MarcaRecorridoId marcaInicial;

  /// Indicador de carga que debe desaparecer antes de decidir qué pasos
  /// mostrar, o `null` si no hay nada que esperar. Por defecto, la carga de
  /// los resultados de Inicio.
  final MarcaRecorridoId? marcaCargando;

  /// Cuánto se espera a que [marcaInicial] esté a la vista antes de
  /// renunciar. Conserva su nombre original (en Inicio es el buscador).
  final Duration esperaBuscador;

  /// Cuánto se espera a que desaparezca [marcaCargando]. Conserva su nombre
  /// original (en Inicio son los resultados).
  final Duration esperaResultados;

  /// Cada cuánto se consulta a la vista mientras se espera.
  final Duration intervaloSondeo;

  List<ModeloPasoRecorrido> _pasosActivos;
  bool _visible = false;
  bool _preparando = false;
  bool _marcaPresente = true;
  int _indice = 0;
  String? _uid;

  bool _iniciado = false;
  bool _desechado = false;

  /// Cambia con cada [cancelarInicio]. Un inicio en curso que ya no es el
  /// último (porque se canceló) abandona sin mostrar nada.
  int _inicio = 0;

  /// Esperas entre consultas en curso. Cancelar o desechar las interrumpe:
  /// así una espera vieja termina enseguida y no deja temporizadores vivos.
  final Set<Completer<void>> _pausas = {};

  /// Cambia con cada navegación. Una navegación en curso que ya no es la
  /// última (porque se cerró o se pidió otra) no debe tocar el estado.
  int _generacion = 0;

  /// Si la capa del recorrido está en pantalla.
  bool get visible => _visible;

  /// Si se está resolviendo o desplazando hacia un paso. Mientras tanto, la
  /// vista oculta la tarjeta y el hueco, y no atiende acciones.
  bool get preparando => _preparando;

  /// Pasos de este recorrido. Antes de pulsar «Comenzar» son todos; después,
  /// solo los que tienen algo que mostrar.
  List<ModeloPasoRecorrido> get pasosActivos => _pasosActivos;

  int get indice => _indice;

  ModeloPasoRecorrido? get pasoActual {
    if (!_visible || _indice >= _pasosActivos.length) return null;
    return _pasosActivos[_indice];
  }

  /// Si la marca del paso actual está en pantalla. Cuando no, el paso se
  /// muestra centrado y con su texto para ese caso.
  bool get marcaPresente => _marcaPresente;

  /// Posición del paso actual entre los que señalan algo (desde 1), o `null`
  /// en la bienvenida y el cierre.
  int? get numeroDePaso {
    final paso = pasoActual;
    if (paso == null || paso.tipo != TipoPasoRecorrido.resaltado) return null;
    return _pasosActivos
        .take(_indice + 1)
        .where((p) => p.tipo == TipoPasoRecorrido.resaltado)
        .length;
  }

  /// Cuántos pasos señalan algo en pantalla.
  int get totalPasos =>
      _pasosActivos.where((p) => p.tipo == TipoPasoRecorrido.resaltado).length;

  /// Se puede volver desde cualquier paso resaltado salvo el primero, y desde
  /// el cierre. Nunca se vuelve a la bienvenida.
  bool get puedeRetroceder => _indiceDelPasoAnterior != -1;

  int get _indiceDelPasoAnterior {
    final paso = pasoActual;
    if (paso == null || paso.tipo == TipoPasoRecorrido.bienvenida) return -1;
    for (var i = _indice - 1; i >= 0; i--) {
      if (_pasosActivos[i].tipo == TipoPasoRecorrido.resaltado) return i;
    }
    return -1;
  }

  /// Decide si hay que mostrar el recorrido y, si es así, lo muestra. Solo
  /// actúa la primera vez que se llama (o la primera después de
  /// [cancelarInicio]).
  ///
  /// Si el estado no se puede leer o [marcaInicial] no llega a estar a la
  /// vista (por ejemplo, el usuario cambió de pestaña), no muestra nada y no
  /// guarda nada: la próxima visita lo volverá a intentar.
  Future<void> iniciarSiCorresponde() async {
    if (_iniciado || _desechado) return;
    _iniciado = true;
    final inicio = _inicio;
    bool cancelado() => _desechado || inicio != _inicio;

    final uid = _obtenerUid();
    if (uid == null || _pasos.isEmpty) return;

    final EstadoRecorrido estado;
    try {
      estado = await _servicio.leer(uid);
    } catch (_) {
      // Falla cerrado: sin poder leer no se sabe si ya lo vio.
      return;
    }
    if (cancelado() || estado != EstadoRecorrido.noVisto) return;

    final listo = await _esperarHasta(
      () => _vista.estaDisponible(marcaInicial),
      esperaBuscador,
      cancelado: cancelado,
    );
    if (cancelado() || !listo) return;

    _uid = uid;
    _vista.capturarDesplazamiento(marcaInicial);
    _pasosActivos = List.unmodifiable(_pasos);
    _indice = 0;
    _marcaPresente = true;
    _preparando = false;
    _visible = true;
    _notificar();
  }

  /// Abandona un inicio pendiente (leyendo el estado o esperando a
  /// [marcaInicial]) y deja el controlador listo para volver a intentarlo
  /// con [iniciarSiCorresponde]. Se usa al salir de la sección: el recorrido
  /// de una pestaña que ya no se ve no debe aparecer de pronto.
  ///
  /// Con el recorrido en pantalla no hace nada: ese solo termina por una
  /// acción del usuario.
  void cancelarInicio() {
    if (_visible || _desechado) return;
    _inicio++;
    _iniciado = false;
    _interrumpirPausas();
  }

  /// Sale de la bienvenida: espera a que termine la carga de la sección (si
  /// tiene [marcaCargando]), resuelve qué pasos hay que mostrar y va al
  /// primero.
  Future<void> comenzar() async {
    if (!_visible || _preparando) return;
    if (pasoActual?.tipo != TipoPasoRecorrido.bienvenida) return;

    _preparando = true;
    _notificar();

    // Lo que se señala puede llegar de forma asíncrona (las tarjetas de
    // Inicio). Sin esperar, el recorrido decidiría «no hay abogados» mientras
    // todavía se están cargando.
    final cargando = marcaCargando;
    if (cargando != null) {
      await _esperarHasta(
        () => !_vista.estaDisponible(cargando),
        esperaResultados,
        cancelado: () => !_visible,
      );
    }
    if (_desechado || !_visible) return;

    _pasosActivos = _resolverPasos();
    final primero = _pasosActivos.indexWhere(
      (p) => p.tipo == TipoPasoRecorrido.resaltado,
    );
    await _irA(primero == -1 ? _pasosActivos.length - 1 : primero);
  }

  /// Avanza al paso siguiente. En la bienvenida equivale a [comenzar]; en el
  /// cierre no hace nada (se termina con [finalizar]).
  Future<void> siguiente() async {
    if (!_visible || _preparando) return;
    final paso = pasoActual;
    if (paso == null) return;
    switch (paso.tipo) {
      case TipoPasoRecorrido.bienvenida:
        await comenzar();
      case TipoPasoRecorrido.resaltado:
        if (_indice + 1 < _pasosActivos.length) {
          await _irA(_indice + 1);
        } else {
          await finalizar();
        }
      case TipoPasoRecorrido.cierre:
        break;
    }
  }

  Future<void> anterior() async {
    if (!_visible || _preparando || !puedeRetroceder) return;
    await _irA(_indiceDelPasoAnterior);
  }

  /// Vuelve a desplazar hacia la marca del paso actual. La vista lo pide
  /// cuando la marca se recreó (por ejemplo, al cruzar el ancho de escritorio
  /// se vuelven a montar las secciones) y ya no está donde se midió.
  Future<void> reprepararPasoActual() async {
    if (!_visible || pasoActual?.marca == null) return;
    await _irA(_indice);
  }

  /// Termina sin completar («Saltar tutorial») y lo recuerda como omitido.
  Future<void> omitir() => _terminar(EstadoRecorrido.omitido);

  /// Termina el recorrido y lo recuerda como completado.
  Future<void> finalizar() => _terminar(EstadoRecorrido.completado);

  /// Cerrar con la X, Esc o el botón atrás. Cerrar en el último paso cuenta
  /// como terminar; en cualquier otro, como omitir.
  Future<void> cerrarPorUsuario() {
    return pasoActual?.tipo == TipoPasoRecorrido.cierre
        ? finalizar()
        : omitir();
  }

  /// Descarta el recorrido sin guardar nada: si el panel se cierra a mitad (se
  /// recargó la página, se cerró sesión), el recorrido volverá a aparecer.
  @override
  void dispose() {
    _desechado = true;
    _interrumpirPausas();
    super.dispose();
  }

  /// Deja los pasos que tienen algo que mostrar. La bienvenida y el cierre
  /// siempre se quedan; un paso resaltado se queda si su marca está en
  /// pantalla, o si pide mostrarse centrado.
  List<ModeloPasoRecorrido> _resolverPasos() {
    return List.unmodifiable([
      for (final paso in _pasos)
        if (_tieneQueMostrar(paso)) paso,
    ]);
  }

  bool _tieneQueMostrar(ModeloPasoRecorrido paso) {
    final marca = paso.marca;
    if (paso.tipo != TipoPasoRecorrido.resaltado || marca == null) return true;
    // Un paso que depende de otro elemento (el botón «Ver perfil» de la
    // tarjeta) no tiene a qué señalar sin él, y no se muestra ni centrado.
    final requerida = paso.requiereMarca;
    if (requerida != null && !_vista.estaDisponible(requerida)) return false;
    if (_vista.estaDisponible(marca)) return true;
    return paso.siFaltaMarca == SiFaltaMarca.centrar;
  }

  /// Va al paso [indice]. La vista oculta la tarjeta mientras se desplaza a la
  /// marca, para no mostrar un hueco que todavía se está moviendo.
  Future<void> _irA(int indice) async {
    final generacion = ++_generacion;
    _indice = indice;
    _preparando = true;
    final marca = _pasosActivos[indice].marca;
    _marcaPresente = marca == null || _vista.estaDisponible(marca);
    _notificar();

    if (marca != null && _marcaPresente) {
      try {
        await _vista.prepararPaso(marca);
      } catch (_) {
        // Si no se pudo desplazar, el paso se muestra donde esté la marca.
      }
    }
    if (_desechado || !_visible || generacion != _generacion) return;
    _preparando = false;
    _notificar();
  }

  /// Cierra primero y guarda después: ocultar el recorrido no debe esperar a
  /// un almacenamiento lento.
  Future<void> _terminar(EstadoRecorrido estado) async {
    if (!_visible) return;
    final uid = _uid;
    _cerrar();
    if (uid == null) return;
    try {
      await _servicio.guardar(uid, estado);
    } catch (_) {
      // No poder guardar no rompe nada: el recorrido se mostrará otra vez.
    }
  }

  void _cerrar() {
    _visible = false;
    _preparando = false;
    _generacion++;
    _vista.restaurarDesplazamiento();
    _notificar();
  }

  /// Espera a que [condicion] se cumpla, consultando cada [intervaloSondeo]
  /// hasta [limite]. Cuenta intentos en lugar de medir tiempo real, para que
  /// el resultado no dependa del reloj (ni de uno falso en las pruebas).
  ///
  /// Abandona en cuanto [cancelado] lo indique (o el controlador se
  /// deseche), sin consultar más la vista.
  Future<bool> _esperarHasta(
    bool Function() condicion,
    Duration limite, {
    bool Function()? cancelado,
  }) async {
    bool abandonar() => _desechado || (cancelado?.call() ?? false);
    if (abandonar()) return false;
    if (condicion()) return true;
    final pasoEnMicros = intervaloSondeo.inMicroseconds <= 0
        ? 1
        : intervaloSondeo.inMicroseconds;
    final intentos = (limite.inMicroseconds / pasoEnMicros).ceil();
    for (var i = 0; i < intentos; i++) {
      await _pausar(intervaloSondeo);
      if (abandonar()) return false;
      if (condicion()) return true;
    }
    return false;
  }

  /// Como `Future.delayed`, pero [_interrumpirPausas] la termina antes y
  /// cancela su temporizador.
  Future<void> _pausar(Duration duracion) {
    final pausa = Completer<void>();
    final temporizador = Timer(duracion, () {
      if (_pausas.remove(pausa)) pausa.complete();
    });
    _pausas.add(pausa);
    return pausa.future.whenComplete(temporizador.cancel);
  }

  void _interrumpirPausas() {
    final pendientes = _pausas.toList();
    _pausas.clear();
    for (final pausa in pendientes) {
      pausa.complete();
    }
  }

  void _notificar() {
    if (!_desechado) notifyListeners();
  }
}
