import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../configuracion/configuracion_landing.dart';
import '../../../tema/tema_app.dart';
import 'estilos_landing.dart';
import 'navegacion_landing.dart';
import 'simbolo_manolegal.dart';

/// Abre las opciones de descarga del APK: diálogo en pantallas anchas y hoja
/// inferior en móvil.
Future<void> mostrarDescargaApp(BuildContext context) {
  final ancho = MediaQuery.sizeOf(context).width;
  if (ancho >= 600) {
    return showDialog<void>(
      context: context,
      builder: (dialogo) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: ColoresApp.blanco,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ContenidoDescargaApp(
            alCerrar: () => Navigator.pop(dialogo),
            alUsarWeb: () {
              Navigator.pop(dialogo);
              NavegacionLanding.irAInicioSesion(context);
            },
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: ColoresApp.blanco,
    builder: (hoja) => ContenidoDescargaApp(
      alUsarWeb: () {
        Navigator.pop(hoja);
        NavegacionLanding.irAInicioSesion(context);
      },
    ),
  );
}

class ContenidoDescargaApp extends StatelessWidget {
  const ContenidoDescargaApp({
    super.key,
    required this.alUsarWeb,
    this.alCerrar,
  });

  final VoidCallback alUsarWeb;

  /// Si se entrega, se muestra el botón de cierre (modo diálogo).
  final VoidCallback? alCerrar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alCerrar != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Cerrar',
                onPressed: alCerrar,
                icon: const Icon(Icons.close),
              ),
            )
          else
            const SizedBox(height: 8),
          const SimboloManoLegal(tamanio: 48),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              'Descarga ManoLegal para Android',
              style: EstilosLanding.titulo(tamanio: 24, alto: 1.2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige desde dónde descargar el instalador (APK).',
            style: EstilosLanding.cuerpo(tamanio: 15),
          ),
          const SizedBox(height: 20),
          for (final opcion in ConfiguracionLanding.opcionesDescarga())
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OpcionDescarga(opcion: opcion),
            ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ColoresApp.grisClaro,
              borderRadius: BorderRadius.circular(EstilosLanding.radioM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para instalarla, abre el archivo APK en tu Android y '
                    'permite la instalación desde esa fuente cuando el '
                    'sistema lo pida.',
                    style: EstilosLanding.cuerpo(tamanio: 14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Aún no hay versión para iPhone. Puedes usar ManoLegal '
                    'desde el navegador.',
                    style: EstilosLanding.cuerpo(tamanio: 14),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: ColoresApp.azulTurqui,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: alUsarWeb,
                    child: const Text('Usar ManoLegal en la Web'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionDescarga extends StatelessWidget {
  const _OpcionDescarga({required this.opcion});

  final OpcionEnlace opcion;

  Widget _icono() {
    const color = ColoresApp.blanco;
    return switch (opcion.tipo) {
      TipoEnlace.googleDrive => const FaIcon(
        FontAwesomeIcons.googleDrive,
        size: 20,
        color: color,
      ),
      TipoEnlace.mediaFire => const Icon(
        Icons.cloud_download_outlined,
        size: 24,
        color: color,
      ),
      _ => const Icon(Icons.cloud_queue_outlined, size: 24, color: color),
    };
  }

  @override
  Widget build(BuildContext context) {
    final disponible = opcion.disponible;
    final contenido = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EstilosLanding.radioM),
        border: Border.all(color: EstilosLanding.borde),
        color: ColoresApp.blanco,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ColoresApp.azulTurqui,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: _icono()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opcion.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: ColoresApp.azulTurquiOscuro,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    disponible
                        ? 'Abrir en una pestaña nueva'
                        : 'Enlace pendiente',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: EstilosLanding.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              disponible ? Icons.open_in_new : Icons.schedule,
              size: 20,
              color: EstilosLanding.textoSuave,
            ),
          ],
        ),
      ),
    );

    if (!disponible) {
      return Semantics(
        enabled: false,
        label: '${opcion.nombre}: enlace pendiente',
        excludeSemantics: true,
        child: Opacity(opacity: 0.55, child: contenido),
      );
    }
    return Semantics(
      button: true,
      label: '${opcion.nombre}. Abrir en una pestaña nueva',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(EstilosLanding.radioM),
          onTap: () => NavegacionLanding.abrirEnlace(opcion.url),
          child: contenido,
        ),
      ),
    );
  }
}
