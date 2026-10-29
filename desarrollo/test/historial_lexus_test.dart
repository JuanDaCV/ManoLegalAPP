import 'package:desarrollo/configuracion/configuracion_lexus.dart';
import 'package:desarrollo/controlador/historial_lexus.dart';
import 'package:desarrollo/modelo/modelo_conversacion_lexus.dart';
import 'package:desarrollo/modelo/modelo_mensaje_lexus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_lexus.dart';

ModeloMensajeLexus _mensajeUsuario(String id, String texto) {
  return ModeloMensajeLexus(
    id: id,
    autor: AutorMensajeLexus.usuario,
    texto: texto,
    momento: DateTime(2026, 1, 1),
    estado: EstadoMensajeLexus.enviando,
  );
}

void main() {
  late ServicioConversacionesLexusDoble servicio;
  late int avisos;
  late HistorialLexus historial;

  setUp(() {
    servicio = ServicioConversacionesLexusDoble();
    avisos = 0;
    historial = HistorialLexus(
      servicio: servicio,
      alQuedarNoDisponible: () => avisos++,
    );
  });

  test('el título se recorta al largo máximo y termina en «…»', () async {
    final largo = 'a' * (ConfiguracionLexus.largoMaximoTitulo + 40);

    historial.guardarEnvio(_mensajeUsuario('u1', largo));
    await Future<void>.delayed(Duration.zero);

    final titulo = servicio.conversaciones.values.single.titulo!;
    expect(ConfiguracionLexus.largoMaximoTitulo, 60);
    expect(titulo, '${'a' * 60}…');
  });

  test('retoma dentro de las 48 h y no retoma pasado ese plazo', () async {
    final ahora = DateTime(2026, 3, 10, 12);
    final vigente = conversacionGuardadaDePrueba(
      id: 'vigente',
      turnos: 1,
      actualizadoEn: ahora.subtract(const Duration(hours: 47)),
      mensajes: intercambioGuardado(0, pregunta: 'Hola', respuesta: 'Buenas'),
    );
    final retomada = historial.retomar(vigente, ahora);
    expect(retomada, isNotNull);
    expect(retomada!.turnos, 1);
    expect(retomada.mensajes.map((m) => m.id), ['u0', 'l0']);

    final otro = HistorialLexus(
      servicio: servicio,
      alQuedarNoDisponible: () {},
    );
    final vencida = conversacionGuardadaDePrueba(
      id: 'vencida',
      actualizadoEn: ahora.subtract(const Duration(hours: 49)),
      mensajes: intercambioGuardado(0, pregunta: 'Hola', respuesta: 'Buenas'),
    );
    servicio.guardada = vencida;
    expect(otro.retomar(vencida, ahora), isNull);
    expect(servicio.llamadasDe('expirar'), isEmpty);

    otro.guardarEnvio(_mensajeUsuario('u9', 'Nueva consulta'));
    await Future<void>.delayed(Duration.zero);

    expect(servicio.llamadasDe('expirar').single.conversacionId, 'vencida');
    expect(
      servicio.conversaciones['vencida']!.estado,
      EstadoConversacionLexus.expirada,
    );
  });

  test('el primer fallo apaga el guardado y avisa una sola vez', () async {
    servicio.fallar = true;

    historial.guardarEnvio(_mensajeUsuario('u1', 'Primera'));
    historial.guardarEnvio(_mensajeUsuario('u2', 'Segunda'));
    await Future<void>.delayed(Duration.zero);

    expect(historial.noDisponible, isTrue);
    expect(avisos, 1);

    final llamadasAntes = servicio.llamadas.length;
    historial.guardarEnvio(_mensajeUsuario('u3', 'Tercera'));
    historial.reiniciar();
    await Future<void>.delayed(Duration.zero);

    expect(servicio.llamadas.length, llamadasAntes);
    expect(historial.nuevoIdMensaje(), isNull);
    expect(avisos, 1);
  });

  test('reiniciar cierra la conversación guardada', () async {
    historial.guardarEnvio(_mensajeUsuario('u1', 'Hola'));
    await Future<void>.delayed(Duration.zero);

    historial.reiniciar();
    await Future<void>.delayed(Duration.zero);

    final conversacion = servicio.conversaciones.values.single;
    expect(conversacion.estado, EstadoConversacionLexus.cerrada);
    expect(
      servicio.llamadasDe('cerrar').single.conversacionId,
      conversacion.id,
    );
  });

  test('un reintento reutiliza el documento ya guardado', () async {
    historial.guardarEnvio(_mensajeUsuario('u1', 'Hola'));
    historial.guardarEnvio(_mensajeUsuario('u1', 'Hola'));
    await Future<void>.delayed(Duration.zero);

    expect(servicio.nombres, ['guardarEnvio:nueva', 'guardarReintento']);
    final conversacion = servicio.conversaciones.values.single;
    expect(conversacion.mensajes.keys, ['u1']);
    expect(conversacion.mensajes['u1']!.orden, 1);
  });
}
