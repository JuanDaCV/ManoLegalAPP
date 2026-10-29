import 'package:flutter/material.dart';

import '../../widgets_comunes/tarjeta_cristal.dart';
import '../estilos_administrador.dart';

/// Tarjeta de métrica en vidrio, pensada para apoyarse sobre la franja
/// oscura del Inicio del administrador.
///
/// Muestra siempre un valor real. Mientras los datos cargan recibe `null` y
/// muestra un indicador de progreso: nunca un 0 provisional, que se leería
/// como un dato.
class TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final int? valor;
  final String descripcion;
  final Color colorAcento;

  /// Fracción entre 0 y 1 para una barra de proporción. Opcional.
  final double? progreso;

  final String? textoAccion;
  final VoidCallback? onAccion;

  const TarjetaMetrica({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.descripcion,
    required this.colorAcento,
    this.progreso,
    this.textoAccion,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaCristal(
      color: const Color(0x14FFFFFF),
      colorBorde: const Color(0x29FFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorAcento.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorAcento.withValues(alpha: 0.4)),
                ),
                child: Icon(icono, color: colorAcento, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EstilosAdmin.textoSobreOscuro,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (valor == null)
            const SizedBox(
              height: 46,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: EstilosAdmin.textoSobreOscuro),
                ),
              ),
            )
          else
            Text(
              '$valor',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: const TextStyle(color: EstilosAdmin.textoSecundarioSobreOscuro, fontSize: 12.5, height: 1.35),
          ),
          if (progreso != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0x1FFFFFFF),
                valueColor: AlwaysStoppedAnimation<Color>(colorAcento),
              ),
            ),
          ],
          if (textoAccion != null && onAccion != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAccion,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(textoAccion!),
              style: TextButton.styleFrom(
                // Dorado sobre azul turquí sí tiene contraste suficiente.
                foregroundColor: colorAcento,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
