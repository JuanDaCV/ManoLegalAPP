import 'package:flutter/material.dart';

import '../../../modelo/especialidad_abogado.dart';
import '../../../modelo/ubicacion_cali.dart';
import '../../tema/tema_app.dart';

String _textoCalificacion(int estrellas) {
  if (estrellas == 0) return 'Cualquier calificación';
  final palabra = estrellas == 1 ? 'estrella' : 'estrellas';
  return '$estrellas $palabra o más';
}

/// Panel de filtros de búsqueda de abogados.
///
/// Un solo widget, reutilizado tanto en el panel lateral fijo de escritorio
/// como dentro del bottom sheet de móvil (ver `BuscadorAbogados`).
///
/// Las opciones salen de los enums [EspecialidadAbogado] y [UbicacionCali],
/// que son la única fuente oficial de esos valores en todo el sistema: los
/// mismos que usa el registro, el modelo y lo que se guarda en Firestore.
/// Antes había aquí dos listas de texto escritas a mano que no coincidían con
/// el modelo, de modo que un filtro podía ofrecer una especialidad que ningún
/// abogado podía tener.
///
/// Es un widget controlado: no guarda su propio estado, solo refleja los
/// valores recibidos y notifica cambios mediante los callbacks.
class PanelFiltros extends StatelessWidget {
  final List<EspecialidadAbogado> especialidadesSeleccionadas;
  final ValueChanged<List<EspecialidadAbogado>> onEspecialidadesSeleccionadasChanged;
  final List<UbicacionCali> ubicacionesSeleccionadas;
  final ValueChanged<List<UbicacionCali>> onUbicacionesSeleccionadasChanged;
  final double calificacionMinima;
  final ValueChanged<double> onCalificacionMinimaChanged;
  final bool soloVerificados;
  final ValueChanged<bool> onSoloVerificadosChanged;

  /// Restablece todos los filtros de una vez, para que se lance una sola búsqueda.
  final VoidCallback onLimpiarFiltros;

  const PanelFiltros({
    super.key,
    required this.especialidadesSeleccionadas,
    required this.onEspecialidadesSeleccionadasChanged,
    required this.ubicacionesSeleccionadas,
    required this.onUbicacionesSeleccionadasChanged,
    required this.calificacionMinima,
    required this.onCalificacionMinimaChanged,
    required this.soloVerificados,
    required this.onSoloVerificadosChanged,
    required this.onLimpiarFiltros,
  });

  void _alternarEnLista<T>(T valor, bool? marcada, List<T> actual, ValueChanged<List<T>> onChanged) {
    final nuevos = List<T>.from(actual);
    if (marcada ?? false) {
      nuevos.add(valor);
    } else {
      nuevos.remove(valor);
    }
    onChanged(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    final estrellasCalificacion = calificacionMinima.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Icon(Icons.tune, color: ColoresApp.azulTurqui),
            SizedBox(width: 8),
            Text('Filtros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ColoresApp.azulTurquiOscuro)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Especialidad', style: _estiloGrupo),
        for (final especialidad in EspecialidadAbogado.values)
          CheckboxListTile(
            value: especialidadesSeleccionadas.contains(especialidad),
            onChanged: (marcada) => _alternarEnLista(
              especialidad,
              marcada,
              especialidadesSeleccionadas,
              onEspecialidadesSeleccionadasChanged,
            ),
            title: Text(especialidad.textoLegible, style: const TextStyle(fontSize: 14)),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: ColoresApp.azulTurqui,
          ),
        const SizedBox(height: 12),
        const Text('Ubicación', style: _estiloGrupo),
        for (final ubicacion in UbicacionCali.values)
          CheckboxListTile(
            value: ubicacionesSeleccionadas.contains(ubicacion),
            onChanged: (marcada) => _alternarEnLista(
              ubicacion,
              marcada,
              ubicacionesSeleccionadas,
              onUbicacionesSeleccionadasChanged,
            ),
            title: Text(ubicacion.textoLegible, style: const TextStyle(fontSize: 14)),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: ColoresApp.azulTurqui,
          ),
        const SizedBox(height: 12),
        const Text('Calificación mínima', style: _estiloGrupo),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= estrellasCalificacion ? Icons.star : Icons.star_border,
                color: ColoresApp.dorado,
                size: 20,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _textoCalificacion(estrellasCalificacion),
                style: const TextStyle(fontSize: 13, color: ColoresApp.grisTexto),
              ),
            ),
          ],
        ),
        Slider(
          value: calificacionMinima,
          min: 0,
          max: 5,
          divisions: 5,
          activeColor: ColoresApp.azulTurqui,
          label: estrellasCalificacion == 0 ? 'Cualquiera' : '$estrellasCalificacion+',
          onChanged: onCalificacionMinimaChanged,
        ),
        const Divider(height: 24),
        SwitchListTile(
          value: soloVerificados,
          onChanged: onSoloVerificadosChanged,
          title: const Text(
            'Solo abogados verificados',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ColoresApp.azulTurquiOscuro),
          ),
          // `activeColor` está obsoleto desde Flutter 3.31 para Switch/SwitchListTile.
          activeThumbColor: ColoresApp.azulTurqui,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onLimpiarFiltros,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Limpiar filtros'),
          ),
        ),
      ],
    );
  }

  static const TextStyle _estiloGrupo = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: ColoresApp.azulTurquiOscuro,
  );
}
