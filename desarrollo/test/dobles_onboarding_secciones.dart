import 'dart:async';

import 'package:desarrollo/configuracion/configuracion_recorrido_abogado.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_pqrs.dart';
import 'package:desarrollo/controlador/controlador_busqueda_abogados.dart';
import 'package:desarrollo/controlador/controlador_dictado_lexus.dart';
import 'package:desarrollo/controlador/controlador_lexus.dart';
import 'package:desarrollo/controlador/controlador_perfil_abogado.dart';
import 'package:desarrollo/controlador/controlador_pqrs.dart';
import 'package:desarrollo/controlador/servicio_firestore.dart';
import 'package:desarrollo/controlador/servicio_perfil_publico.dart';
import 'package:desarrollo/controlador/servicio_resenas.dart';
import 'package:desarrollo/modelo/modelo_abogado.dart';
import 'package:desarrollo/modelo/modelo_documento_abogado.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/modelo/modelo_perfil_publico_abogado.dart';
import 'package:desarrollo/modelo/modelo_recorrido.dart';
import 'package:desarrollo/modelo/modelo_resena.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:desarrollo/vista/abogado/seccion_mi_perfil.dart';
import 'package:desarrollo/vista/abogado/seccion_panel.dart';
import 'package:desarrollo/vista/cliente/seccion_como_funciona.dart';
import 'package:desarrollo/vista/cliente/seccion_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/como_funciona/estilos_como_funciona.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/estilos_lexus.dart';
import 'package:desarrollo/vista/compartido/barra_superior_post_login.dart';
import 'package:desarrollo/vista/compartido/plantilla_post_login.dart';
import 'package:desarrollo/vista/compartido/seccion_pqrs.dart';
import 'package:desarrollo/vista/compartido/widgets/buscador_abogados.dart';
import 'package:desarrollo/vista/compartido/widgets/pqrs/estilos_pqrs.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/ambito_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/estilos_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/pintor_foco_recorrido.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/recorridos_por_seccion.dart';
import 'package:desarrollo/vista/compartido/widgets/recorrido/tarjeta_paso_recorrido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'dobles_como_funciona.dart';
import 'dobles_dictado_lexus.dart';
import 'dobles_lexus.dart';
import 'dobles_pqrs.dart';
import 'dobles_recorrido.dart';

// =============================================================================
// Bancos de prueba de los paneles con sus recorridos por sección. Arman lo
// mismo que `PanelCliente` y `PanelAbogado` (que leen FirebaseAuth y
// Firestore directamente), con las secciones reales sobre servicios falsos.
// =============================================================================

const Size tamanoTelefono = Size(390, 844);
const Size tamanoEscritorio = Size(1440, 900);

/// Pone todas las tipografías en la del tema: en las pruebas no hay red.
void usarTipografiaDePrueba() {
  BuscadorAbogados.usarTipografiaDeMarca = false;
  EstilosRecorrido.usarTipografiaDeMarca = false;
  EstilosLexus.usarTipografiaDeMarca = false;
  EstilosComoFunciona.usarTipografiaDeMarca = false;
  EstilosPqrs.usarTipografiaDeMarca = false;
}

void restaurarTipografia() {
  BuscadorAbogados.usarTipografiaDeMarca = true;
  EstilosRecorrido.usarTipografiaDeMarca = true;
}

void fijarVentana(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Lo que se espera de la pantalla de Inicio sin el video introductorio (que
/// necesita la plataforma de video): el buscador real bajo un encabezado.
class InicioDePrueba extends StatelessWidget {
  const InicioDePrueba({
    super.key,
    required this.esEscritorio,
    required this.servicio,
  });

  final bool esEscritorio;
  final PerfilPublicoFalso servicio;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 400),
            BuscadorAbogados(
              esEscritorio: esEscritorio,
              crearControlador: () =>
                  ControladorBusquedaAbogados(servicioPerfilPublico: servicio),
            ),
            const SizedBox(height: 300),
          ],
        ),
      ),
    );
  }
}

/// Dos abogados verificados, con una ubicación corta: la fuente de las
/// pruebas dibuja cada letra del ancho de su altura.
PerfilPublicoFalso abogadosDePrueba() {
  return PerfilPublicoFalso([
    perfilDePrueba(
      uid: 'a1',
      nombreCompleto: 'Ana Prueba',
      ubicacion: UbicacionCali.jamundi,
    ),
    perfilDePrueba(
      uid: 'a2',
      nombreCompleto: 'Beto Prueba',
      ubicacion: UbicacionCali.jamundi,
    ),
  ]);
}

