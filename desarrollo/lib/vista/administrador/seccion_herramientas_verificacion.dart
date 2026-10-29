import 'package:flutter/material.dart';

import '../tema/tema_app.dart';
import 'estilos_administrador.dart';
import 'fuentes_oficiales.dart';

/// Pestaña "Herramientas" del administrador en móvil: las dos fuentes
/// oficiales de verificación, cada una con su explicación y su botón.
///
/// En escritorio los mismos accesos viven directamente en el sidebar.
class SeccionHerramientasVerificacion extends StatelessWidget {
  const SeccionHerramientasVerificacion({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final horizontal = restricciones.maxWidth >= 600 ? 32.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Herramientas oficiales de verificación', style: EstilosAdmin.titulo(tamanio: 24)),
                  const SizedBox(height: 8),
                  const Text(
                    'Accesos directos a las plataformas oficiales para confirmar la situación profesional de un '
                    'abogado. Se abren fuera de ManoLegal: la aplicación no consulta, no automatiza y no guarda '
                    'resultados de estos sitios.',
                    style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  for (final fuente in fuentesOficialesVerificacion) ...[
                    _TarjetaFuente(fuente: fuente),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColoresApp.azulTurqui.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: ColoresApp.azulTurqui, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ambas consultas piden el número de documento del abogado. ManoLegal no lo guarda '
                            'como dato: léelo en la cédula que cargó al registrarse, desde el detalle del abogado.',
                            style: TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13.5, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaFuente extends StatelessWidget {
  final FuenteOficialVerificacion fuente;

  const _TarjetaFuente({required this.fuente});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EstilosAdmin.tarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: EstilosAdmin.degradadoMarca,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ColoresApp.dorado.withValues(alpha: 0.6)),
                ),
                child: Icon(fuente.icono, color: ColoresApp.blanco, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fuente.titulo,
                      style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(fuente.entidad, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fuente.descripcion,
            style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: ColoresApp.verdeVerificado),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fuente.dominio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => abrirFuenteOficial(context, fuente),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Abrir sitio oficial'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
          ),
        ],
      ),
    );
  }
}
