import 'package:desarrollo/configuracion/arranque_firebase.dart';
import 'package:desarrollo/configuracion/respuestas_locales_lexus.dart';
import 'package:desarrollo/controlador/controlador_autenticacion.dart';
import 'package:desarrollo/controlador/controlador_busqueda_abogados.dart';
import 'package:desarrollo/controlador/controlador_lexus.dart';
import 'package:desarrollo/controlador/servicio_conversaciones_lexus_visitante.dart';
import 'package:desarrollo/controlador/servicio_google.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/vista/autenticacion/pantalla_inicio_sesion.dart';
import 'package:desarrollo/vista/autenticacion/widgets/landing/navegacion_landing.dart';
import 'package:desarrollo/vista/cliente/seccion_como_funciona.dart';
import 'package:desarrollo/vista/cliente/seccion_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/boton_enviar_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/encabezado_lexus.dart';
import 'package:desarrollo/vista/cliente/widgets/lexus/indicador_escribiendo_lexus.dart';
import 'package:desarrollo/vista/compartido/pantalla_perfil_abogado.dart';
import 'package:desarrollo/vista/compartido/seccion_inicio.dart';
import 'package:desarrollo/vista/compartido/seccion_pqrs.dart';
import 'package:desarrollo/vista/compartido/widgets/buscador_abogados.dart';
import 'package:desarrollo/vista/compartido/widgets/tarjeta_abogado.dart';
import 'package:desarrollo/vista/visitante/aviso_requiere_cuenta.dart';
import 'package:desarrollo/vista/visitante/panel_visitante.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'dobles_lexus.dart';
import 'dobles_onboarding_secciones.dart';
import 'dobles_pqrs.dart';
import 'dobles_visitante.dart';

/// Registra cada ruta empujada, para comprobar qué se abrió.
class _ObservadorDeRutas extends NavigatorObserver {
  final List<Route<dynamic>> empujadas = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => empujadas.add(route);
}

const String _avisoHistorial = 'No se pudo guardar la conversación';

/// La aplicación de prueba, con el texto al 80 %. La fuente de las pruebas
/// dibuja cada letra tan ancha como alta, casi el doble que la tipografía
/// real: a 390 px el saludo del Inicio y la marca del `AppBar` no caben con
/// ella, aunque en la aplicación sobra espacio. Al 80 % cada texto sigue
/// ocupando más que en la aplicación.
Widget _aplicacion(Widget inicio, {NavigatorObserver? observador}) {
  return MaterialApp(
    navigatorObservers: [?observador],
    builder: (context, hijo) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.8)),
      child: hijo!,
    ),
    home: inicio,
  );
}

