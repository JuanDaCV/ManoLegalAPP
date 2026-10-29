import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../configuracion/configuracion_recorrido_visitante.dart';
import '../../controlador/almacen_local.dart';
import '../../controlador/controlador_como_funciona.dart';
import '../../controlador/controlador_dictado_lexus.dart';
import '../../controlador/controlador_lexus.dart';
import '../../controlador/controlador_pqrs.dart';
import '../../controlador/servicio_perfil_publico.dart';
import '../autenticacion/widgets/landing/navegacion_landing.dart';
import '../cliente/seccion_como_funciona.dart';
import '../cliente/seccion_lexus.dart';
import '../compartido/barra_superior_post_login.dart';
import '../compartido/plantilla_post_login.dart';
import '../compartido/seccion_inicio.dart';
import '../compartido/seccion_pqrs.dart';
import '../compartido/widgets/recorrido/recorridos_por_seccion.dart';
import 'aviso_requiere_cuenta.dart';

/// Los mismos destinos, íconos y orden que el panel del cliente: el
/// visitante ve el producto tal como lo verá al crear su cuenta.
const List<DestinoNavegacion> _destinosVisitante = [
  (Icons.home_outlined, 'Inicio'),
  (Icons.help_outline, 'Cómo funciona'),
  (Icons.gavel_outlined, 'Lexus'),
  (Icons.support_agent, 'PQRS'),
];

/// Modo visitante: el panel del cliente para quien llega a la web sin
/// cuenta.
///
/// Solo existe en la web: se abre desde la landing («Encontrar abogado»,
/// «Buscar por especialidad», «Ingresar»). No hay sesión de Firebase ni un
/// uid inventado: el directorio lee la proyección pública `tarjetasAbogados`,
/// y todo lo que necesita una cuenta (ver un perfil completo, enviar a Lexus,
/// radicar una PQRS) muestra [AvisoRequiereCuenta] en lugar de hacerlo.
///
/// Cada sección tiene su recorrido guiado de visitante
/// ([ConfiguracionRecorridoVisitante]). Como no hay usuario, su estado se
/// recuerda por navegador con una clave fija de dispositivo, separada de la
/// de los recorridos de clientes y abogados.
///
/// Estas restricciones de la interfaz son de experiencia, no de seguridad:
/// la protección real son las reglas de Firestore, que sin sesión solo dejan
/// leer las tarjetas públicas.
///
/// Si se inicia sesión en otra pestaña, el panel se cierra y el enrutador
/// inicial muestra el panel que corresponde a esa cuenta. Mientras el
/// inicio de sesión o el registro abiertos desde aquí están encima, no se
/// cierra: esas pantallas terminan su propio flujo.
class PanelVisitante extends StatefulWidget {
  const PanelVisitante({
    super.key,
    this.servicioPerfilPublico,
    this.crearControladorLexus,
    this.crearDictado,
    this.crearControladorPqrs,
    this.crearControladorComoFunciona,
    this.crearControladorVideo,
    this.flujoSesion,
    this.almacenRecorridos,
    this.intervaloSondeoRecorridos,
  });

  /// Permiten a las pruebas reemplazar los servicios reales (Firestore,
  /// Lexus, micrófono, video y Authentication). En la aplicación siempre son
  /// `null` y se usan los reales.
  @visibleForTesting
  final ServicioPerfilPublico? servicioPerfilPublico;
  @visibleForTesting
  final ControladorLexus Function()? crearControladorLexus;
  @visibleForTesting
  final ControladorDictadoLexus Function(void Function(String texto) alTranscribir)? crearDictado;
  @visibleForTesting
  final ControladorPqrs Function()? crearControladorPqrs;
  @visibleForTesting
  final ControladorComoFunciona Function()? crearControladorComoFunciona;
  @visibleForTesting
  final VideoPlayerController Function()? crearControladorVideo;
  @visibleForTesting
  final Stream<User?>? flujoSesion;

  /// Almacén y sondeo de los recorridos guiados; `null` usa los del
  /// dispositivo.
  @visibleForTesting
  final AlmacenLocal? almacenRecorridos;
  @visibleForTesting
  final Duration? intervaloSondeoRecorridos;

  @override
  State<PanelVisitante> createState() => _PanelVisitanteState();
}

class _PanelVisitanteState extends State<PanelVisitante> {
  /// Igual que en el panel del cliente: conservan el estado de «Cómo
  /// funciona» y la conversación de Lexus al cruzar los 900 px de ancho.
  final _claveComoFunciona = GlobalKey();
  final _claveLexus = GlobalKey();

