import 'package:flutter/material.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../tema/tema_app.dart';
import '../widgets_comunes/plantilla_autenticacion.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_registro_abogado_paso1.dart';
import 'pantalla_registro_cliente.dart';

/// Permite elegir con qué rol se va a registrar el usuario.
class PantallaSeleccionRol extends StatelessWidget {
  /// Datos de la cuenta de Google cuando el usuario ya se autenticó pero aún
  /// no tiene perfil. Se pasan al formulario del rol elegido para
  /// autorrellenarlo y evitar que tenga que autenticarse de nuevo.
  final DatosGoogle? datosGoogle;

  const PantallaSeleccionRol({super.key, this.datosGoogle});

  @override
  Widget build(BuildContext context) {
    return PlantillaAutenticacion(
      motivo: MotivoAutenticacion.seleccionRol,
      titulo: 'Elige tu perfil',
      subtitulo:
          'Según tu perfil, te pediremos la información necesaria para crear y verificar tu cuenta.',
      heroGrande: true,
      formulario: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaRegistroCliente(datosGoogle: datosGoogle),
                    ),
                  ),
                  child: const Text('Cliente'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaRegistroAbogadoPaso1(datosGoogle: datosGoogle),
                    ),
                  ),
                  child: const Text('Abogado'),
                ),
              ),
            ],
          ),
          // Con una sesión de Google ya abierta no tiene sentido ofrecer
          // iniciar sesión: lo que falta es completar el perfil, no entrar.
          if (datosGoogle == null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ya tengo una cuenta.',
                  style: TextStyle(color: ColoresApp.grisTexto, fontSize: 14),
                ),
                TextButton(
                  // Reemplaza esta pantalla para no apilar registro sobre login.
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
                  ),
                  child: const Text('Iniciar sesión'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