void main() {
  late BancoVisitante banco;
  late List<String> destinos;

  setUp(() {
    usarTipografiaDePrueba();
    banco = BancoVisitante();
    destinos = [];
    NavegacionLanding.interceptor = destinos.add;
  });

  tearDown(() async {
    NavegacionLanding.interceptor = null;
    restaurarTipografia();
    await banco.cerrar();
  });

  Future<void> montar(WidgetTester tester, Size tamano, {NavigatorObserver? observador}) async {
    fijarVentana(tester, tamano);
    await tester.pumpWidget(_aplicacion(banco.panel(), observador: observador));
    await avanzar(tester);
  }

  Future<void> tocar(WidgetTester tester, Finder objetivo) async {
    await tester.ensureVisible(objetivo);
    await tester.pump();
    await tester.tap(objetivo);
    await avanzar(tester);
  }

  /// Los textos de una tarjeta, en orden.
  List<String> textosDe(WidgetTester tester, Finder tarjeta) => [
    for (final texto in tester.widgetList<Text>(find.descendant(of: tarjeta, matching: find.byType(Text))))
      texto.data ?? texto.textSpan?.toPlainText() ?? '',
  ];

  Finder enElAviso(String texto) =>
      find.descendant(of: find.byType(AvisoRequiereCuenta), matching: find.text(texto));

  for (final (nombre, tamano) in const [('teléfono', tamanoTelefono), ('escritorio', tamanoEscritorio)]) {
    group('en $nombre', () {
      testWidgets('muestra las cuatro secciones con un saludo neutro y sin cerrar sesión', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);

          for (final destino in ['Inicio', 'Cómo funciona', 'Lexus', 'PQRS']) {
            expect(destinoNavegacion(destino), findsOneWidget, reason: destino);
          }
          expect(find.byType(SeccionInicio), findsOneWidget);
          expect(find.byType(SeccionComoFunciona, skipOffstage: false), findsOneWidget);
          expect(find.byType(SeccionLexus, skipOffstage: false), findsOneWidget);
          expect(find.byType(SeccionPqrs, skipOffstage: false), findsOneWidget);

          expect(find.text('Bienvenido a ManoLegal'), findsOneWidget);
          expect(find.textContaining('Bienvenido a ManoLegal,'), findsNothing);
          expect(find.text('Cerrar sesión'), findsNothing);
          expect(find.byTooltip('Cerrar sesión'), findsNothing);
          expect(find.byIcon(Icons.logout), findsNothing);
          expect(find.text('Ingresar'), findsOneWidget);
        });
      });

      testWidgets('«Ingresar» lleva al inicio de sesión', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);

          await tester.tap(find.text('Ingresar'));
          await avanzar(tester);

          expect(destinos, ['login']);
        });
      });

      testWidgets('el directorio usa la proyección y las mismas tarjetas que ve el cliente', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);

          expect(banco.tarjetas.busquedas, hasLength(1));
          final tarjetasVisitante = find.byType(TarjetaAbogado);
          expect(tarjetasVisitante, findsNWidgets(2));
          final textosVisitante = [
            for (var i = 0; i < 2; i++) textosDe(tester, tarjetasVisitante.at(i)),
          ];
          expect(textosVisitante[0], containsAll(['Ana Prueba', 'Derecho laboral', 'Ver perfil']));
          expect(textosVisitante[1], contains('Beto Prueba'));

          // El buscador tal como lo arma el panel del cliente, con los mismos
          // abogados.
          await tester.pumpWidget(
            _aplicacion(
              Scaffold(
                body: SingleChildScrollView(
                  child: BuscadorAbogados(
                    esEscritorio: tamano.width >= 900,
                    crearControlador: () =>
                        ControladorBusquedaAbogados(servicioPerfilPublico: TarjetasFalsas(abogadosVisitante())),
                  ),
                ),
              ),
            ),
          );
          await avanzar(tester);

          final tarjetasCliente = find.byType(TarjetaAbogado);
          expect(tarjetasCliente, findsNWidgets(2));
          expect([for (var i = 0; i < 2; i++) textosDe(tester, tarjetasCliente.at(i))], textosVisitante);
        });
      });

      testWidgets('«Ver perfil» pide una cuenta y no abre el perfil', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          final observador = _ObservadorDeRutas();
          await montar(tester, tamano, observador: observador);
          final empujadasAntes = observador.empujadas.length;

          await tocar(tester, find.text('Ver perfil').first);

          expect(find.byType(AvisoRequiereCuenta), findsOneWidget);
          expect(find.text('Conoce el perfil completo'), findsOneWidget);
          expect(
            find.text(
              'Crea tu cuenta en ManoLegal o inicia sesión para consultar la información completa de este abogado.',
            ),
            findsOneWidget,
          );
          expect(find.byType(PantallaPerfilAbogado), findsNothing);
          expect(observador.empujadas.skip(empujadasAntes).whereType<PageRoute<dynamic>>(), isEmpty);
          expect(tester.takeException(), isNull);
        });
      });

      testWidgets('desde el aviso, «Iniciar sesión» y «Crear cuenta» llevan a su pantalla', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);

          await tocar(tester, find.text('Ver perfil').first);
          await tester.tap(enElAviso('Iniciar sesión'));
          await avanzar(tester);
          expect(find.byType(AvisoRequiereCuenta), findsNothing);
          expect(destinos, ['login']);

          await tocar(tester, find.text('Ver perfil').first);
          await tester.tap(enElAviso('Crear cuenta'));
          await avanzar(tester);
          expect(find.byType(AvisoRequiereCuenta), findsNothing);
          expect(destinos, ['login', 'registro']);
        });
      });

      testWidgets('Lexus del visitante no carga historial ni envía, y conserva el texto', (tester) async {
        banco.lexusDeLaAplicacion = true;
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);
          await irASeccion(tester, 'Lexus');

          // El controlador que creó la propia sección, como en la aplicación.
          final controlador = tester.widget<EncabezadoLexus>(find.byType(EncabezadoLexus)).controlador;
          expect(controlador.cargando, isFalse);
          expect(controlador.historialNoDisponible, isFalse);
          expect(controlador.mensajes.single.texto, RespuestasLocalesLexus.saludo);
          expect(find.textContaining(_avisoHistorial), findsNothing);
          expect(find.byType(SnackBar), findsNothing);

          await tester.enterText(find.byType(TextField), 'Me despidieron sin justa causa');
          await tester.pump();
          expect(tester.widget<BotonEnviarLexus>(find.byType(BotonEnviarLexus)).habilitado, isTrue);
          await tester.tap(find.byType(BotonEnviarLexus));
          await avanzar(tester);

          expect(find.text('Conversa con Lexus'), findsOneWidget);
          expect(find.text('Crea tu cuenta o inicia sesión para enviar tu consulta a Lexus.'), findsOneWidget);
          expect(find.byType(IndicadorEscribiendoLexus), findsNothing);
          expect(controlador.mensajes, hasLength(1));
          expect(controlador.enviando, isFalse);
          expect(controlador.historialNoDisponible, isFalse);
          expect(find.textContaining(_avisoHistorial), findsNothing);

          await tester.tap(enElAviso('Continuar explorando'));
          await avanzar(tester);
          expect(find.byType(AvisoRequiereCuenta), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Me despidieron sin justa causa',
          );
        });
      });

      testWidgets('el micrófono del visitante pide una cuenta sin grabar', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);
          await irASeccion(tester, 'Lexus');

          await tester.tap(find.byTooltip('Dictar consulta'));
          await avanzar(tester);

          expect(find.text('Conversa con Lexus'), findsOneWidget);
          expect(banco.grabadora.llamadas, isEmpty);
          expect(find.byKey(const ValueKey('punto-grabacion')), findsNothing);
        });
      });

      testWidgets('PQRS: las categorías y «Radicar» piden una cuenta sin abrir el formulario', (tester) async {
        await aceptandoSoloAvisoDeListTile(() async {
          await montar(tester, tamano);
          await irASeccion(tester, 'PQRS');

          await tocar(tester, find.text('Quejas'));
          expect(find.text('Radica tu PQRS'), findsOneWidget);
          expect(
            find.text('Crea tu cuenta o inicia sesión para radicar una PQRS y recibir tu número de radicado.'),
            findsOneWidget,
          );
          await tester.tap(enElAviso('Continuar explorando'));
          await avanzar(tester);
          expect(find.text('Tipo de PQRS'), findsNothing);

          await tocar(tester, find.text('Radicar una PQRS'));
          expect(find.text('Radica tu PQRS'), findsOneWidget);
          await tester.tap(enElAviso('Continuar explorando'));
          await avanzar(tester);

          expect(find.text('Tipo de PQRS'), findsNothing);
          expect(find.text('Radicar una PQRS'), findsOneWidget);
          expect(banco.pqrs.creadas, isEmpty);
        });
      });
    });
  }

  group('en escritorio', () {
    testWidgets('«Crear cuenta» de la barra lleva al registro', (tester) async {
      await aceptandoSoloAvisoDeListTile(() async {
        await montar(tester, tamanoEscritorio);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
        await avanzar(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
        await avanzar(tester);

        expect(destinos, ['registro', 'login']);
      });
    });

    testWidgets('los filtros buscan en la proyección con la especialidad elegida', (tester) async {
      await aceptandoSoloAvisoDeListTile(() async {
        await montar(tester, tamanoEscritorio);

        await tocar(tester, find.widgetWithText(CheckboxListTile, 'Derecho laboral'));

        expect(banco.tarjetas.busquedas, hasLength(2));
        expect(banco.tarjetas.busquedas.last, [EspecialidadAbogado.laboral]);
      });
    });

    testWidgets('«Continuar explorando» cierra el aviso y conserva resultados y filtros', (tester) async {
      await aceptandoSoloAvisoDeListTile(() async {
        await montar(tester, tamanoEscritorio);
        await tocar(tester, find.widgetWithText(CheckboxListTile, 'Derecho laboral'));
        final busquedas = banco.tarjetas.busquedas.length;

        await tocar(tester, find.text('Ver perfil').first);
        expect(find.byType(AvisoRequiereCuenta), findsOneWidget);
        await tester.tap(enElAviso('Continuar explorando'));
        await avanzar(tester);

        expect(find.byType(AvisoRequiereCuenta), findsNothing);
        expect(find.byType(TarjetaAbogado), findsNWidgets(2));
        expect(
          tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Derecho laboral')).value,
          isTrue,
        );
        expect(banco.tarjetas.busquedas, hasLength(busquedas));
      });
    });

    testWidgets('«Volver» de la barra cierra el panel', (tester) async {
      await aceptandoSoloAvisoDeListTile(() async {
        fijarVentana(tester, tamanoEscritorio);
        await tester.pumpWidget(_aplicacion(_Inicio(banco: banco)));
        await tester.tap(find.text('Abrir visitante'));
        await avanzar(tester);
        expect(find.byType(PanelVisitante), findsOneWidget);

        await tester.tap(find.byTooltip('Volver'));
        await avanzar(tester);

        expect(find.byType(PanelVisitante), findsNothing);
        expect(find.text('Abrir visitante'), findsOneWidget);
      });
    });
  });

  group('en teléfono', () {
    testWidgets('los filtros de la hoja inferior también buscan en la proyección', (tester) async {
      await montar(tester, tamanoTelefono);

      await tocar(tester, find.widgetWithText(OutlinedButton, 'Filtros'));
      await tocar(tester, find.widgetWithText(CheckboxListTile, 'Derecho laboral'));

      expect(banco.tarjetas.busquedas.last, [EspecialidadAbogado.laboral]);
    });

    testWidgets('la barra superior muestra la flecha de volver del AppBar', (tester) async {
      fijarVentana(tester, tamanoTelefono);
      await tester.pumpWidget(_aplicacion(_Inicio(banco: banco)));
      await tester.tap(find.text('Abrir visitante'));
      await avanzar(tester);

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Crear cuenta'), findsNothing);
    });
  });

  group('Lexus con un servicio de prueba', () {
    testWidgets('enviar no llama al modelo ni agrega mensajes', (tester) async {
      await montar(tester, tamanoTelefono);
      await irASeccion(tester, 'Lexus');
      final controlador = banco.controladorLexus!;
      final mensajes = controlador.mensajes.length;

      await tester.enterText(find.byType(TextField), 'Tengo un problema con mi empleador');
      await tester.pump();
      await tester.tap(find.byType(BotonEnviarLexus));
      await avanzar(tester);

      expect(find.text('Conversa con Lexus'), findsOneWidget);
      expect(banco.lexus.llamadas, isEmpty);
      expect(controlador.mensajes, hasLength(mensajes));
      expect(controlador.enviando, isFalse);
      expect(controlador.historialNoDisponible, isFalse);
    });

    testWidgets('en el computador, Enter tampoco envía y conserva el texto', (tester) async {
      var avisos = 0;
      final servicio = ServicioLexusDoble();
      fijarVentana(tester, tamanoTelefono);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeccionLexus(
              crearControlador: () => ControladorLexus(
                servicio: servicio,
                conversaciones: ServicioConversacionesLexusVisitante(),
                haySesion: () => false,
              ),
              alRequerirCuenta: () => avisos++,
            ),
          ),
        ),
      );
      await avanzar(tester);

      await tester.enterText(find.byType(TextField), 'Hola Lexus');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await avanzar(tester);

      expect(avisos, 1);
      expect(servicio.llamadas, isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Hola Lexus');
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('sesión iniciada mientras se explora', () {
    Future<void> abrirDesdeInicio(WidgetTester tester) async {
      fijarVentana(tester, tamanoTelefono);
      await tester.pumpWidget(_aplicacion(_Inicio(banco: banco)));
      await tester.tap(find.text('Abrir visitante'));
      await avanzar(tester);
      expect(find.byType(PanelVisitante), findsOneWidget);
    }

    testWidgets('al aparecer un usuario, vuelve a la primera ruta', (tester) async {
      await abrirDesdeInicio(tester);

      banco.sesion.add(UsuarioFalso());
      await avanzar(tester);

      expect(find.byType(PanelVisitante), findsNothing);
      expect(find.text('Abrir visitante'), findsOneWidget);
    });

    testWidgets('también cierra un aviso abierto', (tester) async {
      await abrirDesdeInicio(tester);
      await tocar(tester, find.text('Ver perfil').first);
      expect(find.byType(AvisoRequiereCuenta), findsOneWidget);

      banco.sesion.add(UsuarioFalso());
      await avanzar(tester);

      expect(find.byType(AvisoRequiereCuenta), findsNothing);
      expect(find.byType(PanelVisitante), findsNothing);
    });

    testWidgets('sin usuario sigue explorando', (tester) async {
      await abrirDesdeInicio(tester);

      banco.sesion.add(null);
      await avanzar(tester);

      expect(find.byType(PanelVisitante), findsOneWidget);
    });

    testWidgets('con el inicio de sesión abierto encima no cierra nada; al volver de él, sí', (tester) async {
      NavegacionLanding.interceptor = null;
      ArranqueFirebase.usarEnPruebas(listo: Future<void>.value());
      addTearDown(ArranqueFirebase.reiniciarEnPruebas);
      fijarVentana(tester, tamanoTelefono);
      await tester.pumpWidget(
        ChangeNotifierProvider<ControladorAutenticacion>(
          create: (_) => ControladorAutenticacion(
            servicioFirestore: FirestoreFalso(),
            servicioStorage: StorageFalso(),
            servicioGoogle: ServicioGoogle(),
          ),
          child: _aplicacion(_Inicio(banco: banco)),
        ),
      );
      await tester.tap(find.text('Abrir visitante'));
      await avanzar(tester);

      await tester.tap(find.text('Ingresar'));
      await avanzar(tester);
      expect(find.byType(PantallaInicioSesion), findsOneWidget);

      banco.sesion.add(UsuarioFalso());
      await avanzar(tester);
      expect(find.byType(PantallaInicioSesion), findsOneWidget);
      expect(find.byType(PanelVisitante, skipOffstage: false), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await avanzar(tester);

      expect(find.byType(PantallaInicioSesion), findsNothing);
      expect(find.byType(PanelVisitante, skipOffstage: false), findsNothing);
      expect(find.text('Abrir visitante'), findsOneWidget);
    });
  });
}

/// Primera ruta de prueba, como la landing: abre el panel del visitante
/// encima, para poder comprobar cuándo se cierra.
class _Inicio extends StatelessWidget {
  const _Inicio({required this.banco});

  final BancoVisitante banco;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => banco.panel())),
          child: const Text('Abrir visitante'),
        ),
      ),
    );
  }
}
