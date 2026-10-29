import '../modelo/especialidad_abogado.dart';
import '../modelo/modelo_perfil_publico_abogado.dart';
import '../modelo/modelo_resultado_abogado.dart';
import '../modelo/ubicacion_cali.dart';

/// Aplica en memoria los filtros que Firestore no puede resolver en la misma
/// consulta: ubicación y búsqueda por texto. Ambos filtros se combinan con
/// una conjunción (Y lógico).
List<ModeloPerfilPublicoAbogado> aplicarFiltrosLocales(
  List<ModeloPerfilPublicoAbogado> perfiles, {
  List<UbicacionCali> ubicaciones = const [],
  String texto = '',
}) {
  var resultado = perfiles;

  if (ubicaciones.isNotEmpty) {
    resultado = resultado.where((perfil) => ubicaciones.contains(perfil.ubicacionGeneral)).toList();
  }

  final textoLimpio = texto.trim();
  if (textoLimpio.isNotEmpty) {
    final busqueda = normalizarTexto(textoLimpio);
    resultado = resultado.where((perfil) {
      return perfil.nombreBusqueda.contains(busqueda) ||
          normalizarTexto(perfil.especialidad.textoLegible).contains(busqueda) ||
          normalizarTexto(perfil.ubicacionGeneral?.textoLegible ?? '').contains(busqueda) ||
          normalizarTexto(perfil.sector).contains(busqueda);
    }).toList();
  }

  return resultado;
}

/// Convierte un perfil público en el modelo que consume la tarjeta del
/// buscador.
ModeloResultadoAbogado aResultadoBusqueda(ModeloPerfilPublicoAbogado perfil) {
  return ModeloResultadoAbogado(
    uid: perfil.uid,
    nombreCompleto: perfil.nombreCompleto,
    especialidad: perfil.especialidad.textoLegible,
    ubicacion: perfil.ubicacionGeneral?.textoLegible ?? 'Ubicación no indicada',
    verificado: perfil.verificado,
    calificacion: perfil.calificacionPromedio,
    tarifaDesde: perfil.tarifa,
    fotoUrl: perfil.fotoUrl,
    cantidadResenas: perfil.cantidadResenas,
  );
}
