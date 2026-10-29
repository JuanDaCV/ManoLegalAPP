import 'package:flutter/foundation.dart';

import '../configuracion/configuracion_recorrido_cliente.dart';
import '../modelo/modelo_recorrido.dart';
import 'almacen_local.dart';
import 'controlador_recorrido.dart';
import 'servicio_estado_recorrido.dart';

/// Decide qué recorrido guiado corresponde a la sección que se ve.
///
/// Un panel tiene una sola capa de recorrido y un solo registro de marcas; el
/// coordinador le dice cuál de sus controladores está activo. Cada sección
/// con recorrido tiene su propio [ControladorRecorrido], que se crea la
/// primera vez que se entra en ella y vive mientras viva el panel.
///
/// Reglas:
/// - Solo un recorrido a la vez. Mientras uno está en pantalla, los cambios
///   de sección se ignoran (la capa tapa la navegación, así que no deberían
///   ocurrir).
/// - Al salir de una sección se cancela su inicio pendiente: el recorrido de
///   una pestaña que ya no se ve no debe aparecer de pronto.
/// - Un recorrido que terminó en esta sesión no se vuelve a intentar, aunque
///   su estado todavía no se haya terminado de guardar.
class CoordinadorRecorridos extends ChangeNotifier {
  CoordinadorRecorridos({
    required List<ModeloRecorrido?> recorridos,
    required this._vista,
    required this._obtenerUid,
    AlmacenLocal? almacen,
    this.intervaloSondeo = ConfiguracionRecorridoCliente.intervaloSondeo,
  }) : _recorridos = List.unmodifiable(recorridos),
       _almacenInyectado = almacen;

  /// Recorrido de cada sección, en el orden de la navegación. `null` en las
  /// secciones sin recorrido.
  final List<ModeloRecorrido?> _recorridos;
  final PuenteVistaRecorrido _vista;
  final String? Function() _obtenerUid;
  final AlmacenLocal? _almacenInyectado;

  /// Cada cuánto consultan la vista los controladores mientras esperan.
  final Duration intervaloSondeo;

  /// Un único almacén para todos los recorridos: en móvil es un solo archivo,
  /// y dos instancias escribiéndolo a la vez podrían pisarse. Se crea al
  /// usarlo por primera vez.
  late final AlmacenLocal _almacen = _almacenInyectado ?? crearAlmacenLocal();

  final Map<int, ControladorRecorrido> _controladores = {};

  /// Lo que se registró como oyente de cada controlador, para poder quitarlo.
  final Map<ControladorRecorrido, VoidCallback> _oyentes = {};

  /// Si cada controlador estaba visible la última vez que avisó: así se sabe
  /// cuándo uno pasa de visible a oculto (terminó).
  final Map<ControladorRecorrido, bool> _visibles = {};

  /// Recorridos que terminaron (completados u omitidos) en esta sesión. El
  /// controlador oculta la capa antes de guardar: sin esto, salir y volver
  /// enseguida podría leer «no visto» y mostrarlo otra vez.
  final Set<String> _terminados = {};

  /// Para las secciones sin recorrido: sin pasos, nunca se muestra. Así la
  /// capa siempre tiene un controlador que observar. Se crea al pedirlo.
  ControladorRecorrido? _inerteCreado;
  ControladorRecorrido get _inerte => _inerteCreado ??= ControladorRecorrido(
    pasos: const [],
    servicio: ServicioEstadoRecorridoLocal(almacen: _almacen),
    vista: _vista,
    obtenerUid: _obtenerUid,
    intervaloSondeo: intervaloSondeo,
  );

  ControladorRecorrido? _activo;
  int? _seccionActiva;
  bool _desechado = false;

  /// El controlador que la capa debe mostrar ahora.
  ControladorRecorrido get controladorActivo => _activo ?? _inerte;

  /// Sección en la que se está, o `null` antes de la primera llamada a
  /// [alEntrarEnSeccion].
  int? get seccionActiva => _seccionActiva;

  /// Si algún recorrido está en pantalla.
  bool get hayRecorridoVisible =>
      _controladores.values.any((controlador) => controlador.visible);

  /// Ids de los recorridos que terminaron en esta sesión.
  Set<String> get terminados => Set.unmodifiable(_terminados);

  /// El usuario entró en la sección [indice]: cancela el inicio pendiente de
  /// la anterior e intenta el de esta.
  void alEntrarEnSeccion(int indice) {
    if (_desechado || hayRecorridoVisible) return;

    final anterior = _seccionActiva;
    if (anterior != null && anterior != indice) {
      _controladores[anterior]?.cancelarInicio();
    }
    _seccionActiva = indice;

    final modelo = indice >= 0 && indice < _recorridos.length
        ? _recorridos[indice]
        : null;
    final controlador = modelo == null ? _inerte : _controladorDe(indice, modelo);
    _activar(controlador);
    if (modelo != null && !_terminados.contains(modelo.id)) {
      controlador.iniciarSiCorresponde();
    }
  }

  ControladorRecorrido _controladorDe(int indice, ModeloRecorrido modelo) {
    final existente = _controladores[indice];
    if (existente != null) return existente;
    final controlador = ControladorRecorrido(
      pasos: modelo.pasos,
      servicio: ServicioEstadoRecorridoLocal(
        almacen: _almacen,
        prefijoClave: modelo.prefijoClave,
      ),
      vista: _vista,
      obtenerUid: _obtenerUid,
      marcaInicial: modelo.marcaInicial,
      marcaCargando: modelo.marcaCargando,
      esperaBuscador: modelo.esperaInicial,
      esperaResultados: modelo.esperaCarga,
      intervaloSondeo: intervaloSondeo,
    );
    void oyente() => _alCambiarControlador(controlador, modelo);
    _controladores[indice] = controlador;
    _visibles[controlador] = false;
    _oyentes[controlador] = oyente;
    controlador.addListener(oyente);
    return controlador;
  }

  void _alCambiarControlador(
    ControladorRecorrido controlador,
    ModeloRecorrido modelo,
  ) {
    if (_desechado) return;
    final antes = _visibles[controlador] ?? false;
    final ahora = controlador.visible;
    _visibles[controlador] = ahora;
    if (antes && !ahora) _terminados.add(modelo.id);
    // Por defensa: un recorrido que aparece debe ser el que la capa muestra,
    // aunque no sea el de la sección activa.
    if (ahora) _activar(controlador);
  }

  void _activar(ControladorRecorrido controlador) {
    if (identical(controlador, controladorActivo)) {
      _activo = controlador;
      return;
    }
    _activo = controlador;
    notifyListeners();
  }

  /// Primero deja de escuchar y después desecha: un controlador desechado no
  /// debe avisar a un coordinador que ya no existe. Desechar no guarda nada,
  /// así que un recorrido a medias volverá a aparecer en la próxima visita.
  @override
  void dispose() {
    _desechado = true;
    _oyentes.forEach((controlador, oyente) {
      controlador.removeListener(oyente);
    });
    final controladores = [..._controladores.values, ?_inerteCreado];
    _oyentes.clear();
    _controladores.clear();
    _visibles.clear();
    _activo = null;
    for (final controlador in controladores) {
      controlador.dispose();
    }
    super.dispose();
  }
}
