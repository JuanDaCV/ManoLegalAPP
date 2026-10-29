import 'package:flutter/material.dart';

import '../../../tema/tema_app.dart';

/// Tarjeta contenedora estándar de un bloque del perfil del abogado: encabezado
/// con ícono y título, y contenido libre debajo.
///
/// Si se provee [onEditar], muestra un botón de lápiz para editar el bloque.
/// Si [esDatoDelSistema] es `true`, muestra en cambio un candado indicando
/// que ese dato lo gestiona ManoLegal y no se puede editar desde aquí.
class BloquePerfil extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;
  final VoidCallback? onEditar;
  final bool esDatoDelSistema;

  const BloquePerfil({
    super.key,
    required this.titulo,
    required this.icono,
    required this.child,
    this.onEditar,
    this.esDatoDelSistema = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: ColoresApp.azulTurqui, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ColoresApp.azulTurquiOscuro),
                ),
              ),
              if (onEditar != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: ColoresApp.grisTexto),
                  tooltip: 'Editar',
                  onPressed: onEditar,
                ),
              if (esDatoDelSistema)
                const Tooltip(
                  message: 'Lo gestiona ManoLegal',
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.lock_outline, size: 18, color: ColoresApp.grisTexto),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
