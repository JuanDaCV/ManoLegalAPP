import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desarrollo/configuracion/configuracion_lexus.dart';
import 'package:desarrollo/controlador/servicio_conversaciones_lexus_real.dart';
import 'package:desarrollo/modelo/error_lexus.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_conversacion_lexus.dart';
import 'package:desarrollo/modelo/modelo_mensaje_lexus.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los campos que validan las reglas de Firestore (`mensajeLexusValido` y
/// `conversacionLexusValida`). Si cambian allí, cambian aquí.
const _camposDeConversacion = {
  'titulo',
  'creadoEn',
  'actualizadoEn',
  'turnos',
  'estado',
};
const _camposObligatoriosDeMensaje = {
  'autor',
  'texto',
  'momento',
  'orden',
  'estado',
  'origen',
  'urgente',
  'enHistorialModelo',
};
const _camposDeMensaje = {
  ..._camposObligatoriosDeMensaje,
  'error',
  'areaSugerida',
  'textoParaModelo',
};

ModeloMensajeLexus _mensajeDeLexus({
  OrigenMensajeLexus origen = OrigenMensajeLexus.modelo,
  EspecialidadAbogado? area,
}) {
  return ModeloMensajeLexus(
    id: 'l1',
    autor: AutorMensajeLexus.lexus,
    texto: 'Depende del contrato.',
    momento: DateTime(2026, 1, 1),
    origen: origen,
    urgente: true,
    areaSugerida: area,
    enHistorialModelo: origen == OrigenMensajeLexus.modelo,
    textoParaModelo: '{"ambito":"juridico"}',
  );
}