/// Panel del cliente: Inicio, Cómo funciona, Lexus y PQRS.
class BancoPanelCliente {
  static const String uid = 'uid-cliente';

  final AlmacenMemoria almacen = AlmacenMemoria();
  final PerfilPublicoFalso abogados = abogadosDePrueba();
  final PqrsFalso pqrs = PqrsFalso();
  final StorageFalso storage = StorageFalso();
  final ServicioLexusDoble lexus = ServicioLexusDoble();
  final ServicioConversacionesLexusDoble historial =
      ServicioConversacionesLexusDoble();
  final BuscadorAbogadosFalso abogadosLexus = BuscadorAbogadosFalso();
  final RelojFalso reloj = RelojFalso();
  final GrabacionAudioFalsa grabadora = GrabacionAudioFalsa();
  final TranscriptorFalso transcriptor = TranscriptorFalso();
  final RelojDictadoFalso relojDictado = RelojDictadoFalso();

  /// Como en el panel real: conservan el estado al cruzar los 900 px.
  final GlobalKey claveComoFunciona = GlobalKey();
  final GlobalKey claveLexus = GlobalKey();

  static const List<ModeloRecorrido> recorridos = [
    ConfiguracionRecorridoCliente.inicio,
    ConfiguracionRecorridoCliente.comoFunciona,
    ConfiguracionRecorridoCliente.lexus,
    ConfiguracionRecorridoPqrs.pqrs,
  ];

  static const List<DestinoNavegacion> destinos = [
    (Icons.home_outlined, 'Inicio'),
    (Icons.help_outline, 'Cómo funciona'),
    (Icons.gavel_outlined, 'Lexus'),
    (Icons.support_agent, 'PQRS'),
  ];

  /// Marca [recorrido] como ya visto por el cliente en este dispositivo.
  void yaVisto(ModeloRecorrido recorrido) {
    almacen.datos['${recorrido.prefijoClave}$uid'] = 'completado';
  }

  String? estadoGuardado(ModeloRecorrido recorrido) =>
      almacen.datos['${recorrido.prefijoClave}$uid'];

