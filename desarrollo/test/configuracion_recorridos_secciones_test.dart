import 'package:desarrollo/configuracion/configuracion_recorrido_abogado.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_cliente.dart';
import 'package:desarrollo/configuracion/configuracion_recorrido_pqrs.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/modelo/modelo_recorrido.dart';
import 'package:flutter_test/flutter_test.dart';

const List<ModeloRecorrido> _recorridos = [
  ConfiguracionRecorridoCliente.inicio,
  ConfiguracionRecorridoCliente.comoFunciona,
  ConfiguracionRecorridoCliente.lexus,
  ConfiguracionRecorridoPqrs.pqrs,
  ConfiguracionRecorridoAbogado.inicio,
  ConfiguracionRecorridoAbogado.miPerfil,
  ConfiguracionRecorridoAbogado.panel,
];

List<String> _textos(ModeloPasoRecorrido p) => [
  p.titulo,
  p.descripcion,
  ?p.descripcionMovil,
  ?p.descripcionSinMarca,
];

void main() {
  test('el recorrido de Inicio del cliente no cambió', () {
    const inicio = ConfiguracionRecorridoCliente.inicio;
    expect(identical(inicio.pasos, ConfiguracionRecorridoCliente.pasos), isTrue);
    expect(inicio.prefijoClave, 'manolegal.recorrido.cliente.v1.');
    expect(inicio.marcaInicial, MarcaRecorridoId.buscador);
    expect(inicio.marcaCargando, MarcaRecorridoId.cargandoResultados);
    expect(inicio.esperaInicial, const Duration(seconds: 8));
    expect(inicio.esperaCarga, const Duration(seconds: 5));
    // La regla de «Ver perfil» ahora es un dato del paso, no del motor.
    final verPerfil = inicio.pasos.firstWhere((p) => p.id == 'verPerfil');
    expect(verPerfil.requiereMarca, MarcaRecorridoId.tarjeta);
    expect(
      inicio.pasos.where((p) => p.requiereMarca != null).map((p) => p.id),
      ['verPerfil'],
    );
  });

  for (final recorrido in _recorridos) {
    group(recorrido.id, () {
      final pasos = recorrido.pasos;

      test('empieza con bienvenida, termina con cierre y en medio solo señala', () {
        expect(pasos.first.tipo, TipoPasoRecorrido.bienvenida);
        expect(pasos.last.tipo, TipoPasoRecorrido.cierre);
        final medio = pasos.sublist(1, pasos.length - 1);
        expect(medio, isNotEmpty);
        for (final paso in medio) {
          expect(paso.tipo, TipoPasoRecorrido.resaltado, reason: paso.id);
          expect(paso.marca, isNotNull, reason: paso.id);
        }
        expect(pasos.first.marca, isNull);
        expect(pasos.last.marca, isNull);
        expect(pasos.map((p) => p.id).toSet(), hasLength(pasos.length));
        expect(
          pasos.map((p) => p.marca).whereType<MarcaRecorridoId>().toSet(),
          hasLength(pasos.length - 2),
        );
      });

      test('no señala sus indicadores de carga', () {
        final marcas = pasos.map((p) => p.marca).whereType<MarcaRecorridoId>();
        final cargando = recorrido.marcaCargando;
        if (cargando != null) expect(marcas, isNot(contains(cargando)));
        expect(marcas, isNot(contains(MarcaRecorridoId.cargandoResultados)));
        expect(marcas, isNot(contains(MarcaRecorridoId.lexusCargando)));
      });

      test('los textos son breves, usan «tú» y no hablan de estadísticas', () {
        const voseo = {
          'tenés',
          'querés',
          'podés',
          'sabés',
          'elegí',
          'buscá',
          'tocá',
          'mirá',
          'hacé',
          'usá',
          'vos',
          'escribí',
          'contá',
        };
        for (final paso in pasos) {
          for (final texto in _textos(paso)) {
            final palabras = texto
                .toLowerCase()
                .split(RegExp(r'[^\wáéíóúüñ]+'))
                .toSet();
            expect(palabras.intersection(voseo), isEmpty, reason: texto);
            expect(texto.toLowerCase(), isNot(contains('estadístic')));
            expect(texto.length, lessThanOrEqualTo(200), reason: texto);
          }
        }
      });
    });
  }

  test('la guía del Panel dice que las tarjetas de demostración no son cifras reales', () {
    final paso = ConfiguracionRecorridoAbogado.pasosPanel.firstWhere(
      (p) => p.marca == MarcaRecorridoId.panelDemostracion,
    );
    for (final texto in [
      'Dato de demostración',
      'Visualizaciones del perfil',
      'Solicitudes recibidas',
      'Contactos',
      'no muestran cifras reales',
    ]) {
      expect(paso.descripcion, contains(texto));
    }
  });

  test('Mi perfil y Panel esperan más que las secciones inmediatas', () {
    for (final recorrido in [
      ConfiguracionRecorridoAbogado.miPerfil,
      ConfiguracionRecorridoAbogado.panel,
      ConfiguracionRecorridoCliente.lexus,
    ]) {
      expect(
        recorrido.esperaInicial,
        greaterThanOrEqualTo(const Duration(seconds: 15)),
        reason: recorrido.id,
      );
    }
  });

  test('sin resultados, la guía de Inicio del abogado no deja pasos vacíos', () {
    final pasos = ConfiguracionRecorridoAbogado.pasosInicio;
    ModeloPasoRecorrido paso(String id) => pasos.firstWhere((p) => p.id == id);
    expect(paso('tarjeta').siFaltaMarca, SiFaltaMarca.omitir);
    expect(paso('verPerfil').requiereMarca, MarcaRecorridoId.tarjeta);
    expect(paso('verificacion').siFaltaMarca, SiFaltaMarca.centrar);
    expect(paso('verificacion').descripcionSinMarca, isNotNull);
  });
}
