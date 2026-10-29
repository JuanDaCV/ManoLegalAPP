import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../tema/tema_app.dart';
import 'barra_superior_post_login.dart';

/// Ancho mínimo, en píxeles lógicos, a partir del cual un panel post-login
/// (cliente o abogado) usa el layout de escritorio (barra superior propia +
/// contenido ancho) en vez del layout de móvil (AppBar compacta + barra de
/// navegación inferior).
///
/// Único umbral del módulo: todo lo que necesita distinguir escritorio de
/// móvil recibe el resultado ya calculado aquí como un bool `esEscritorio`,
/// en vez de repetir este número en cada widget.
const double anchoEscritorioPostLogin = 900;

/// Shell genérico de navegación post-login, compartido entre el panel del
/// cliente y el panel del abogado: responsive entre barra superior propia
/// (escritorio) y barra de navegación inferior (móvil), con las secciones
/// concretas provistas por quien lo usa.
class PlantillaPostLogin extends StatefulWidget {
  final List<DestinoNavegacion> destinos;

  /// Construye las secciones a mostrar en el [IndexedStack], en el mismo
  /// orden que [destinos]. Recibe `esEscritorio` para que cada sección
  /// adapte su propio layout.
  final List<Widget> Function(bool esEscritorio) construirSecciones;

  /// Nombre del usuario a mostrar en la barra superior / menú. `null`
  /// mientras se está cargando.
  final String? nombre;

  /// Se llama con el índice de la sección elegida, solo cuando cambia de
  /// verdad: no al volver a elegir la misma, ni al redimensionar, ni al
  /// reconstruirse. Lo usa el recorrido guiado para saber qué sección se ve.
  final ValueChanged<int>? alCambiarSeccion;

  /// Modo visitante (web, sin sesión). Si no es `null`, en lugar del menú
  /// del usuario (escritorio) y del botón de cerrar sesión (móvil) se ofrece
  /// «Ingresar»; en escritorio también «Crear cuenta» ([alCrearCuenta]).
  final VoidCallback? alIngresar;
  final VoidCallback? alCrearCuenta;

  /// Botón de volver de la barra de escritorio. En móvil no hace falta: el
  /// `AppBar` ya muestra su flecha cuando la ruta se puede cerrar.
  final VoidCallback? alVolver;

  const PlantillaPostLogin({
    super.key,
    required this.destinos,
    required this.construirSecciones,
    required this.nombre,
    this.alCambiarSeccion,
    this.alIngresar,
    this.alCrearCuenta,
    this.alVolver,
  });

  @override
  State<PlantillaPostLogin> createState() => _PlantillaPostLoginState();
}

class _PlantillaPostLoginState extends State<PlantillaPostLogin> {
  int _indiceSeccion = 0;

  void _seleccionarSeccion(int indice) {
    if (indice == _indiceSeccion) return;
    setState(() => _indiceSeccion = indice);
    widget.alCambiarSeccion?.call(indice);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.nombre ?? 'Cargando...';

    return LayoutBuilder(
      builder: (context, constraints) {
        final esEscritorio = constraints.maxWidth >= anchoEscritorioPostLogin;
        final cuerpo = IndexedStack(
          index: _indiceSeccion,
          children: widget.construirSecciones(esEscritorio),
        );

        if (esEscritorio) {
          return Scaffold(
            body: Column(
              children: [
                BarraSuperiorPostLogin(
                  nombre: nombre,
                  indiceSeleccionado: _indiceSeccion,
                  onSeleccionar: _seleccionarSeccion,
                  destinos: widget.destinos,
                  alIngresar: widget.alIngresar,
                  alCrearCuenta: widget.alCrearCuenta,
                  alVolver: widget.alVolver,
                ),
                Expanded(child: cuerpo),
              ],
            ),
          );
        }

        final alIngresar = widget.alIngresar;
        return Scaffold(
          appBar: AppBar(
            title: const MarcaManoLegal(colorTexto: ColoresApp.blanco),
            actions: [
              if (alIngresar != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: ColoresApp.blanco,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: alIngresar,
                  child: const Text('Ingresar'),
                )
              else
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: () => context.read<ControladorAutenticacion>().cerrarSesion(),
                ),
            ],
          ),
          body: cuerpo,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _indiceSeccion,
            onDestinationSelected: _seleccionarSeccion,
            destinations: [
              for (final destino in widget.destinos) NavigationDestination(icon: Icon(destino.$1), label: destino.$2),
            ],
          ),
        );
      },
    );
  }
}
