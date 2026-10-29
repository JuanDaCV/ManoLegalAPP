import 'dart:async';

import 'package:desarrollo/controlador/almacen_local_base.dart';
import 'package:desarrollo/controlador/controlador_recorrido.dart';
import 'package:desarrollo/controlador/servicio_perfil_publico.dart';
import 'package:desarrollo/modelo/especialidad_abogado.dart';
import 'package:desarrollo/modelo/modelo_paso_recorrido.dart';
import 'package:desarrollo/modelo/modelo_perfil_publico_abogado.dart';
import 'package:desarrollo/modelo/ubicacion_cali.dart';

/// Almacén local en memoria, con fallos programables. Nunca toca el disco ni
/// el navegador.
class AlmacenMemoria implements AlmacenLocal {
  final Map<String, String> datos = {};

  bool fallarLectura = false;
  bool fallarEscritura = false;

  /// Cuántas veces se leyó.
  int lecturas = 0;

  /// Cada escritura (con `valor`) y cada borrado (con `valor` nulo), en orden.
  final List<({String clave, String? valor})> escrituras = [];

  /// Si está puesto, escribir y borrar esperan a que se complete: simula un
  /// almacenamiento lento.
  Completer<void>? retenerEscritura;

  @override
  Future<String?> leer(String clave) async {
    lecturas++;
    if (fallarLectura) {
      throw StateError('No se puede leer el almacén de prueba.');
    }
    return datos[clave];
  }

  @override
  Future<void> escribir(String clave, String valor) async {
    await retenerEscritura?.future;
    if (fallarEscritura) {
      throw StateError('No se puede escribir en el almacén de prueba.');
    }
    datos[clave] = valor;
    escrituras.add((clave: clave, valor: valor));
  }

  @override
  Future<void> borrar(String clave) async {
    await retenerEscritura?.future;
    if (fallarEscritura) {
      throw StateError('No se puede escribir en el almacén de prueba.');
    }
    datos.remove(clave);
    escrituras.add((clave: clave, valor: null));
  }
}

/// Las marcas que hay en Inicio cuando ya cargaron abogados: todas menos el
/// indicador de carga.
Set<MarcaRecorridoId> marcasDeInicioConAbogados() => {
  MarcaRecorridoId.buscador,
  MarcaRecorridoId.filtros,
  MarcaRecorridoId.tarjeta,
  MarcaRecorridoId.verPerfil,
  MarcaRecorridoId.insignia,
};

/// Vista falsa del recorrido: qué marcas hay a la vista lo decide la prueba, y
/// registra lo que el controlador le pide.
class PuenteVistaFalso implements PuenteVistaRecorrido {
  final Set<MarcaRecorridoId> disponibles = {};

  /// Marcas para las que se pidió [prepararPaso], en orden.
  final List<MarcaRecorridoId> preparados = [];

  /// Cuántas veces se consultó la disponibilidad de cada marca.
  final Map<MarcaRecorridoId, int> consultas = {};

  int capturas = 0;
  MarcaRecorridoId? marcaCapturada;
  int restauraciones = 0;

  /// Se llama en cada consulta de disponibilidad, antes de responder. Permite
  /// programar que una marca aparezca o desaparezca tras N consultas, sin
  /// depender del reloj.
  void Function(MarcaRecorridoId marca)? alConsultar;

  /// Si está puesto, [prepararPaso] espera a que se complete: un
  /// desplazamiento en curso.
  Completer<void>? retenerPreparacion;

  /// Si está puesto, [prepararPaso] lo lanza: un desplazamiento que falla.
  Object? fallarAlPreparar;

  @override
  bool estaDisponible(MarcaRecorridoId marca) {
    consultas[marca] = (consultas[marca] ?? 0) + 1;
    alConsultar?.call(marca);
    return disponibles.contains(marca);
  }

  @override
  Future<void> prepararPaso(MarcaRecorridoId marca) async {
    preparados.add(marca);
    await retenerPreparacion?.future;
    final fallo = fallarAlPreparar;
    if (fallo != null) throw fallo;
  }

  @override
  void capturarDesplazamiento(MarcaRecorridoId marca) {
    capturas++;
    marcaCapturada = marca;
  }

  @override
  void restaurarDesplazamiento() => restauraciones++;
}

/// Perfil público con datos obviamente inventados, solo para pruebas.
ModeloPerfilPublicoAbogado perfilDePrueba({
  required String uid,
  required String nombreCompleto,
  EspecialidadAbogado especialidad = EspecialidadAbogado.civil,
  UbicacionCali? ubicacion,
  bool verificado = true,
  double calificacion = 0,
  int cantidadResenas = 0,
  double? tarifa,
}) {
  return ModeloPerfilPublicoAbogado(
    uid: uid,
    nombreCompleto: nombreCompleto,
    nombreBusqueda: normalizarTexto(nombreCompleto),
    especialidad: especialidad,
    aniosExperiencia: 5,
    ubicacionGeneral: ubicacion,
    verificado: verificado,
    calificacionPromedio: calificacion,
    cantidadResenas: cantidadResenas,
    telefonoProfesional: '+573001112233',
    correoContacto: 'contacto@ejemplo.com',
    tarifa: tarifa,
  );
}

/// Servicio de perfiles públicos falso: devuelve [perfiles] sin tocar
/// Firestore. Se declara con `implements` porque extender la clase real
/// ejecutaría `FirebaseFirestore.instance` al crearla.
class PerfilPublicoFalso implements ServicioPerfilPublico {
  PerfilPublicoFalso(this.perfiles);

  List<ModeloPerfilPublicoAbogado> perfiles;

  /// Cuántas búsquedas se hicieron.
  int busquedas = 0;

  /// Si está puesto, la búsqueda queda cargando hasta que se complete.
  Completer<void>? retener;

  /// Si está puesto, la búsqueda lo lanza: Firestore sin conexión.
  Object? error;

  @override
  Future<List<ModeloPerfilPublicoAbogado>> buscar({
    bool soloVerificados = true,
    double calificacionMinima = 0,
    List<EspecialidadAbogado> especialidades = const [],
    int limite = 100,
  }) async {
    busquedas++;
    await retener?.future;
    final fallo = error;
    if (fallo != null) throw fallo;
    return perfiles;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
