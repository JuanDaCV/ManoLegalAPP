import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../configuracion/configuracion_recorrido_abogado.dart';
import '../../configuracion/configuracion_recorrido_pqrs.dart';
import '../../controlador/controlador_perfil_abogado.dart';
import '../compartido/barra_superior_post_login.dart';
import '../compartido/plantilla_post_login.dart';
import '../compartido/seccion_inicio.dart';
import '../compartido/seccion_pqrs.dart';
import '../compartido/widgets/recorrido/recorridos_por_seccion.dart';
import 'seccion_mi_perfil.dart';
import 'seccion_panel.dart';

/// Destinos de navegación del panel del abogado, en el orden en que
/// aparecen tanto en la barra superior de escritorio como en la barra de
/// navegación inferior de móvil.
const List<DestinoNavegacion> _destinosAbogado = [
  (Icons.home_outlined, 'Inicio'),
  (Icons.badge_outlined, 'Mi perfil'),
  (Icons.dashboard_outlined, 'Panel'),
  (Icons.support_agent, 'PQRS'),
];

/// Panel principal del abogado autenticado: shell de navegación con 4
/// secciones (Inicio, Mi perfil, Panel, PQRS), responsive entre barra
/// superior propia (escritorio) y barra de navegación inferior (móvil),
/// provisto por [PlantillaPostLogin].
///
/// El perfil real del abogado se carga una sola vez desde Firestore y se
/// expone vía Provider local a este panel, de modo que "Mi perfil" y "Panel"
/// leen exactamente los mismos datos. El nombre de bienvenida también sale de
/// ahí: antes se consultaba por separado, lo que permitía que el saludo y el
/// perfil mostraran información distinta.
class PanelAbogado extends StatefulWidget {
  const PanelAbogado({super.key});

  @override
  State<PanelAbogado> createState() => _PanelAbogadoState();
}

class _PanelAbogadoState extends State<PanelAbogado> {
  late final ControladorPerfilAbogado _controlador;

  @override
  void initState() {
    super.initState();
    _controlador = ControladorPerfilAbogado();
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) _controlador.cargar(usuario.uid);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// Nombre a mostrar en la bienvenida. Mientras el perfil carga se usa el
  /// correo de la sesión, que siempre está disponible.
  String? _nombreVisible() {
    final perfil = _controlador.perfil;
    if (perfil != null && perfil.nombreCompleto.trim().isNotEmpty) {
      return perfil.nombreCompleto.split(' ').first;
    }
    return FirebaseAuth.instance.currentUser?.email;
  }

  /// Cada sección tiene su recorrido guiado, que aparece la primera vez que
  /// el abogado entra en ella. Va por fuera del `ListenableBuilder` del
  /// perfil: recargar el perfil no debe recrear el coordinador ni la capa.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ControladorPerfilAbogado>.value(
      value: _controlador,
      child: RecorridosPorSeccion(
        recorridos: const [
          ConfiguracionRecorridoAbogado.inicio,
          ConfiguracionRecorridoAbogado.miPerfil,
          ConfiguracionRecorridoAbogado.panel,
          ConfiguracionRecorridoPqrs.pqrs,
        ],
        obtenerUid: () => FirebaseAuth.instance.currentUser?.uid,
        constructor: _construirPlantilla,
      ),
    );
  }

  Widget _construirPlantilla(ValueChanged<int> alCambiarSeccion) {
    return ListenableBuilder(
      listenable: _controlador,
      builder: (context, _) {
        final nombre = _nombreVisible();
        return PlantillaPostLogin(
          destinos: _destinosAbogado,
          nombre: nombre,
          alCambiarSeccion: alCambiarSeccion,
          construirSecciones: (esEscritorio) => [
            SeccionInicio(
              nombre: nombre ?? 'Cargando...',
              esEscritorio: esEscritorio,
              subtituloBienvenida:
                  'Consulta los perfiles de otros profesionales registrados en ManoLegal, incluidos colegas de otras especialidades.',
            ),
            SeccionMiPerfil(esEscritorio: esEscritorio),
            SeccionPanel(esEscritorio: esEscritorio),
            const SeccionPqrs(),
          ],
        );
      },
    );
  }
}
