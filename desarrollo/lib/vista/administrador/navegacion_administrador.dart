import 'package:flutter/material.dart';

import '../compartido/barra_superior_post_login.dart';
import '../tema/tema_app.dart';
import '../widgets_comunes/fondo_juridico.dart';
import 'estilos_administrador.dart';
import 'fuentes_oficiales.dart';

/// Secciones internas del panel. "Herramientas" solo tiene pestaña propia en
/// móvil: en escritorio sus dos accesos viven directamente en el sidebar.
enum SeccionAdministrador { inicio, verificacion, herramientas }

/// Sidebar del administrador en escritorio.
///
/// Completo desde [EstilosAdmin.corteSidebarCompleto]; entre ese ancho y
/// [EstilosAdmin.corteMovil] se reduce a un riel de íconos con tooltips, para
/// dejar espacio a la tabla sin esconder la navegación. Usa el mismo fondo de
/// marca que la landing y el onboarding.
class SidebarAdministrador extends StatelessWidget {
  final SeccionAdministrador seccionActual;
  final ValueChanged<SeccionAdministrador> onSeleccionar;
  final bool compacto;
  final String correoAdministrador;
  final VoidCallback onCerrarSesion;

  const SidebarAdministrador({
    super.key,
    required this.seccionActual,
    required this.onSeleccionar,
    required this.compacto,
    required this.correoAdministrador,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compacto ? EstilosAdmin.anchoRiel : EstilosAdmin.anchoSidebar,
      child: FondoJuridico(
        intensidadIcono: 0.05,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Marca(compacto: compacto),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!compacto) const _EtiquetaGrupo('GENERAL'),
                      _EntradaSidebar(
                        icono: Icons.space_dashboard_outlined,
                        etiqueta: 'Inicio',
                        activa: seccionActual == SeccionAdministrador.inicio,
                        compacto: compacto,
                        onTap: () => onSeleccionar(SeccionAdministrador.inicio),
                      ),
                      _EntradaSidebar(
                        icono: Icons.fact_check_outlined,
                        etiqueta: 'Verificación de abogados',
                        activa: seccionActual == SeccionAdministrador.verificacion,
                        compacto: compacto,
                        onTap: () => onSeleccionar(SeccionAdministrador.verificacion),
                      ),
                      const SizedBox(height: 18),
                      if (compacto)
                        const Divider(indent: 22, endIndent: 22, color: Color(0x1FFFFFFF))
                      else
                        const _EtiquetaGrupo('HERRAMIENTAS OFICIALES DE VERIFICACIÓN'),
                      for (final fuente in fuentesOficialesVerificacion)
                        _EntradaSidebar(
                          icono: fuente.icono,
                          etiqueta: fuente.titulo,
                          compacto: compacto,
                          externa: true,
                          ayuda: '${fuente.entidad}\nSe abre ${fuente.dominio} en una pestaña nueva',
                          onTap: () => abrirFuenteOficial(context, fuente),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0x1FFFFFFF)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!compacto) _Administrador(correo: correoAdministrador),
                    _EntradaSidebar(
                      icono: Icons.logout_rounded,
                      etiqueta: 'Cerrar sesión',
                      compacto: compacto,
                      onTap: onCerrarSesion,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  final bool compacto;

  const _Marca({required this.compacto});

  @override
  Widget build(BuildContext context) {
    if (compacto) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 26),
        child: Tooltip(
          message: 'ManoLegal · Administración',
          child: Icon(Icons.balance, color: ColoresApp.blanco, size: 28),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(26, 30, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarcaManoLegal(colorTexto: ColoresApp.blanco),
          SizedBox(height: 8),
          Text(
            'ADMINISTRACIÓN',
            // Dorado sobre azul turquí: contraste suficiente para texto.
            style: TextStyle(color: ColoresApp.dorado, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8),
          ),
        ],
      ),
    );
  }
}

class _EtiquetaGrupo extends StatelessWidget {
  final String texto;

  const _EtiquetaGrupo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 8, 20, 8),
      child: Text(texto, maxLines: 2, style: EstilosAdmin.etiquetaGrupoSidebar),
    );
  }
}

class _EntradaSidebar extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activa;
  final bool compacto;

  /// Abre un sitio externo: se marca con un ícono de salida.
  final bool externa;

  /// Texto adicional del tooltip, por ejemplo la entidad y el dominio.
  final String? ayuda;
  final VoidCallback onTap;

  const _EntradaSidebar({
    required this.icono,
    required this.etiqueta,
    required this.compacto,
    required this.onTap,
    this.activa = false,
    this.externa = false,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    final color = activa ? ColoresApp.blanco : EstilosAdmin.textoSobreOscuro;

    final indicador = Container(
      width: 3,
      height: 22,
      decoration: BoxDecoration(
        color: activa ? ColoresApp.dorado : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    final contenido = compacto
        ? SizedBox(
            height: 48,
            child: Row(
              children: [
                indicador,
                Expanded(
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(icono, color: color, size: 23),
                        if (externa)
                          const Positioned(
                            right: -8,
                            top: -5,
                            child: Icon(Icons.open_in_new_rounded, size: 11, color: Color(0x99FFFFFF)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(0, 11, 12, 11),
            child: Row(
              children: [
                indicador,
                const SizedBox(width: 11),
                Icon(icono, color: color, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    etiqueta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (externa) const Icon(Icons.open_in_new_rounded, size: 15, color: Color(0x99FFFFFF)),
              ],
            ),
          );

    final entrada = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Semantics(
        button: true,
        selected: activa,
        label: externa ? '$etiqueta, abre el sitio oficial fuera de ManoLegal' : etiqueta,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            hoverColor: const Color(0x0FFFFFFF),
            child: Ink(
              decoration: activa
                  ? BoxDecoration(
                      color: ColoresApp.superficieCristal,
                      border: Border.all(color: ColoresApp.bordeCristal),
                      borderRadius: BorderRadius.circular(14),
                    )
                  : null,
              child: contenido,
            ),
          ),
        ),
      ),
    );

    final mensaje = compacto ? (ayuda == null ? etiqueta : '$etiqueta\n$ayuda') : ayuda;
    if (mensaje == null) return entrada;
    return Tooltip(message: mensaje, preferBelow: false, child: entrada);
  }
}

class _Administrador extends StatelessWidget {
  final String correo;

  const _Administrador({required this.correo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 16, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ColoresApp.dorado.withValues(alpha: 0.2),
            child: const Icon(Icons.shield_outlined, size: 18, color: ColoresApp.dorado),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrador',
                  style: TextStyle(color: ColoresApp.blanco, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: EstilosAdmin.textoSecundarioSobreOscuro, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
