import 'package:flutter/material.dart';

import '../../../../configuracion/configuracion_recorrido_cliente.dart';
import '../../../../controlador/almacen_local.dart';
import '../../../../controlador/coordinador_recorridos.dart';
import '../../../../modelo/modelo_recorrido.dart';
import 'anfitrion_recorrido.dart';
import 'registro_marcas_recorrido.dart';

/// Da a un panel con secciones (cliente o abogado) un recorrido guiado por
/// sección, mostrado la primera vez que el usuario entra en cada una.
///
/// Es dueño del registro de marcas y del [CoordinadorRecorridos]. Envuelve la
/// plantilla en un único [AnfitrionRecorrido], que muestra el recorrido de la
/// sección activa. [constructor] recibe la función que la plantilla debe
/// llamar al cambiar de sección.
class RecorridosPorSeccion extends StatefulWidget {
  const RecorridosPorSeccion({
    super.key,
    required this.recorridos,
    required this.obtenerUid,
    required this.constructor,
    this.almacen,
    this.intervaloSondeo,
  });

  /// Recorrido de cada sección, en el orden de la navegación; `null` en las
  /// que no tienen. Se lee al montarse.
  final List<ModeloRecorrido?> recorridos;

  /// Usuario actual. Se inyecta para poder probar el panel sin Firebase.
  final String? Function() obtenerUid;

  /// Construye la plantilla del panel. Debe pasarle `alCambiarSeccion` a la
  /// `PlantillaPostLogin` para que el recorrido sepa qué sección se ve.
  final Widget Function(ValueChanged<int> alCambiarSeccion) constructor;

  /// Almacén del estado de los recorridos. `null` usa el del dispositivo;
  /// las pruebas pasan uno en memoria.
  final AlmacenLocal? almacen;

  /// Cada cuánto se consulta la vista mientras se espera. `null` usa el valor
  /// de la configuración.
  final Duration? intervaloSondeo;

  @override
  State<RecorridosPorSeccion> createState() => _RecorridosPorSeccionState();
}

class _RecorridosPorSeccionState extends State<RecorridosPorSeccion> {
  final RegistroMarcasRecorrido _registro = RegistroMarcasRecorrido();
  late final CoordinadorRecorridos _coordinador = CoordinadorRecorridos(
    recorridos: widget.recorridos,
    vista: _registro,
    obtenerUid: () => widget.obtenerUid(),
    almacen: widget.almacen,
    intervaloSondeo:
        widget.intervaloSondeo ?? ConfiguracionRecorridoCliente.intervaloSondeo,
  );

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: el recorrido necesita la primera sección ya
    // dibujada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coordinador.alEntrarEnSeccion(0);
    });
  }

  @override
  void dispose() {
    _coordinador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // La plantilla se construye una vez por build de este widget y pasa como
    // `child`: cambiar de recorrido activo no la reconstruye.
    return ListenableBuilder(
      listenable: _coordinador,
      child: widget.constructor(_coordinador.alEntrarEnSeccion),
      builder: (context, plantilla) => AnfitrionRecorrido(
        controlador: _coordinador.controladorActivo,
        registro: _registro,
        child: plantilla!,
      ),
    );
  }
}
