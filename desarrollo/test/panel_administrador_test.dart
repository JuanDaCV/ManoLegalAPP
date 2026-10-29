import 'dart:async';

import 'package:desarrollo/controlador/controlador_administrador.dart';
import 'package:desarrollo/controlador/servicio_firestore.dart';
import 'package:desarrollo/controlador/servicio_perfil_publico.dart';
import 'package:desarrollo/controlador/servicio_storage.dart';
import 'package:desarrollo/modelo/modelo_abogado.dart';
import 'package:desarrollo/modelo/modelo_documento_abogado.dart';
import 'package:desarrollo/modelo/modelo_info_archivo.dart';
import 'package:desarrollo/modelo/modelo_perfil_publico_abogado.dart';
import 'package:desarrollo/vista/administrador/detalle/detalle_abogado.dart';
import 'package:desarrollo/vista/administrador/estilos_administrador.dart';
import 'package:desarrollo/vista/administrador/seccion_herramientas_verificacion.dart';
import 'package:desarrollo/vista/administrador/seccion_inicio_administrador.dart';
import 'package:desarrollo/vista/administrador/seccion_verificacion_abogados.dart';
import 'package:desarrollo/controlador/filtros_administrador.dart';
import 'package:desarrollo/vista/administrador/widgets/tabla_abogados.dart';
import 'package:desarrollo/vista/administrador/widgets/tarjeta_abogado_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// =============================================================================
// Estas pruebas usan el ControladorAdministrador REAL, con servicios falsos que
// implementan la misma interfaz. Así se comprueba que la interfaz nueva sigue
// pasando por la lógica existente (cambiarEstado, eliminarAbogado...) sin
// necesitar Firebase. Los servicios falsos se declaran con `implements`, no
// con `extends`: extender ejecutaría `FirebaseFirestore.instance` al crearlos.
// =============================================================================

class _FirestoreFalso implements ServicioFirestore {
  final _flujo = StreamController<List<ModeloAbogado>>.broadcast();
  List<ModeloAbogado> _actuales = [];
  final llamadas = <String>[];

  /// Simula una respuesta de Firestore en tiempo real.
  void emitir(List<ModeloAbogado> lista) {
    _actuales = lista;
    _flujo.add(lista);
  }

  @override
  Stream<List<ModeloAbogado>> observarAbogados() => _flujo.stream;

  @override
  Future<void> actualizarEstadoAbogadoYPerfil(String uid, String nuevoEstado) async {
    llamadas.add('estado:$uid:$nuevoEstado');
    emitir([for (final a in _actuales) a.uid == uid ? a.copiarCon(estado: nuevoEstado) : a]);
  }

