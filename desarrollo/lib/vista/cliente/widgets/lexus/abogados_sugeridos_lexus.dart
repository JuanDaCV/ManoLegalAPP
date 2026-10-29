import 'package:flutter/material.dart';

import '../../../../configuracion/respuestas_locales_lexus.dart';
import '../../../../controlador/controlador_lexus.dart';
import '../../../../modelo/especialidad_abogado.dart';
import '../../../compartido/pantalla_perfil_abogado.dart';
import '../../../compartido/widgets/tarjeta_abogado.dart';
import '../../../tema/tema_app.dart';
import 'estilos_lexus.dart';

/// Abogados reales de ManoLegal para la especialidad que Lexus sugirió. Solo
/// muestra lo que devuelve el servicio de perfiles: nunca texto del modelo.
class AbogadosSugeridosLexus extends StatelessWidget {
  const AbogadosSugeridosLexus({
    super.key,
    required this.controlador,
    required this.area,
  });

  final ControladorLexus controlador;
  final EspecialidadAbogado area;

  @override
  Widget build(BuildContext context) {
    final sugerencias = controlador.sugerencias(area);
    switch (sugerencias.estado) {
      case EstadoAbogadosLexus.inicial:
        return Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => controlador.cargarAbogados(area),
            icon: const Icon(Icons.person_search_outlined),
            label: Text(RespuestasLocalesLexus.textoBotonAbogados(area)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      case EstadoAbogadosLexus.cargando:
        return Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColoresApp.azulTurqui,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscando abogados…',
                  style: EstilosLexus.cuerpo(tamanio: 13.5),
                ),
              ),
            ],
          ),
        );
      case EstadoAbogadosLexus.conResultados:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Nota(
              icono: Icons.info_outline,
              texto: RespuestasLocalesLexus.notaAbogadosSugeridos,
            ),
            for (final abogado in sugerencias.abogados) ...[
              const SizedBox(height: 10),
              TarjetaAbogado(
                abogado: abogado,
                esEscritorio: false,
                onVerPerfil: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaPerfilAbogado(uid: abogado.uid),
                  ),
                ),
              ),
            ],
          ],
        );
      case EstadoAbogadosLexus.vacio:
        return _Nota(
          icono: Icons.search_off_outlined,
          texto: RespuestasLocalesLexus.mensajeSinAbogados,
        );
      case EstadoAbogadosLexus.error:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: ColoresApp.rojoNoVerificado,
            ),
            Text(
              RespuestasLocalesLexus.mensajeErrorAbogados,
              style: EstilosLexus.cuerpo(
                tamanio: 13.5,
                color: ColoresApp.rojoNoVerificado,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.azulTurqui,
                minimumSize: const Size(48, 48),
              ),
              onPressed: () => controlador.cargarAbogados(area),
              child: const Text('Reintentar'),
            ),
          ],
        );
    }
  }
}

class _Nota extends StatelessWidget {
  const _Nota({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icono, size: 16, color: EstilosLexus.textoSobreGris),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: EstilosLexus.cuerpo(
              tamanio: 13,
              color: EstilosLexus.textoSobreGris,
            ),
          ),
        ),
      ],
    );
  }
}
