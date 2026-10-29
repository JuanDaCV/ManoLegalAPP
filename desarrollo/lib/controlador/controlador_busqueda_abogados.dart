import 'package:flutter/foundation.dart';

import '../modelo/especialidad_abogado.dart';
import '../modelo/modelo_resultado_abogado.dart';
import '../modelo/ubicacion_cali.dart';
import 'filtros_abogados.dart';
import 'servicio_perfil_publico.dart';

/// Estado del buscador de abogados.
///
/// [vacio] es un estado propio y no un error: significa que la consulta se
/// ejecutó correctamente y Firestore no devolvió ningún abogado. Con la base
/// vacía, el buscador debe decirlo y nunca inventar resultados.
enum EstadoBusqueda { inicial, cargando, conResultados, vacio, error }

/// Controlador del buscador de abogados del panel del cliente.
class ControladorBusquedaAbogados extends ChangeNotifier {
  final ServicioPerfilPublico _servicioPerfilPublico;

  ControladorBusquedaAbogados({ServicioPerfilPublico? servicioPerfilPublico})
      : _servicioPerfilPublico = servicioPerfilPublico ?? ServicioPerfilPublico();

  EstadoBusqueda estado = EstadoBusqueda.inicial;
  String? mensajeError;
  List<ModeloResultadoAbogado> resultados = const [];

  /// Vacío significa "todas las especialidades", no "ninguna".
  List<EspecialidadAbogado> especialidades = const [];

  /// Vacío significa "todas las zonas".
  List<UbicacionCali> ubicaciones = const [];

  /// Cero significa "cualquier calificación".
  double calificacionMinima = 0;

  bool soloVerificados = true;
  String texto = '';

  void fijarEspecialidades(List<EspecialidadAbogado> valores) {
    especialidades = valores;
    notifyListeners();
    buscar();
  }

  void fijarUbicaciones(List<UbicacionCali> valores) {
    ubicaciones = valores;
    notifyListeners();
    buscar();
  }

  void fijarCalificacionMinima(double valor) {
    calificacionMinima = valor;
    notifyListeners();
    buscar();
  }

  void fijarSoloVerificados(bool valor) {
    soloVerificados = valor;
    notifyListeners();
    buscar();
  }

  /// Guarda el texto sin lanzar la consulta: el usuario todavía está
  /// escribiendo. La búsqueda la dispara el botón "Buscar" o la tecla Enter.
  void fijarTexto(String valor) {
    texto = valor;
  }

  void limpiarFiltros() {
    especialidades = const [];
    ubicaciones = const [];
    calificacionMinima = 0;
    soloVerificados = true;
    notifyListeners();
    buscar();
  }

  /// Consulta los perfiles públicos reales.
  ///
  /// La especialidad, la verificación y la calificación mínima se resuelven
  /// en el servidor. La ubicación y el texto se aplican después en memoria,
  /// sobre ese conjunto ya acotado, porque Firestore no admite dos
  /// disyunciones en la misma consulta.
  Future<void> buscar() async {
    estado = EstadoBusqueda.cargando;
    mensajeError = null;
    notifyListeners();

    try {
      final perfiles = await _servicioPerfilPublico.buscar(
        soloVerificados: soloVerificados,
        calificacionMinima: calificacionMinima,
        especialidades: especialidades,
      );
      final filtrados = aplicarFiltrosLocales(perfiles, ubicaciones: ubicaciones, texto: texto);
      resultados = filtrados.map(aResultadoBusqueda).toList();
      estado = resultados.isEmpty ? EstadoBusqueda.vacio : EstadoBusqueda.conResultados;
      notifyListeners();
    } catch (e) {
      resultados = const [];
      estado = EstadoBusqueda.error;
      mensajeError = 'No se pudo cargar la lista de abogados. Revisa tu conexión e inténtalo de nuevo.';
      // También en release: el mensaje de la interfaz es el mismo para una
      // caída de red, un permiso denegado o un índice faltante, y solo la
      // consola del navegador dice cuál fue. El error no lleva datos
      // personales.
      debugPrint('Error al buscar abogados: $e');
      notifyListeners();
    }
  }
}
