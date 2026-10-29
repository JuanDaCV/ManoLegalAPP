import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../tema/tema_app.dart';

/// Un destino de navegación del panel post-login (cliente o abogado): (ícono,
/// etiqueta). Record posicional sin nombres de campo (Dart no permite nombrar
/// campos posicionales en un alias de tipo record); se accede con `.$1` / `.$2`.
typedef DestinoNavegacion = (IconData, String);

/// Marca "ManoLegal" con ícono de balanza, reutilizada en la barra superior
/// de escritorio y en el AppBar de móvil.
class MarcaManoLegal extends StatelessWidget {
  final Color colorTexto;

  const MarcaManoLegal({super.key, required this.colorTexto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.balance, color: colorTexto, size: 22),
        const SizedBox(width: 8),
        Text(
          'ManoLegal',
          style: GoogleFonts.plusJakartaSans(color: colorTexto, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ],
    );
  }
}

/// Barra superior propia del layout de escritorio del panel post-login
/// (cliente o abogado): marca a la izquierda, destinos de navegación al
/// centro (con indicador dorado sutil en el activo), y menú del usuario a la
/// derecha.
///
/// En modo visitante ([alIngresar] no nulo), el menú del usuario se cambia
/// por «Crear cuenta» e «Ingresar». Esos botones ocupan más que el menú, así
/// que los destinos se reducen un poco si no caben, en vez de desbordar.
class BarraSuperiorPostLogin extends StatelessWidget {
  final String nombre;
  final int indiceSeleccionado;
  final ValueChanged<int> onSeleccionar;
  final List<DestinoNavegacion> destinos;

  /// Modo visitante: ver [PlantillaPostLogin.alIngresar].
  final VoidCallback? alIngresar;
  final VoidCallback? alCrearCuenta;

  /// Si no es `null`, muestra un botón de volver antes de la marca.
  final VoidCallback? alVolver;

  const BarraSuperiorPostLogin({
    super.key,
    required this.nombre,
    required this.indiceSeleccionado,
    required this.onSeleccionar,
    required this.destinos,
    this.alIngresar,
    this.alCrearCuenta,
    this.alVolver,
  });

  @override
  Widget build(BuildContext context) {
    final alIngresar = this.alIngresar;
    final esVisitante = alIngresar != null;
    final separacion = esVisitante ? 24.0 : 40.0;
    final navegacion = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: esVisitante ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var i = 0; i < destinos.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _BotonDestino(
            icono: destinos[i].$1,
            etiqueta: destinos[i].$2,
            activo: i == indiceSeleccionado,
            onTap: () => onSeleccionar(i),
          ),
        ],
      ],
    );

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: ColoresApp.blanco,
        border: Border(bottom: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        children: [
          if (alVolver != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: ColoresApp.azulTurquiOscuro),
              tooltip: 'Volver',
              onPressed: alVolver,
            ),
            const SizedBox(width: 8),
          ],
          const MarcaManoLegal(colorTexto: ColoresApp.azulTurquiOscuro),
          SizedBox(width: separacion),
          Expanded(
            child: esVisitante ? FittedBox(fit: BoxFit.scaleDown, child: navegacion) : navegacion,
          ),
          SizedBox(width: separacion),
          if (esVisitante)
            _AccionesVisitante(alIngresar: alIngresar, alCrearCuenta: alCrearCuenta)
          else
            _MenuUsuario(nombre: nombre),
        ],
      ),
    );
  }
}

/// «Crear cuenta» (secundario) e «Ingresar» (primario) del visitante, más
/// compactos que los botones de pantalla completa del tema.
class _AccionesVisitante extends StatelessWidget {
  final VoidCallback alIngresar;
  final VoidCallback? alCrearCuenta;

  const _AccionesVisitante({required this.alIngresar, required this.alCrearCuenta});

  static const _relleno = EdgeInsets.symmetric(horizontal: 18, vertical: 10);
  static const _tamanoMinimo = Size(0, 44);
  static const _texto = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
  static final _forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(22));

  @override
  Widget build(BuildContext context) {
    final alCrearCuenta = this.alCrearCuenta;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (alCrearCuenta != null) ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: _relleno,
              minimumSize: _tamanoMinimo,
              textStyle: _texto,
              shape: _forma,
            ),
            onPressed: alCrearCuenta,
            child: const Text('Crear cuenta'),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: _relleno,
            minimumSize: _tamanoMinimo,
            textStyle: _texto,
            shape: _forma,
          ),
          onPressed: alIngresar,
          child: const Text('Ingresar'),
        ),
      ],
    );
  }
}

class _BotonDestino extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  const _BotonDestino({required this.icono, required this.etiqueta, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = activo ? ColoresApp.azulTurqui : ColoresApp.grisTexto;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  etiqueta,
                  style: TextStyle(color: color, fontWeight: activo ? FontWeight.w700 : FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 3,
              width: 20,
              decoration: BoxDecoration(
                color: activo ? ColoresApp.dorado : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menú del usuario en la esquina superior derecha de escritorio: nombre +
/// acceso a cerrar sesión.
class _MenuUsuario extends StatelessWidget {
  final String nombre;

  const _MenuUsuario({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (_) => context.read<ControladorAutenticacion>().cerrarSesion(),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'cerrar_sesion',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: ColoresApp.azulTurquiOscuro),
              SizedBox(width: 10),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: ColoresApp.azulTurqui,
            child: Text(
              nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Text(nombre, style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontWeight: FontWeight.w600)),
          const Icon(Icons.expand_more, color: ColoresApp.grisTexto, size: 20),
        ],
      ),
    );
  }
}