  Widget construir() {
    return MaterialApp(
      home: RecorridosPorSeccion(
        recorridos: recorridos,
        obtenerUid: () => uid,
        almacen: almacen,
        constructor: (alCambiarSeccion) => PlantillaPostLogin(
          destinos: destinos,
          nombre: 'Ana',
          alCambiarSeccion: alCambiarSeccion,
          construirSecciones: (esEscritorio) => [
            InicioDePrueba(esEscritorio: esEscritorio, servicio: abogados),
            SeccionComoFunciona(
              key: claveComoFunciona,
              crearControlador: controladorDePrueba,
            ),
            SeccionLexus(
              key: claveLexus,
              crearControlador: () => ControladorLexus(
                servicio: lexus,
                conversaciones: historial,
                buscarAbogados: abogadosLexus.buscar,
                haySesion: () => true,
                ahora: () {
                  reloj.avanzar();
                  return reloj.ahora;
                },
              ),
              crearDictado: (alTranscribir) => ControladorDictadoLexus(
                alTranscribir: alTranscribir,
                grabadora: grabadora,
                transcriptor: transcriptor,
                ahora: relojDictado.call,
                crearTemporizador: relojDictado.crearTemporizador,
              ),
            ),
            SeccionPqrs(
              crearControlador: () => ControladorPqrs(
                servicioPqrs: pqrs,
                servicioStorage: storage,
                obtenerUid: () => uid,
                obtenerCorreo: () => 'cliente@ejemplo.com',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void cerrar() => pqrs.flujo.close();
}

/// Firestore falso del perfil del abogado. Con [retener], la carga espera.
class FirestorePerfilFalso implements ServicioFirestore {
  FirestorePerfilFalso(this.abogado);

  final ModeloAbogado abogado;
  Completer<void>? retener;

  @override
  Future<ModeloAbogado?> obtenerAbogado(String uid) async {
    await retener?.future;
    return abogado;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// El perfil público del propio abogado, ya creado.
class PerfilPublicoPropioFalso implements ServicioPerfilPublico {
  @override
  Future<ModeloPerfilPublicoAbogado?> obtener(String uid) async =>
      perfilDePrueba(uid: uid, nombreCompleto: 'Laura Prueba');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ResenasFalsas implements ServicioResenas {
  @override
  Future<List<ModeloResena>> obtenerDeAbogado(String abogadoUid) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Datos obviamente inventados, solo para pruebas.
ModeloAbogado abogadoPropioDePrueba() {
  return ModeloAbogado(
    uid: BancoPanelAbogado.uid,
    nombre: 'Laura',
    apellido: 'Prueba',
    fechaNacimiento: DateTime(1990, 6, 15),
    telefono: '+573001112233',
    correo: 'laura@ejemplo.com',
    telefonoProfesional: '+573004445566',
    especialidad: EspecialidadAbogado.civil,
    aniosExperiencia: 7,
    descripcion: 'Abogada de prueba.',
    fotoPerfilRuta: '',
    documentos: const ModeloDocumentoAbogado(
      cedulaRuta: 'abogados/uid-abogado/documentos/cedula',
      tarjetaProfesionalRuta: 'abogados/uid-abogado/documentos/tarjeta',
      certificadoRnaRuta: 'abogados/uid-abogado/documentos/rna',
      antecedentesRuta: 'abogados/uid-abogado/documentos/antecedentes',
    ),
    estado: 'verificado',
    ubicacionGeneral: UbicacionCali.jamundi,
    correoContacto: 'contacto@ejemplo.com',
  );
}

/// Panel del abogado: Inicio, Mi perfil, Panel y PQRS, con el perfil real
/// ([ControladorPerfilAbogado]) sobre servicios falsos.
class BancoPanelAbogado {
  BancoPanelAbogado() {
    perfil = ControladorPerfilAbogado(
      servicioFirestore: firestore,
      servicioPerfilPublico: PerfilPublicoPropioFalso(),
      servicioResenas: ResenasFalsas(),
      servicioStorage: storage,
    );
  }

  static const String uid = 'uid-abogado';

  final AlmacenMemoria almacen = AlmacenMemoria();
  final PerfilPublicoFalso abogados = abogadosDePrueba();
  final FirestorePerfilFalso firestore = FirestorePerfilFalso(
    abogadoPropioDePrueba(),
  );
  final PqrsFalso pqrs = PqrsFalso();
  final StorageFalso storage = StorageFalso();
  late final ControladorPerfilAbogado perfil;

  static const List<ModeloRecorrido> recorridos = [
    ConfiguracionRecorridoAbogado.inicio,
    ConfiguracionRecorridoAbogado.miPerfil,
    ConfiguracionRecorridoAbogado.panel,
    ConfiguracionRecorridoPqrs.pqrs,
  ];

  static const List<DestinoNavegacion> destinos = [
    (Icons.home_outlined, 'Inicio'),
    (Icons.badge_outlined, 'Mi perfil'),
    (Icons.dashboard_outlined, 'Panel'),
    (Icons.support_agent, 'PQRS'),
  ];

  void yaVisto(ModeloRecorrido recorrido) {
    almacen.datos['${recorrido.prefijoClave}$uid'] = 'completado';
  }

  String? estadoGuardado(ModeloRecorrido recorrido) =>
      almacen.datos['${recorrido.prefijoClave}$uid'];

  /// Como `PanelAbogado`: el Provider del perfil por fuera y el recorrido por
  /// fuera del `ListenableBuilder` que reconstruye la plantilla.
  Widget construir() {
    return MaterialApp(
      home: ChangeNotifierProvider<ControladorPerfilAbogado>.value(
        value: perfil,
        child: RecorridosPorSeccion(
          recorridos: recorridos,
          obtenerUid: () => uid,
          almacen: almacen,
          constructor: (alCambiarSeccion) => ListenableBuilder(
            listenable: perfil,
            builder: (context, _) => PlantillaPostLogin(
              destinos: destinos,
              nombre: 'Laura',
              alCambiarSeccion: alCambiarSeccion,
              construirSecciones: (esEscritorio) => [
                InicioDePrueba(esEscritorio: esEscritorio, servicio: abogados),
                SeccionMiPerfil(esEscritorio: esEscritorio),
                SeccionPanel(esEscritorio: esEscritorio),
                SeccionPqrs(
                  crearControlador: () => ControladorPqrs(
                    servicioPqrs: pqrs,
                    servicioStorage: storage,
                    obtenerUid: () => uid,
                    obtenerCorreo: () => 'laura@ejemplo.com',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void cerrar() {
    pqrs.flujo.close();
    perfil.dispose();
  }
}

// =============================================================================
// Ayudas para recorrer la interfaz.
// =============================================================================

/// Avanza [cuadros] cuadros de 100 ms. No usa `pumpAndSettle`: los
/// indicadores de carga animan sin fin.
Future<void> avanzar(WidgetTester tester, {int cuadros = 12}) async {
  await tester.pump();
  for (var i = 0; i < cuadros; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Los `MarcaRecorrido` con [id] que hay en el árbol.
Finder marcasDe(MarcaRecorridoId id) {
  return find.byWidgetPredicate((w) => w is MarcaRecorrido && w.id == id);
}

/// El destino [etiqueta] de la navegación que se esté mostrando (barra
/// inferior en teléfonos, barra superior en escritorio).
Finder destinoNavegacion(String etiqueta) {
  final movil = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(etiqueta),
  );
  if (movil.evaluate().isNotEmpty) return movil;
  return find.descendant(
    of: find.byType(BarraSuperiorPostLogin),
    matching: find.text(etiqueta),
  );
}

Future<void> irASeccion(WidgetTester tester, String etiqueta) async {
  await tester.tap(destinoNavegacion(etiqueta));
  await avanzar(tester);
}

/// [texto] dentro de la tarjeta del recorrido.
Finder enLaGuia(String texto) {
  return find.descendant(
    of: find.byType(TarjetaPasoRecorrido),
    matching: find.text(texto),
  );
}

bool hayGuia() => find.byType(TarjetaPasoRecorrido).evaluate().isNotEmpty;

Future<void> pulsarEnLaGuia(WidgetTester tester, String texto) async {
  await tester.tap(enLaGuia(texto));
  await avanzar(tester);
}

Rect? huecoActual(WidgetTester tester) {
  final pintores = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((pintura) => pintura.painter)
      .whereType<PintorFocoRecorrido>();
  return pintores.isEmpty ? null : pintores.single.hueco;
}

/// Recorre la guía que se está mostrando, de la bienvenida al cierre, y
/// comprueba que cada paso resaltado señala su elemento real. [resaltados]
/// son los ids de los pasos que deben aparecer, en orden; por defecto, todos
/// los del recorrido. [alMostrar] permite revisar algo más en cada paso.
Future<void> recorrerGuia(
  WidgetTester tester,
  ModeloRecorrido recorrido, {
  List<String>? resaltados,
  void Function(ModeloPasoRecorrido paso)? alMostrar,
}) async {
  final pasos = recorrido.pasos;
  final bienvenida = pasos.first;
  final cierre = pasos.last;
  final esperados = [
    for (final paso in pasos)
      if (paso.tipo == TipoPasoRecorrido.resaltado &&
          (resaltados == null || resaltados.contains(paso.id)))
        paso,
  ];

  expect(enLaGuia(bienvenida.titulo), findsOneWidget, reason: recorrido.id);
  expect(enLaGuia(bienvenida.descripcion), findsOneWidget);
  await pulsarEnLaGuia(tester, 'Comenzar');

  for (final (indice, paso) in esperados.indexed) {
    if (indice > 0) await pulsarEnLaGuia(tester, 'Siguiente');
    final razon = '${recorrido.id}/${paso.id}';
    expect(enLaGuia(paso.titulo), findsOneWidget, reason: razon);
    expect(
      enLaGuia('PASO ${indice + 1} DE ${esperados.length}'),
      findsOneWidget,
      reason: razon,
    );
    final marca = marcasDe(paso.marca!);
    expect(marca, findsOneWidget, reason: razon);
    final hueco = huecoActual(tester);
    expect(hueco, isNotNull, reason: razon);
    expect(
      tester
          .getRect(marca)
          .inflate(PintorFocoRecorrido.holgura + 1)
          .contains(hueco!.center),
      isTrue,
      reason: '$razon: $hueco fuera de ${tester.getRect(marca)}',
    );
    alMostrar?.call(paso);
  }

  await pulsarEnLaGuia(tester, 'Siguiente');
  expect(enLaGuia(cierre.titulo), findsOneWidget, reason: recorrido.id);
  expect(enLaGuia(cierre.descripcion), findsOneWidget);
  await pulsarEnLaGuia(tester, 'Comenzar');
  expect(hayGuia(), isFalse, reason: recorrido.id);
}

/// Ejecuta [cuerpo] aceptando solo un aviso de depuración ya conocido: en
/// escritorio, los `CheckboxListTile` del panel de filtros van dentro de un
/// contenedor blanco que tapa su fondo. Existe desde antes del recorrido y
/// solo con las aserciones activas. Cualquier otro error hace fallar.
Future<void> aceptandoSoloAvisoDeListTile(Future<void> Function() cuerpo) async {
  final errores = <FlutterErrorDetails>[];
  final original = FlutterError.onError;
  FlutterError.onError = errores.add;
  try {
    await cuerpo();
  } finally {
    FlutterError.onError = original;
  }
  for (final error in errores) {
    expect(
      error.exceptionAsString(),
      contains('ListTile background color or ink splashes may be invisible'),
    );
  }
}
