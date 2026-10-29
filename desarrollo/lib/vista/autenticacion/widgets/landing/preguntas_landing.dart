import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'revelar_al_desplazar.dart';
import 'tarjeta_landing.dart';

const List<(String, String)> _preguntas = [
  (
    '¿Qué significa que un abogado esté verificado?',
    'Que un administrador de ManoLegal revisó los documentos que el abogado '
        'subió al registrarse: cédula, tarjeta profesional, certificado de '
        'vigencia RNA/SIRNA y antecedentes disciplinarios. Es una revisión '
        'documental: no es una recomendación ni garantiza resultados.',
  ),
  (
    '¿Cuesta algo usar ManoLegal?',
    'La aplicación no tiene pagos: crear tu cuenta, buscar y contactar '
        'abogados no tiene costo dentro de ManoLegal. Los honorarios los '
        'acuerdas directamente con el abogado.',
  ),
  (
    '¿Cómo contacto a un abogado?',
    'Desde su perfil, por WhatsApp o por correo, si el abogado publicó esos '
        'datos. ManoLegal no intermedia la conversación ni el acuerdo.',
  ),
  (
    '¿Qué es Lexus?',
    'El asistente de orientación inicial con inteligencia artificial de '
        'ManoLegal. Te ayuda a entender tu situación e identificar el área '
        'del derecho, y puede mostrarte abogados verificados de esa área. No '
        'es un abogado y puede equivocarse.',
  ),
  (
    '¿Puedo usar ManoLegal en el celular?',
    'Sí: desde el navegador del celular o instalando la app para Android con '
        'el archivo APK. Por ahora no hay versión para iPhone.',
  ),
  (
    '¿Cómo me registro como abogado?',
    'Elige «Abogado» al crear tu cuenta y completa los tres pasos: datos '
        'personales, información profesional y documentos. Tu perfil quedará '
        'pendiente hasta la revisión del administrador.',
  ),
  (
    '¿Qué hago si olvido mi contraseña?',
    'En la pantalla de inicio de sesión, usa «¿Olvidaste tu contraseña?» '
        'para recibir un correo de recuperación.',
  ),
  (
    '¿Dónde envío una petición, queja o reclamo?',
    'En la sección PQRS dentro de la app, después de ingresar. Recibirás un '
        'número de radicado.',
  ),
];

/// Preguntas frecuentes en acordeón (una abierta a la vez).
class PreguntasLanding extends StatelessWidget {
  const PreguntasLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return SeccionBase(
      color: ColoresApp.blanco,
      builder: (context, t, util) {
        final esAncho = t == TamanoLanding.ancho || t == TamanoLanding.amplio;
        final encabezado = RevelarAlDesplazar(
          child: EncabezadoSeccion(
            etiqueta: 'AYUDA',
            titulo: 'Preguntas frecuentes',
            lead:
                '¿Tienes otra duda? Ingresa y escríbenos desde la sección '
                'PQRS.',
            tamano: t,
          ),
        );
        if (esAncho) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: encabezado),
              const SizedBox(width: 64),
              const Expanded(flex: 7, child: _Acordeon()),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [encabezado, const SizedBox(height: 40), const _Acordeon()],
        );
      },
    );
  }
}

class _Acordeon extends StatefulWidget {
  const _Acordeon();

  @override
  State<_Acordeon> createState() => _AcordeonState();
}

class _AcordeonState extends State<_Acordeon> {
  int _abierto = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _preguntas.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == _preguntas.length - 1 ? 0 : 12,
            ),
            child: RevelarAlDesplazar(
              child: _ItemPregunta(
                pregunta: _preguntas[i].$1,
                respuesta: _preguntas[i].$2,
                abierto: _abierto == i,
                alAlternar: () =>
                    setState(() => _abierto = _abierto == i ? -1 : i),
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemPregunta extends StatelessWidget {
  const _ItemPregunta({
    required this.pregunta,
    required this.respuesta,
    required this.abierto,
    required this.alAlternar,
  });

  final String pregunta;
  final String respuesta;
  final bool abierto;
  final VoidCallback alAlternar;

  @override
  Widget build(BuildContext context) {
    return TarjetaLanding(
      elevable: false,
      radio: 16,
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: abierto,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: alAlternar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pregunta,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: ColoresApp.azulTurquiOscuro,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: abierto ? 0.5 : 0,
                        duration: EstilosLanding.duracion(context, 220),
                        child: const Icon(
                          Icons.expand_more,
                          color: ColoresApp.azulTurqui,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _conAnimacion(
              context,
              abierto
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(
                        respuesta,
                        style: EstilosLanding.cuerpo(
                          tamanio: 15.5,
                          color: EstilosLanding.textoSuave,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Con "reducir movimiento" no se usa [AnimatedSize]: con duración cero marca
/// su propio diseño como sucio durante el layout.
Widget _conAnimacion(BuildContext context, Widget hijo) {
  if (MediaQuery.disableAnimationsOf(context)) return hijo;
  return AnimatedSize(
    duration: EstilosLanding.duracion(context, 240),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: hijo,
  );
}
