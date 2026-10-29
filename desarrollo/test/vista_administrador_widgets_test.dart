import 'package:desarrollo/controlador/filtros_administrador.dart';
import 'package:desarrollo/modelo/modelo_abogado.dart';
import 'package:desarrollo/modelo/modelo_documento_abogado.dart';
import 'package:desarrollo/vista/administrador/widgets/grafico_dona_verificacion.dart';
import 'package:desarrollo/vista/administrador/widgets/tabla_abogados.dart';
import 'package:desarrollo/vista/administrador/widgets/tarjeta_abogado_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Datos deliberadamente largos: si algo va a desbordar, es con esto.
ModeloAbogado _abogadoLargo({required String uid, String estado = 'pendiente', String? diploma}) {
  return ModeloAbogado(
    uid: uid,
    nombre: 'María Alejandra',
    apellido: 'Fernández de Castro Villegas',
    fechaNacimiento: DateTime(1988, 3, 14),
    telefono: '+573001234567',
    correo: 'maria.alejandra.fernandez.castro@consultoriojuridico.com.co',
    telefonoProfesional: '+573009876543',
    especialidad: EspecialidadAbogado.administrativo,
    aniosExperiencia: 12,
    descripcion: '',
    fotoPerfilRuta: '',
    documentos: ModeloDocumentoAbogado(
      cedulaRuta: 'abogados/$uid/documentos/cedula',
      tarjetaProfesionalRuta: 'abogados/$uid/documentos/tarjeta_profesional',
      certificadoRnaRuta: 'abogados/$uid/documentos/certificado_rna',
      diplomaRuta: diploma,
      antecedentesRuta: 'abogados/$uid/documentos/antecedentes',
    ),
    estado: estado,
  );
}

final _abogados = [
  _abogadoLargo(uid: 'Xy7kP2qLmN9rT4vB8cD1eF6gH3', estado: 'verificado', diploma: 'abogados/x/documentos/diploma'),
  _abogadoLargo(uid: 'Ab3dE5fG7hJ9kL1mN2pQ4rS6tU'),
];

/// Fija el tamaño de la ventana de prueba y lo restaura al terminar.
void _fijarVentana(WidgetTester tester, double ancho, {double alto = 1400}) {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _envolver(Widget hijo) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: hijo)));
}

void main() {
  group('gráfico de dona', () {
    testWidgets('sin abogados lo dice en lugar de dibujar una proporción', (tester) async {
      _fijarVentana(tester, 600);
      await tester.pumpWidget(_envolver(const GraficoDonaVerificacion(resumen: ResumenVerificacion(total: 0, verificados: 0))));
      await tester.pumpAndSettle();

      expect(find.text('Sin abogados\nregistrados'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('muestra cantidades y porcentajes reales en el centro y la leyenda', (tester) async {
      _fijarVentana(tester, 600);
      await tester.pumpWidget(_envolver(const GraficoDonaVerificacion(resumen: ResumenVerificacion(total: 5, verificados: 3))));
      await tester.pumpAndSettle();

      // 60 % en el centro y en la leyenda de verificados; 40 % en pendientes.
      expect(find.text('60%'), findsNWidgets(2));
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Verificados'), findsOneWidget);
      expect(find.text('No verificados'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('con la leyenda abajo cabe en un móvil angosto', (tester) async {
      _fijarVentana(tester, 320);
      await tester.pumpWidget(
        _envolver(const GraficoDonaVerificacion(resumen: ResumenVerificacion(total: 9, verificados: 4), leyendaAbajo: true)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('tabla de abogados', () {
    for (final ancho in [960.0, 1000.0, 1280.0]) {
      testWidgets('no desborda con datos largos a $ancho px', (tester) async {
        _fijarVentana(tester, ancho);
        await tester.pumpWidget(_envolver(TablaAbogados(abogados: _abogados, onVerDetalle: (_) {})));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('muestra el UID abreviado y el estado de cada abogado, sin contraseñas', (tester) async {
      _fijarVentana(tester, 1280);
      await tester.pumpWidget(_envolver(TablaAbogados(abogados: _abogados, onVerDetalle: (_) {})));

      expect(find.text('Xy7kP2qL…'), findsOneWidget);
      expect(find.text('Verificado'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.textContaining('contraseña', findRichText: true), findsNothing);
    });

    testWidgets('tocar una fila abre el detalle de ese abogado', (tester) async {
      _fijarVentana(tester, 1280);
      ModeloAbogado? elegido;
      await tester.pumpWidget(_envolver(TablaAbogados(abogados: _abogados, onVerDetalle: (a) => elegido = a)));

      await tester.tap(find.byTooltip('Ver detalle').last);
      expect(elegido?.uid, 'Ab3dE5fG7hJ9kL1mN2pQ4rS6tU');
    });
  });

  group('tarjeta de abogado para pantallas chicas', () {
    for (final ancho in [320.0, 360.0, 600.0]) {
      testWidgets('no desborda con datos largos a $ancho px', (tester) async {
        _fijarVentana(tester, ancho);
        await tester.pumpWidget(
          _envolver(Padding(
            padding: const EdgeInsets.all(16),
            child: TarjetaAbogadoAdmin(abogado: _abogados.first, onVerDetalle: () {}),
          )),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