  /// El buscador del visitante lee la proyección pública: sin sesión, las
  /// reglas no dejan leer los perfiles completos.
  late final ServicioPerfilPublico _servicioTarjetas =
      widget.servicioPerfilPublico ??
      ServicioPerfilPublico(coleccionBusqueda: ServicioPerfilPublico.coleccionTarjetas);

  StreamSubscription<User?>? _suscripcionSesion;

  /// Verdadero mientras el inicio de sesión o el registro abiertos desde
  /// aquí están encima. Esas pantallas cierran todo al terminar; si este
  /// panel también cerrara al aparecer la sesión, cortaría el registro a
  /// medias (el usuario de Authentication existe antes que su perfil).
  bool _rutaAuthEncima = false;

  /// Si el último aviso de Authentication traía un usuario.
  bool _haySesion = false;

  @override
  void initState() {
    super.initState();
    // Firebase ya está listo: `NavegacionLanding.irAExplorar` lo espera
    // antes de abrir este panel.
    final flujo = widget.flujoSesion ?? FirebaseAuth.instance.authStateChanges();
    _suscripcionSesion = flujo.listen(_alCambiarSesion);
  }

  @override
  void dispose() {
    _suscripcionSesion?.cancel();
    super.dispose();
  }

  void _alCambiarSesion(User? usuario) {
    _haySesion = usuario != null;
    if (_haySesion) _volverAlInicio();
  }

  /// Vuelve a la primera ruta (el enrutador inicial), que ya muestra el
  /// panel de la cuenta. También cierra un aviso abierto.
  void _volverAlInicio() {
    if (!mounted || _rutaAuthEncima) return;
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  Future<void> _irAInicioSesion() => _abrirAutenticacion(NavegacionLanding.irAInicioSesion);

  Future<void> _irARegistro() => _abrirAutenticacion(NavegacionLanding.irARegistro);

  /// La navegación termina cuando se cierra la pantalla abierta. Si para
  /// entonces ya hay sesión (por ejemplo, se volvió atrás tras entrar con
  /// Google), este panel ya no tiene sentido y se cierra.
  Future<void> _abrirAutenticacion(Future<void> Function(BuildContext context) navegar) async {
    _rutaAuthEncima = true;
    try {
      await navegar(context);
    } finally {
      if (mounted) {
        _rutaAuthEncima = false;
        if (_haySesion) _volverAlInicio();
      }
    }
  }

  void _pedirCuenta(MotivoCuentaRequerida motivo) {
    mostrarAvisoRequiereCuenta(
      context,
      motivo: motivo,
      alIniciarSesion: _irAInicioSesion,
      alCrearCuenta: _irARegistro,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecorridosPorSeccion(
      recorridos: ConfiguracionRecorridoVisitante.todos,
      obtenerUid: () => ConfiguracionRecorridoVisitante.claveDispositivo,
      almacen: widget.almacenRecorridos,
      intervaloSondeo: widget.intervaloSondeoRecorridos,
      constructor: _construirPlantilla,
    );
  }

  Widget _construirPlantilla(ValueChanged<int> alCambiarSeccion) {
    return PlantillaPostLogin(
      destinos: _destinosVisitante,
      nombre: null,
      alCambiarSeccion: alCambiarSeccion,
      alIngresar: _irAInicioSesion,
      alCrearCuenta: _irARegistro,
      alVolver: () => Navigator.maybePop(context),
      construirSecciones: (esEscritorio) => [
        SeccionInicio(
          // Sin nombre: el título reemplaza el saludo personal.
          nombre: '',
          titulo: 'Bienvenido a ManoLegal',
          esEscritorio: esEscritorio,
          servicioPerfilPublico: _servicioTarjetas,
          alVerPerfil: (_) => _pedirCuenta(MotivoCuentaRequerida.verPerfil),
          crearControladorVideo: widget.crearControladorVideo,
        ),
        SeccionComoFunciona(
          key: _claveComoFunciona,
          crearControlador: widget.crearControladorComoFunciona,
        ),
        SeccionLexus(
          key: _claveLexus,
          crearControlador: widget.crearControladorLexus,
          crearDictado: widget.crearDictado,
          alRequerirCuenta: () => _pedirCuenta(MotivoCuentaRequerida.lexus),
        ),
        SeccionPqrs(
          crearControlador: widget.crearControladorPqrs,
          alRequerirCuenta: () => _pedirCuenta(MotivoCuentaRequerida.pqrs),
        ),
      ],
    );
  }
}
