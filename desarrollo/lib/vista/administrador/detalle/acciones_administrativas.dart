import 'package:flutter/material.dart';

import '../../tema/tema_app.dart';

/// Acción administrativa en curso. Mientras hay una, todos los botones se
/// deshabilitan para evitar dobles envíos.
enum AccionAdministrativa { verificacion, regeneracion, eliminacion }

/// Barra fija inferior del detalle: la acción de verificación, regenerar el
/// perfil público y, en el panel lateral, cerrar el detalle.
///
/// Es de presentación: las acciones reales las ejecuta el detalle a través de
/// [ControladorAdministrador], con la misma lógica de siempre.
class BarraAccionesAdministrativas extends StatelessWidget {
  final bool verificado;
  final AccionAdministrativa? accionEnCurso;
  final bool deshabilitada;
  final VoidCallback onCambiarVerificacion;
  final VoidCallback onRegenerarPerfil;

  /// `null` en pantalla completa: ahí se cierra con la flecha de la barra
  /// superior.
  final VoidCallback? onCerrar;

  const BarraAccionesAdministrativas({
    super.key,
    required this.verificado,
    required this.accionEnCurso,
    required this.deshabilitada,
    required this.onCambiarVerificacion,
    required this.onRegenerarPerfil,
    this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final ocupada = deshabilitada || accionEnCurso != null;
    final verificando = accionEnCurso == AccionAdministrativa.verificacion;
    final regenerando = accionEnCurso == AccionAdministrativa.regeneracion;

    Widget progreso(Color color) =>
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color));

    final botonPrincipal = verificado
        ? OutlinedButton.icon(
            onPressed: ocupada ? null : onCambiarVerificacion,
            icon: verificando ? progreso(ColoresApp.rojoNoVerificado) : const Icon(Icons.unpublished_outlined),
            label: const Text('Marcar como no verificado'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresApp.rojoNoVerificado,
              side: BorderSide(color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.55), width: 1.5),
            ),
          )
        : ElevatedButton.icon(
            onPressed: ocupada ? null : onCambiarVerificacion,
            icon: verificando ? progreso(ColoresApp.blanco) : const Icon(Icons.verified_outlined),
            label: const Text('Verificar abogado'),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: ColoresApp.blanco,
        border: Border(top: BorderSide(color: Color(0x1F6B7280))),
        boxShadow: [BoxShadow(color: Color(0x0F0A1930), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              verificado
                  ? 'Este abogado aparece como verificado en el buscador de ManoLegal.'
                  : 'Revisa los documentos y confírmalos en las fuentes oficiales antes de verificar.',
              style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            botonPrincipal,
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Tooltip(
                    message: 'Vuelve a publicar el perfil en el buscador a partir de los datos privados. '
                        'Útil si el abogado no aparece o sus datos públicos están desactualizados.',
                    child: TextButton.icon(
                      onPressed: ocupada ? null : onRegenerarPerfil,
                      icon: regenerando ? progreso(ColoresApp.azulTurqui) : const Icon(Icons.sync_rounded, size: 20),
                      label: const Text('Regenerar perfil público', overflow: TextOverflow.ellipsis),
                      style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
                    ),
                  ),
                ),
                if (onCerrar != null) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: onCerrar,
                    style: TextButton.styleFrom(foregroundColor: ColoresApp.grisTexto),
                    child: const Text('Cerrar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque separado para eliminar la cuenta, al final del detalle, lejos de
/// las acciones de uso frecuente para evitar un borrado accidental.
class ZonaRiesgoAbogado extends StatelessWidget {
  final bool ocupada;
  final bool eliminando;
  final VoidCallback onEliminar;

  const ZonaRiesgoAbogado({super.key, required this.ocupada, required this.eliminando, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 19, color: ColoresApp.rojoNoVerificado),
              SizedBox(width: 8),
              Text(
                'Zona de riesgo',
                style: TextStyle(color: ColoresApp.rojoNoVerificado, fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Eliminar borra los datos privados del abogado en Firestore, su perfil público y sus archivos en '
            'Storage. La cuenta de inicio de sesión (Firebase Authentication) no se elimina desde la aplicación: '
            'queda pendiente de borrado manual en Firebase Console.',
            style: TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: ocupada ? null : onEliminar,
            icon: eliminando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ColoresApp.rojoNoVerificado),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar cuenta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresApp.rojoNoVerificado,
              side: BorderSide(color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.55), width: 1.5),
              minimumSize: const Size(0, 46),
            ),
          ),
        ],
      ),
    );
  }
}
