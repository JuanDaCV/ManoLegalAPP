import 'package:desarrollo/controlador/controlador_busqueda_abogados.dart';
import 'package:desarrollo/controlador/servicio_perfil_publico.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_perfil_publico_abogado.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';
import 'package:desarrollo/vista/compartido/widgets/panel_filtros.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PerfilPublicoFalso implements ServicioPerfilPublico {
  final busquedas = <({bool soloVerificados, double calificacionMinima, List<EspecialidadAbogado> especialidades})>[];

  @override
  Future<List<ModeloPerfilPublicoAbogado>> buscar({
    bool soloVerificados = true,
    double calificacionMinima = 0,
    List<EspecialidadAbogado> especialidades = const [],
    int limite = 100,
  }) async {
    busquedas.add((
      soloVerificados: soloVerificados,
      calificacionMinima: calificacionMinima,
      especialidades: especialidades,
    ));
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('"Limpiar filtros" avisa una sola vez y no pasa por los callbacks de cada filtro', (tester) async {
    var limpiezas = 0;
    var cambiosIndividuales = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PanelFiltros(
            especialidadesSeleccionadas: [EspecialidadAbogado.values.first],
            onEspecialidadesSeleccionadasChanged: (_) => cambiosIndividuales++,
            ubicacionesSeleccionadas: [UbicacionCali.values.first],
            onUbicacionesSeleccionadasChanged: (_) => cambiosIndividuales++,
            calificacionMinima: 3,
            onCalificacionMinimaChanged: (_) => cambiosIndividuales++,
            soloVerificados: false,
            onSoloVerificadosChanged: (_) => cambiosIndividuales++,
            onLimpiarFiltros: () => limpiezas++,
          ),
        ),
      ),
    ));

    await tester.ensureVisible(find.text('Limpiar filtros'));
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pump();

    expect(limpiezas, 1);
    expect(cambiosIndividuales, 0);
  });

  test('limpiarFiltros() deja los valores por defecto y hace una sola búsqueda con ellos', () async {
    final servicio = _PerfilPublicoFalso();
    final controlador = ControladorBusquedaAbogados(servicioPerfilPublico: servicio)
      ..especialidades = [EspecialidadAbogado.values.first]
      ..ubicaciones = [UbicacionCali.values.first]
      ..calificacionMinima = 3
      ..soloVerificados = false;
    addTearDown(controlador.dispose);

    controlador.limpiarFiltros();
    await Future<void>.delayed(Duration.zero);

    expect(servicio.busquedas, hasLength(1));
    final busqueda = servicio.busquedas.single;
    expect(busqueda.soloVerificados, isTrue);
    expect(busqueda.calificacionMinima, 0);
    expect(busqueda.especialidades, isEmpty);

    expect(controlador.especialidades, isEmpty);
    expect(controlador.ubicaciones, isEmpty);
    expect(controlador.calificacionMinima, 0);
    expect(controlador.soloVerificados, isTrue);
  });
}