  @override
  Future<void> eliminarAbogadoCompleto(String uid) async {
    llamadas.add('eliminar:$uid');
    emitir(_actuales.where((a) => a.uid != uid).toList());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PerfilPublicoFalso implements ServicioPerfilPublico {
  @override
  Future<ModeloPerfilPublicoAbogado?> obtener(String uid) async => ModeloPerfilPublicoAbogado(
        uid: uid,
        nombreCompleto: 'Existente',
        especialidad: EspecialidadAbogado.civil,
        aniosExperiencia: 1,
        verificado: false,
        telefonoProfesional: '',
        correoContacto: '',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StorageFalso implements ServicioStorage {
  final eliminados = <String>[];

  @override
  Future<ModeloInfoArchivo?> obtenerInfoArchivo(String ruta) async => ModeloInfoArchivo(
        nombreArchivo: '${ruta.split('/').last}.pdf',
        tipoContenido: 'application/pdf',
        tamanio: 250000,
        fechaSubida: DateTime(2026, 9, 10),
      );

  @override
  Future<void> eliminarTodoDelAbogado(String uid) async => eliminados.add(uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ModeloAbogado _abogado(
  String uid,
  String nombre,
  String apellido, {
  String estado = 'pendiente',
  String correo = 'correo@ejemplo.com',
  EspecialidadAbogado especialidad = EspecialidadAbogado.civil,
}) {
  return ModeloAbogado(
    uid: uid,
    nombre: nombre,
    apellido: apellido,
    fechaNacimiento: DateTime(1990, 6, 15),
    telefono: '+573001112233',
    correo: correo,
    telefonoProfesional: '+573004445566',
    especialidad: especialidad,
    aniosExperiencia: 7,
    descripcion: 'Abogado con experiencia.',
    fotoPerfilRuta: '',
    documentos: ModeloDocumentoAbogado(
      cedulaRuta: 'abogados/$uid/documentos/cedula',
      tarjetaProfesionalRuta: 'abogados/$uid/documentos/tarjeta_profesional',
      certificadoRnaRuta: 'abogados/$uid/documentos/certificado_rna',
      antecedentesRuta: 'abogados/$uid/documentos/antecedentes',
    ),
    estado: estado,
  );
}

final _abogados = [
  _abogado('a1', 'Ana', 'Torres', estado: 'verificado'),
  _abogado('a2', 'José', 'Muñoz', correo: 'jose@ley.co'),
  _abogado('a3', 'Luis', 'Gómez', especialidad: EspecialidadAbogado.laboral),
];

class _Entorno {
  final firestore = _FirestoreFalso();
  final storage = _StorageFalso();
  late final controlador = ControladorAdministrador(
    servicioFirestore: firestore,
    servicioPerfilPublico: _PerfilPublicoFalso(),
    servicioStorage: storage,
  )..escucharAbogados();

  Widget app(Widget hijo) => ChangeNotifierProvider<ControladorAdministrador>.value(
        value: controlador,
        child: MaterialApp(home: Scaffold(body: hijo)),
      );
}

void _fijarVentana(WidgetTester tester, double ancho, {double alto = 1600}) {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => EstilosAdmin.usarTipografiaDeMarca = false);

  group('Inicio del administrador', () {
    Widget inicio({VoidCallback? onRevisar, ValueChanged<String>? onDetalle}) =>
        SeccionInicioAdministrador(onRevisarPendientes: onRevisar ?? () {}, onAbrirDetalle: onDetalle ?? (_) {});

    testWidgets('mientras carga no inventa cifras, y luego muestra las reales', (tester) async {
      _fijarVentana(tester, 1280);
      final entorno = _Entorno();
      await tester.pumpWidget(entorno.app(inicio()));
      await tester.pump();

      expect(find.text('Conectando con Firestore…'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      entorno.firestore.emitir(_abogados);
      await tester.pumpAndSettle();

      expect(find.text('Datos en tiempo real'), findsOneWidget);
      expect(find.text('33% del total'), findsOneWidget);
      // La cola de pendientes muestra solo a los no verificados.
      expect(find.text('José Muñoz'), findsOneWidget);
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text('Ana Torres'), findsNothing);
    });

    testWidgets('sin abogados lo dice en lugar de mostrar una cola vacía', (tester) async {
      _fijarVentana(tester, 1280);
      final entorno = _Entorno();
      await tester.pumpWidget(entorno.app(inicio()));
      entorno.firestore.emitir([]);
      await tester.pumpAndSettle();

      expect(find.text('No hay abogados pendientes'), findsOneWidget);
      expect(find.text('Sin abogados\nregistrados'), findsOneWidget);
    });

    testWidgets('"Revisar pendientes" y "Revisar" llevan a donde corresponde', (tester) async {
      _fijarVentana(tester, 1280);
      final entorno = _Entorno();
      var revisados = 0;
      String? detalle;
      await tester.pumpWidget(entorno.app(inicio(onRevisar: () => revisados++, onDetalle: (uid) => detalle = uid)));
      entorno.firestore.emitir(_abogados);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revisar pendientes'));
      expect(revisados, 1);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Revisar').first);
      expect(detalle, isNotNull);
    });

    for (final ancho in [360.0, 800.0, 1000.0, 1440.0]) {
      testWidgets('no desborda a $ancho px', (tester) async {
        _fijarVentana(tester, ancho);
        final entorno = _Entorno();
        await tester.pumpWidget(entorno.app(inicio()));
        entorno.firestore.emitir(_abogados);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Listado de verificación', () {
    Widget listado({ValueChanged<String>? onDetalle}) => SeccionVerificacionAbogados(
          filtroInicial: FiltroEstadoAbogado.todos,
          versionFiltro: 0,
          onAbrirDetalle: onDetalle ?? (_) {},
        );

    testWidgets('en escritorio usa la tabla, en pantallas chicas las tarjetas', (tester) async {
      _fijarVentana(tester, 1280);
      final entorno = _Entorno();
      await tester.pumpWidget(entorno.app(listado()));
      entorno.firestore.emitir(_abogados);
      await tester.pumpAndSettle();
      expect(find.byType(TablaAbogados), findsOneWidget);

      _fijarVentana(tester, 700);
      await tester.pumpAndSettle();
      expect(find.byType(TablaAbogados), findsNothing);
      expect(find.byType(TarjetaAbogadoAdmin), findsNWidgets(3));
    });

    testWidgets('busca sin tildes y filtra por estado sobre los datos del stream', (tester) async {
      _fijarVentana(tester, 1280);
      final entorno = _Entorno();
      await tester.pumpWidget(entorno.app(listado()));
      entorno.firestore.emitir(_abogados);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'munoz');
      await tester.pumpAndSettle();
      expect(find.text('Muñoz'), findsOneWidget);
      expect(find.text('Torres'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Pendientes (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Torres'), findsNothing);
      expect(find.text('Mostrando 1–2 de 2 abogados'), findsOneWidget);
    });

    testWidgets('sin coincidencias ofrece limpiar los filtros', (tester) async {
      _fijarVentana(tester, 1280);
      final entorno = _Entorno();
      await tester.pumpWidget(entorno.app(listado()));
      entorno.firestore.emitir(_abogados);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'notario inexistente');
      await tester.pumpAndSettle();
      expect(find.text('Ningún abogado coincide con la búsqueda'), findsOneWidget);

      await tester.tap(find.text('Limpiar filtros').last);
      await tester.pumpAndSettle();
      expect(find.text('Mostrando 1–3 de 3 abogados'), findsOneWidget);
    });

    testWidgets('con la colección vacía lo dice, sin datos de ejemplo', (tester) async {
      _fijarVentana(tester, 1280);
      final entorno = _Entorno();
      await tester.pumpWidget(entorno.app(listado()));
      entorno.firestore.emitir([]);
      await tester.pumpAndSettle();
      expect(find.text('Todavía no hay abogados registrados'), findsOneWidget);
    });

    for (final ancho in [360.0, 600.0, 900.0, 1000.0, 1280.0]) {
      testWidgets('no desborda a $ancho px', (tester) async {
        _fijarVentana(tester, ancho);
        final entorno = _Entorno();
        await tester.pumpWidget(entorno.app(listado()));
        entorno.firestore.emitir(_abogados);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Detalle del abogado', () {
    testWidgets('verificar pasa por cambiarEstado y el estado cambia en vivo', (tester) async {
      _fijarVentana(tester, 800);
      final entorno = _Entorno();
      await tester.pumpWidget(
        ChangeNotifierProvider<ControladorAdministrador>.value(
          value: entorno.controlador,
          child: const MaterialApp(home: DetalleAbogado(uid: 'a2', pantallaCompleta: true)),
        ),
      );
      entorno.firestore.emitir(_abogados);
      await tester.pumpAndSettle();

      // Los cuatro documentos obligatorios existen; el diploma no se cargó.
      expect(find.text('Disponible en Storage'), findsNWidgets(4));
      expect(find.text('No cargado'), findsOneWidget);

      await tester.tap(find.text('Verificar abogado'));
      await tester.pumpAndSettle();

      expect(entorno.firestore.llamadas, contains('estado:a2:verificado'));
      expect(find.text('Abogado verificado.'), findsOneWidget);
      // El detalle sigue abierto y refleja el nuevo estado por el stream.
      expect(find.text('Marcar como no verificado'), findsOneWidget);
    });

    testWidgets('eliminar pide confirmación, pasa por eliminarAbogado y devuelve el correo', (tester) async {
      _fijarVentana(tester, 800);
      final entorno = _Entorno();
      String? resultado;
      await tester.pumpWidget(
        ChangeNotifierProvider<ControladorAdministrador>.value(
          value: entorno.controlador,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      resultado = await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const DetalleAbogado(uid: 'a2', pantallaCompleta: true)),
                      );
                    },
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      entorno.firestore.emitir(_abogados);
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Eliminar cuenta'));
      await tester.tap(find.text('Eliminar cuenta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No borra su cuenta de inicio de sesión'), findsOneWidget);

      await tester.tap(find.text('Eliminar definitivamente'));
      await tester.pumpAndSettle();

      expect(entorno.firestore.llamadas, contains('eliminar:a2'));
      expect(entorno.storage.eliminados, contains('a2'));
      expect(resultado, 'jose@ley.co');
    });

    for (final (ancho, pantallaCompleta) in [(360.0, true), (600.0, false)]) {
      testWidgets('no desborda a $ancho px (${pantallaCompleta ? 'pantalla completa' : 'panel lateral'})', (tester) async {
        _fijarVentana(tester, ancho);
        final entorno = _Entorno();
        await tester.pumpWidget(
          ChangeNotifierProvider<ControladorAdministrador>.value(
            value: entorno.controlador,
            child: MaterialApp(home: DetalleAbogado(uid: 'a1', pantallaCompleta: pantallaCompleta)),
          ),
        );
        entorno.firestore.emitir(_abogados);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Herramientas oficiales', () {
    testWidgets('muestra las dos fuentes y cabe en un móvil angosto', (tester) async {
      _fijarVentana(tester, 320);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SeccionHerramientasVerificacion())));
      await tester.pumpAndSettle();

      expect(find.text('Antecedentes disciplinarios'), findsOneWidget);
      expect(find.text('Vigencia profesional'), findsOneWidget);
      expect(find.text('Abrir sitio oficial'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
