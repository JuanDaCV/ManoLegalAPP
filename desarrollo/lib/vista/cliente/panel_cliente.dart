import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../configuracion/configuracion_recorrido_cliente.dart';
import '../../configuracion/configuracion_recorrido_pqrs.dart';
import '../../controlador/servicio_firestore.dart';
import '../compartido/barra_superior_post_login.dart';
import '../compartido/plantilla_post_login.dart';
import '../compartido/seccion_inicio.dart';
import '../compartido/seccion_pqrs.dart';
import '../compartido/widgets/recorrido/recorridos_por_seccion.dart';
import 'seccion_como_funciona.dart';
import 'seccion_lexus.dart';

/// Destinos de navegación del panel del cliente, en el orden en que
/// aparecen tanto en la barra superior de escritorio como en la barra de
/// navegación inferior de móvil.
const List<DestinoNavegacion> _destinosCliente = [
  (Icons.home_outlined, 'Inicio'),
  (Icons.help_outline, 'Cómo funciona'),
  (Icons.gavel_outlined, 'Lexus'),
  (Icons.support_agent, 'PQRS'),
];

/// Panel principal del cliente autenticado: shell de navegación con 4
/// secciones (Inicio, Cómo funciona, Lexus, PQRS), responsive
/// entre barra superior propia (escritorio) y barra de navegación inferior
/// (móvil), provisto por [PlantillaPostLogin].
class PanelCliente extends StatefulWidget {
  const PanelCliente({super.key});

  @override
  State<PanelCliente> createState() => _PanelClienteState();
}

class _PanelClienteState extends State<PanelCliente> {
  final _servicioFirestore = ServicioFirestore();
  String? _nombre;

  /// El shell reconstruye el `IndexedStack` al cruzar los 900 px de ancho
  /// (escritorio: `Column`; móvil: cuerpo directo del `Scaffold`) y eso vuelve
  /// a montar todas las secciones. Con esta clave "Cómo funciona" conserva su
  /// estado: la posición de desplazamiento y el video en curso. Con la suya,
  /// Lexus conserva la conversación, que solo vive en memoria.
  final _claveComoFunciona = GlobalKey();
  final _claveLexus = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    final usuario = FirebaseAuth.instance.currentUser;
    String nombre;
    try {
      final cliente = usuario == null ? null : await _servicioFirestore.obtenerCliente(usuario.uid);
      nombre = cliente?.nombre ?? usuario?.email ?? 'usuario';
    } catch (_) {
      nombre = usuario?.email ?? 'usuario';
    }
    if (mounted) setState(() => _nombre = nombre);
  }

  /// Cada sección tiene su recorrido guiado, que aparece la primera vez que
  /// el cliente entra en ella. El estado se recuerda por usuario en este
  /// dispositivo; el de Inicio conserva la clave de siempre.
  @override
  Widget build(BuildContext context) {
    return RecorridosPorSeccion(
      recorridos: const [
        ConfiguracionRecorridoCliente.inicio,
        ConfiguracionRecorridoCliente.comoFunciona,
        ConfiguracionRecorridoCliente.lexus,
        ConfiguracionRecorridoPqrs.pqrs,
      ],
      obtenerUid: () => FirebaseAuth.instance.currentUser?.uid,
      constructor: _construirPlantilla,
    );
  }

  Widget _construirPlantilla(ValueChanged<int> alCambiarSeccion) {
    return PlantillaPostLogin(
      destinos: _destinosCliente,
      nombre: _nombre,
      alCambiarSeccion: alCambiarSeccion,
      construirSecciones: (esEscritorio) => [
        SeccionInicio(nombre: _nombre ?? 'Cargando...', esEscritorio: esEscritorio),
        SeccionComoFunciona(key: _claveComoFunciona),
        SeccionLexus(key: _claveLexus),
        const SeccionPqrs(),
      ],
    );
  }
}
