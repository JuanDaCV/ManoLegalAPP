import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controlador/controlador_perfil_abogado.dart';
import '../../../../modelo/modelo_perfil_abogado.dart';
import '../../../../modelo/ubicacion_cali.dart';
import '../../../tema/tema_app.dart';
import '../../../widgets_comunes/campo_texto_personalizado.dart';
import 'bloque_perfil.dart';
import 'editor_perfil.dart';

/// Bloque "Ubicación" del perfil del abogado: zona general, sector y
/// dirección profesional, más un mapa de marcador de posición.
///
/// Los tres campos son editables por el abogado. La zona y la dirección son
/// conceptos distintos a propósito: la zona es la referencia amplia con la
/// que el cliente filtra en el buscador, y la dirección es el lugar concreto
/// de atención.
class SeccionUbicacion extends StatelessWidget {
  final ModeloPerfilAbogado perfil;
  final bool esEscritorio;
  final bool editable;

  const SeccionUbicacion({super.key, required this.perfil, required this.esEscritorio, required this.editable});

  void _editar(BuildContext context) {
    final controlador = context.read<ControladorPerfilAbogado>();
    final controladorSector = TextEditingController(text: perfil.sector);
    final controladorDireccion = TextEditingController(text: perfil.direccion);
    var zonaSeleccionada = ubicacionDesdeTextoLegible(perfil.ubicacionGeneral);

    mostrarEditorPerfil(
      context,
      esEscritorio: esEscritorio,
      titulo: 'Editar ubicación',
      contenido: StatefulBuilder(
        builder: (context, actualizar) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<UbicacionCali>(
              initialValue: zonaSeleccionada,
              decoration: const InputDecoration(labelText: 'Zona donde atiendes'),
              items: UbicacionCali.values
                  .map((valor) => DropdownMenuItem(value: valor, child: Text(valor.textoLegible)))
                  .toList(),
              onChanged: (valor) => actualizar(() => zonaSeleccionada = valor),
            ),
            const SizedBox(height: 12),
            CampoTextoPersonalizado(etiqueta: 'Sector', controlador: controladorSector, pista: 'Ej. Granada'),
            const SizedBox(height: 12),
            CampoTextoPersonalizado(
              etiqueta: 'Dirección',
              controlador: controladorDireccion,
              pista: 'Ej. Avenida 6 Norte #23-45',
            ),
          ],
        ),
      ),
      onGuardar: () async {
        final guardado = await controlador.actualizarUbicacion(
          ubicacionGeneral: zonaSeleccionada,
          sector: controladorSector.text.trim(),
          direccion: controladorDireccion.text.trim(),
        );
        return guardado ? null : controlador.mensajeError;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BloquePerfil(
      titulo: 'Ubicación',
      icono: Icons.map_outlined,
      onEditar: editable ? () => _editar(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilaUbicacion(
            etiqueta: 'Zona',
            valor: perfil.ubicacionGeneral.isEmpty ? 'Sin definir' : perfil.ubicacionGeneral,
            apilada: !esEscritorio,
          ),
          _FilaUbicacion(
            etiqueta: 'Sector',
            valor: perfil.sector.isEmpty ? 'Sin definir' : perfil.sector,
            apilada: !esEscritorio,
          ),
          _FilaUbicacion(
            etiqueta: 'Dirección',
            valor: perfil.direccion.isEmpty ? 'Sin definir' : perfil.direccion,
            ultima: true,
            apilada: !esEscritorio,
          ),
          const SizedBox(height: 16),
          const _MapaPlaceholder(),
        ],
      ),
    );
  }
}

class _FilaUbicacion extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool ultima;

  /// En móvil la etiqueta va arriba del valor: con una columna fija de 150 px
  /// para la etiqueta, al valor le quedaría una columna demasiado estrecha.
  final bool apilada;

  const _FilaUbicacion({
    required this.etiqueta,
    required this.valor,
    this.ultima = false,
    this.apilada = false,
  });

  @override
  Widget build(BuildContext context) {
    const estiloEtiqueta = TextStyle(color: ColoresApp.grisTexto, fontSize: 13, fontWeight: FontWeight.w600);
    const estiloValor = TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14);

    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 12),
      child: apilada
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: estiloEtiqueta),
                const SizedBox(height: 2),
                Text(valor, style: estiloValor),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 150, child: Text(etiqueta, style: estiloEtiqueta)),
                Expanded(child: Text(valor, style: estiloValor)),
              ],
            ),
    );
  }
}

/// Mapa de ubicación de marcador de posición: una grilla suave tipo calles,
/// un pin centrado y una leyenda. Sin ningún paquete de mapas.
class _MapaPlaceholder extends StatelessWidget {
  const _MapaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: ColoresApp.grisClaro,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(child: CustomPaint(painter: _GrillaCallesPainter())),
              const Icon(Icons.location_on, color: ColoresApp.azulTurqui, size: 40),
              Positioned(
                bottom: 12,
                child: Text(
                  'Mapa de ubicación — próximamente',
                  style: TextStyle(color: ColoresApp.grisTexto.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grilla fina simulando calles, decorativa, sobre el mapa de marcador de
/// posición.
class _GrillaCallesPainter extends CustomPainter {
  const _GrillaCallesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()
      ..color = ColoresApp.grisTexto.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const espaciado = 28.0;
    for (var x = 0.0; x < size.width; x += espaciado) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), pintura);
    }
    for (var y = 0.0; y < size.height; y += espaciado) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pintura);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