void main() {
  group('mapas que se escriben (lo que validan las reglas)', () {
    test('la cabecera de una conversación nueva', () {
      final mapa = mapaCabeceraNueva('Mi empleador no me paga');

      expect(mapa.keys.toSet(), _camposDeConversacion);
      expect(mapa['titulo'], 'Mi empleador no me paga');
      expect(mapa['turnos'], 0);
      expect(mapa['estado'], 'activa');
      expect(mapa['creadoEn'], isA<FieldValue>());
      expect(mapa['actualizadoEn'], isA<FieldValue>());
    });

    test('el mensaje de la persona no guarda textoParaModelo', () {
      final mapa = mapaMensajeUsuario(texto: 'Hola', orden: 4);

      expect(mapa.keys.toSet(), _camposDeMensaje);
      expect(mapa['autor'], 'usuario');
      expect(mapa['texto'], 'Hola');
      expect(mapa['orden'], 4);
      expect(mapa['estado'], 'enviando');
      expect(mapa['origen'], 'local');
      expect(mapa['enHistorialModelo'], isFalse);
      expect(mapa['textoParaModelo'], isNull);
      expect(mapa['error'], isNull);
      expect(mapa['momento'], isA<FieldValue>());
    });

    test('el mensaje del modelo guarda el JSON crudo y el área', () {
      final mapa = mapaMensajeLexus(
        _mensajeDeLexus(area: EspecialidadAbogado.laboral),
        orden: 1,
      );

      expect(mapa.keys.toSet(), _camposDeMensaje);
      expect(mapa['autor'], 'lexus');
      expect(mapa['estado'], 'enviado');
      expect(mapa['origen'], 'modelo');
      expect(mapa['urgente'], isTrue);
      expect(mapa['areaSugerida'], 'laboral');
      expect(mapa['enHistorialModelo'], isTrue);
      expect(mapa['textoParaModelo'], '{"ambito":"juridico"}');
      expect(mapa['orden'], 1);
    });

    test('el mensaje local no guarda textoParaModelo ni área', () {
      final mapa = mapaMensajeLexus(
        _mensajeDeLexus(origen: OrigenMensajeLexus.local),
        orden: 1,
      );

      expect(mapa.keys.toSet(), _camposDeMensaje);
      expect(mapa['origen'], 'local');
      expect(mapa['enHistorialModelo'], isFalse);
      expect(mapa['textoParaModelo'], isNull);
      expect(mapa['areaSugerida'], isNull);
    });

    test('los valores de los enums coinciden con los conjuntos de las reglas', () {
      expect(AutorMensajeLexus.values.map((e) => e.name), [
        'usuario',
        'lexus',
      ]);
      expect(EstadoMensajeLexus.values.map((e) => e.name), [
        'enviando',
        'enviado',
        'fallido',
      ]);
      expect(OrigenMensajeLexus.values.map((e) => e.name), [
        'modelo',
        'local',
      ]);
      expect(EstadoConversacionLexus.values.map((e) => e.name), [
        'activa',
        'cerrada',
        'expirada',
      ]);
      // El texto de error y el área caben en los 40 caracteres que admiten.
      for (final tipo in TipoErrorLexus.values) {
        expect(tipo.name.length, lessThanOrEqualTo(40));
      }
      for (final area in EspecialidadAbogado.values) {
        expect(area.clave.length, lessThanOrEqualTo(40));
      }
    });
  });

  group('conversión de lo guardado', () {
    final ahora = DateTime.utc(2026, 3, 1, 12);

    Map<String, dynamic> datosDeMensaje({
      String autor = 'usuario',
      Object? texto = 'Hola',
      Object? orden = 0,
      Map<String, dynamic> extra = const {},
    }) {
      return {
        'autor': autor,
        'texto': texto,
        'momento': Timestamp.fromDate(ahora),
        'orden': orden,
        'estado': 'enviado',
        'origen': 'local',
        'urgente': false,
        'enHistorialModelo': false,
        ...extra,
      };
    }

    ConversacionLexusGuardada convertir(
      List<({String id, Map<String, dynamic> datos})> mensajes, {
      Map<String, dynamic>? datos,
    }) {
      return conversacionDesdeDatos(
        id: 'c1',
        datos:
            datos ??
            {
              'estado': 'activa',
              'turnos': 2,
              'actualizadoEn': Timestamp.fromDate(ahora),
            },
        mensajes: mensajes,
      );
    }

    test('lee la cabecera', () {
      final conversacion = convertir(const []);

      expect(conversacion.id, 'c1');
      expect(conversacion.estado, EstadoConversacionLexus.activa);
      expect(conversacion.turnos, 2);
      expect(conversacion.actualizadoEn!.isAtSameMomentAs(ahora), isTrue);
      expect(conversacion.mensajes, isEmpty);
    });

    test('ordena por posición y no por el orden en que llegan', () {
      final conversacion = convertir([
        (id: 'b', datos: datosDeMensaje(texto: 'segundo', orden: 1)),
        (id: 'c', datos: datosDeMensaje(texto: 'tercero', orden: 2)),
        (id: 'a', datos: datosDeMensaje(texto: 'primero', orden: 0)),
      ]);

      expect(conversacion.mensajes.map((m) => m.mensaje.texto), [
        'primero',
        'segundo',
        'tercero',
      ]);
      expect(conversacion.mensajes.map((m) => m.orden), [0, 1, 2]);
      expect(conversacion.mensajes.first.mensaje.id, 'a');
    });

    test('reconstruye el texto para el modelo de lo que escribió la persona', () {
      final conversacion = convertir([
        (
          id: 'u1',
          datos: datosDeMensaje(
            texto: 'Mi empleador no me paga',
            extra: {'enHistorialModelo': true, 'estado': 'enviado'},
          ),
        ),
        (
          id: 'u2',
          datos: datosDeMensaje(
            texto: 'Esta no pasó al modelo',
            orden: 1,
            extra: {'estado': 'fallido', 'error': 'sinConexion'},
          ),
        ),
      ]);

      final entra = conversacion.mensajes[0].mensaje;
      expect(entra.enHistorialModelo, isTrue);
      expect(entra.textoParaModelo, 'Mi empleador no me paga');
      final noEntra = conversacion.mensajes[1].mensaje;
      expect(noEntra.enHistorialModelo, isFalse);
      expect(noEntra.textoParaModelo, isNull);
      expect(noEntra.estado, EstadoMensajeLexus.fallido);
      expect(noEntra.error, TipoErrorLexus.sinConexion);
    });

    test('lee un mensaje de Lexus con su área, urgencia y JSON crudo', () {
      final conversacion = convertir([
        (
          id: 'l1',
          datos: datosDeMensaje(
            autor: 'lexus',
            texto: 'Busca ayuda ya.',
            extra: {
              'origen': 'modelo',
              'urgente': true,
              'areaSugerida': 'penal',
              'enHistorialModelo': true,
              'textoParaModelo': '{"ambito":"juridico"}',
            },
          ),
        ),
      ]);

      final lexus = conversacion.mensajes.single.mensaje;
      expect(lexus.autor, AutorMensajeLexus.lexus);
      expect(lexus.origen, OrigenMensajeLexus.modelo);
      expect(lexus.urgente, isTrue);
      expect(lexus.areaSugerida, EspecialidadAbogado.penal);
      expect(lexus.enHistorialModelo, isTrue);
      expect(lexus.textoParaModelo, '{"ambito":"juridico"}');
      expect(lexus.momento.isAtSameMomentAs(ahora), isTrue);
    });

    test('un área o un error desconocidos quedan en nulo, no en «otra»', () {
      final conversacion = convertir([
        (
          id: 'l1',
          datos: datosDeMensaje(
            autor: 'lexus',
            extra: {'areaSugerida': 'astrologia', 'error': 'inventado'},
          ),
        ),
      ]);

      final lexus = conversacion.mensajes.single.mensaje;
      expect(lexus.areaSugerida, isNull);
      expect(lexus.error, isNull);
    });

    test('omite los mensajes ilegibles sin perder los demás', () {
      final conversacion = convertir([
        (id: 'bien', datos: datosDeMensaje(texto: 'Hola')),
        (id: 'sin-texto', datos: datosDeMensaje(texto: null, orden: 1)),
        (id: 'sin-orden', datos: datosDeMensaje(orden: null)),
        (id: 'autor-raro', datos: datosDeMensaje(autor: 'otro', orden: 2)),
      ]);

      expect(conversacion.mensajes.map((m) => m.mensaje.id), ['bien']);
    });

    test('un estado desconocido nunca se retoma', () {
      final conversacion = convertir(const [], datos: {'estado': 'archivada'});

      expect(conversacion.estado, EstadoConversacionLexus.cerrada);
    });

    test('tolera una hora ausente o aún sin confirmar', () {
      final conversacion = convertir(const [], datos: {'estado': 'activa'});
      final mensaje = convertir([
        (
          id: 'a',
          datos: datosDeMensaje(extra: {'momento': null}),
        ),
      ]).mensajes.single.mensaje;

      expect(conversacion.actualizadoEn, isNull);
      expect(mensaje.momento, isA<DateTime>());
    });

    test('acota los turnos al máximo y a cero', () {
      expect(
        convertir(const [], datos: {'estado': 'activa', 'turnos': 99}).turnos,
        ConfiguracionLexus.turnosMaximos,
      );
      expect(
        convertir(const [], datos: {'estado': 'activa', 'turnos': -4}).turnos,
        0,
      );
      expect(convertir(const [], datos: {'estado': 'activa'}).turnos, 0);
    });
  });
}
