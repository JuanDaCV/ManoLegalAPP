import 'dart:async';
import 'dart:typed_data';

import 'package:desarrollo/controlador/controlador_pqrs.dart';
import 'package:desarrollo/controlador/servicio_storage.dart';
import 'package:desarrollo/vista/compartido/seccion_pqrs.dart';
import 'package:desarrollo/vista/compartido/widgets/pqrs/estilos_pqrs.dart';
import 'package:desarrollo/vista/compartido/widgets/pqrs/selector_evidencias_pqrs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_pqrs.dart';

void main() {
  late PqrsFalso pqrs;
  late StorageFalso storage;

  setUp(() {
    // Sin red en las pruebas: el texto usa la tipografía del tema.
    EstilosPqrs.usarTipografiaDeMarca = false;
    pqrs = PqrsFalso();
    storage = StorageFalso();
  });

  tearDown(() => pqrs.flujo.close());

  Future<void> montar(WidgetTester tester, {double ancho = 1280, double alto = 2000}) async {
    tester.view.physicalSize = Size(ancho, alto);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SeccionPqrs(
          crearControlador: () => ControladorPqrs(
            servicioPqrs: pqrs,
            servicioStorage: storage,
            obtenerUid: () => 'uidA',
            obtenerCorreo: () => 'laura@ejemplo.com',
          ),
        ),
      ),
    ));
  }

  /// Avanza lo suficiente para terminar las animaciones cortas. No usa
  /// pumpAndSettle porque la espera del radicado tiene un indicador de
  /// progreso que anima sin fin.
  Future<void> avanzar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.tap(find.text(texto));
    await avanzar(tester);
  }

  group('sección PQRS', () {
    testWidgets('al entrar muestra las 4 categorías y permite radicar', (tester) async {
      await montar(tester);

      for (final categoria in ['Peticiones', 'Quejas', 'Reclamos', 'Solicitudes']) {
        expect(find.text(categoria), findsOneWidget);
      }
      expect(find.text('Radicar una PQRS'), findsOneWidget);
      expect(find.textContaining('próximamente'), findsNothing);
    });

    testWidgets('tocar una categoría abre el formulario con ese tipo elegido', (tester) async {
      await montar(tester);

      await tocar(tester, 'Quejas');

      expect(find.text('Tipo de PQRS'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Queja'));
      expect(chip.selected, isTrue);
    });

    testWidgets('no envía sin tipo ni descripción', (tester) async {
      await montar(tester);
      await tocar(tester, 'Radicar una PQRS');

      await tocar(tester, 'Enviar PQRS');

      expect(find.text('Selecciona el tipo de PQRS.'), findsOneWidget);
      expect(find.text('Describe tu solicitud.'), findsOneWidget);
      expect(pqrs.creadas, isEmpty);
    });

    testWidgets('una descripción de solo espacios no es válida', (tester) async {
      await montar(tester);
      await tocar(tester, 'Radicar una PQRS');
      await tocar(tester, 'Petición');

      await tester.enterText(find.byType(TextFormField), '    ');
      await tocar(tester, 'Enviar PQRS');

      expect(find.text('Describe tu solicitud.'), findsOneWidget);
      expect(pqrs.creadas, isEmpty);
    });

    testWidgets('envía y muestra exactamente el radicado que escribió el backend', (tester) async {
      await montar(tester);
      await tocar(tester, 'Radicar una PQRS');
      await tocar(tester, 'Petición');
      await tester.enterText(find.byType(TextFormField), 'Necesito un certificado de mi cuenta.');

      await tocar(tester, 'Enviar PQRS');

      expect(pqrs.creadas.single.descripcion, 'Necesito un certificado de mi cuenta.');
      expect(find.text('Registrando tu PQRS…'), findsOneWidget);

      pqrs.asignarRadicado('PQ-2026-000123');
      await avanzar(tester);

      expect(find.text('Tu PQRS fue recibida correctamente'), findsOneWidget);
      expect(find.text('PQ-2026-000123'), findsOneWidget);
      expect(find.textContaining('laura@ejemplo.com'), findsOneWidget);
      expect(find.textContaining('Tipo: Petición'), findsOneWidget);
    });

    testWidgets('tocar dos veces Enviar crea una sola PQRS', (tester) async {
      pqrs.retenerCreacion = Completer<void>();
      await montar(tester);
      await tocar(tester, 'Radicar una PQRS');
      await tocar(tester, 'Petición');
      await tester.enterText(find.byType(TextFormField), 'Hola.');

      await tester.ensureVisible(find.text('Enviar PQRS'));
      await tester.tap(find.text('Enviar PQRS'));
      await tester.pump();
      // El botón muestra la carga y ya no tiene texto: el segundo toque cae
      // sobre el formulario bloqueado.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      pqrs.retenerCreacion!.complete();
      await avanzar(tester);

      expect(pqrs.creadas, hasLength(1));
    });

    testWidgets('después de la confirmación se puede radicar otra', (tester) async {
      await montar(tester);
      await tocar(tester, 'Radicar una PQRS');
      await tocar(tester, 'Queja');
      await tester.enterText(find.byType(TextFormField), 'Demora en la respuesta.');
      await tocar(tester, 'Enviar PQRS');
      pqrs.asignarRadicado('PQ-2026-000124');
      await avanzar(tester);

      await tocar(tester, 'Radicar otra PQRS');

      expect(find.text('Tipo de PQRS'), findsOneWidget);
      expect(find.text('PQ-2026-000124'), findsNothing);
    });

    for (final ancho in [360.0, 600.0, 900.0, 1280.0]) {
      testWidgets('no desborda a $ancho px', (tester) async {
        await montar(tester, ancho: ancho, alto: 900);
        expect(tester.takeException(), isNull);

        await tocar(tester, 'Radicar una PQRS');
        expect(tester.takeException(), isNull);

        await tocar(tester, 'Petición');
        await tester.enterText(find.byType(TextFormField), 'Necesito ayuda.');
        await tocar(tester, 'Enviar PQRS');
        pqrs.asignarRadicado('PQ-2026-000125');
        await avanzar(tester);
        expect(find.text('PQ-2026-000125'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('validación de evidencias', () {
    Uint8List conFirma(List<int> firma, {int relleno = 16}) => Uint8List.fromList([...firma, ...List.filled(relleno, 0)]);
    final pdf = conFirma([0x25, 0x50, 0x44, 0x46, 0x2D]);
    final png = conFirma([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final jpeg = conFirma([0xFF, 0xD8, 0xFF, 0xE0]);

    test('acepta PDF, PNG y JPG y toma el tipo de su contenido real', () {
      expect(validarArchivoEvidencia('factura.pdf', pdf).archivo!.tipoContenido, 'application/pdf');
      expect(validarArchivoEvidencia('captura.PNG', png).archivo!.tipoContenido, 'image/png');
      expect(validarArchivoEvidencia('foto.jpg', jpeg).archivo!.tipoContenido, 'image/jpeg');
      expect(validarArchivoEvidencia('foto.jpeg', jpeg).archivo!.tipoContenido, 'image/jpeg');
    });

    test('rechaza otras extensiones', () {
      expect(validarArchivoEvidencia('notas.txt', pdf).error, 'Solo se aceptan archivos PDF, PNG o JPG.');
      expect(validarArchivoEvidencia('sin_extension', pdf).error, isNotNull);
    });

    test('rechaza un archivo que no es lo que dice su extensión', () {
      final falso = Uint8List.fromList(List.filled(32, 7));
      expect(validarArchivoEvidencia('falso.pdf', falso).error, 'El archivo no es un PDF o una imagen PNG/JPG válida.');
    });

    test('rechaza un archivo vacío', () {
      expect(validarArchivoEvidencia('vacio.pdf', Uint8List(0)).error, 'El archivo está vacío.');
    });

    test('rechaza un archivo de más de 10 MB', () {
      final grande = conFirma([0x25, 0x50, 0x44, 0x46, 0x2D], relleno: ServicioStorage.tamanioMaximoDocumentoBytes);
      expect(validarArchivoEvidencia('grande.pdf', grande).error, 'El archivo supera el máximo de 10 MB.');
    });
  });
}
