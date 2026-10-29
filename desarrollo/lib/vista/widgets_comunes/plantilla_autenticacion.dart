import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/tema_app.dart';
import 'fondo_juridico.dart';
import 'panel_marca_acceso_web.dart';
import 'tarjeta_cristal.dart';

/// Ancho a partir del cual [PlantillaAutenticacion] usa el layout de
/// escritorio (dos columnas) en vez del layout de móvil (tarjeta esmerilada
/// sobre fondo jurídico).
const double _anchoCorteEscritorio = 900;

/// Motivo por el que se muestra una pantalla de autenticación. Define el
/// ícono y la frase del panel visual dentro de [PlantillaAutenticacion].
enum MotivoAutenticacion {
  iniciarSesion,
  recuperar,
  seleccionRol,
  registroCliente,
  abogadoDatos,
  abogadoPerfil,
  abogadoDocumentos,
}

/// Ícono grande y frase corta del panel visual para cada [MotivoAutenticacion].
(IconData, String) _datosMotivo(MotivoAutenticacion motivo) {
  return switch (motivo) {
    MotivoAutenticacion.iniciarSesion => (Icons.balance, 'Justicia accesible, verificada'),
    MotivoAutenticacion.recuperar => (Icons.lock_reset, 'Recupera tu acceso en un minuto'),
    MotivoAutenticacion.seleccionRol => (Icons.groups, 'Una plataforma, dos caminos'),
    MotivoAutenticacion.registroCliente => (Icons.handshake, 'Encuentra al abogado indicado'),
    MotivoAutenticacion.abogadoDatos => (Icons.badge, 'Súmate como abogado verificado'),
    MotivoAutenticacion.abogadoPerfil => (Icons.military_tech, 'Muestra tu trayectoria'),
    MotivoAutenticacion.abogadoDocumentos => (Icons.verified_user, 'La verificación protege a todos'),
  };
}

/// Plantilla visual compartida por todas las pantallas de autenticación:
/// resuelve el layout responsive (escritorio de dos columnas / móvil con
/// tarjeta esmerilada) para que cada pantalla solo aporte su formulario.
///
/// Ninguna pantalla que use esta plantilla debe declarar su propio
/// [Scaffold] ni [AppBar]: este widget ya provee ambos.
class PlantillaAutenticacion extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final MotivoAutenticacion motivo;
  final Widget formulario;

  /// Paso actual del registro de abogado (1..[totalPasos]). Si es `null`,
  /// no se muestra el indicador de pasos.
  final int? paso;
  final int? totalPasos;

  /// En móvil, hace que el bloque visual superior ocupe casi la mitad de la
  /// pantalla. Se usa en pantallas de poco contenido (selección de rol).
  final bool heroGrande;

  /// Si se usa el diseño web del inicio de sesión de escritorio (panel de
  /// marca a la izquierda y formulario a la derecha, a toda la ventana). Si
  /// es `null`, se usa en la web ([kIsWeb]); las pruebas lo fijan. Solo
  /// aplica a [MotivoAutenticacion.iniciarSesion] desde 900 px: el resto de
  /// motivos, anchos y plataformas conserva su diseño.
  final bool? disenoWeb;

  const PlantillaAutenticacion({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.motivo,
    required this.formulario,
    this.paso,
    this.totalPasos,
    this.heroGrande = false,
    this.disenoWeb,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esEscritorio = constraints.maxWidth >= _anchoCorteEscritorio;
        if (esEscritorio && (disenoWeb ?? kIsWeb) && motivo == MotivoAutenticacion.iniciarSesion) {
          return _construirEscritorioWeb();
        }
        return esEscritorio ? _construirEscritorio() : _construirMovil(context);
      },
    );
  }

  Widget _construirMarca() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.balance, color: ColoresApp.azulTurqui, size: 22),
        const SizedBox(width: 8),
        Text(
          'ManoLegal',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: ColoresApp.azulTurquiOscuro,
          ),
        ),
      ],
    );
  }

  Widget _construirEncabezado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _construirMarca(),
        if (paso != null && totalPasos != null) ...[
          const SizedBox(height: 20),
          _IndicadorPasos(paso: paso!, totalPasos: totalPasos!),
        ],
        const SizedBox(height: 24),
        Text(
          titulo,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 30,
            color: ColoresApp.azulTurquiOscuro,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Columna izquierda del layout de escritorio: marca, encabezado y formulario,
  /// centrados verticalmente y limitados a un ancho de lectura cómodo.
  Widget _panelFormulario() {
    return ColoredBox(
      color: ColoresApp.blanco,
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [_construirEncabezado(), formulario],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirEscritorio() {
    final (icono, frase) = _datosMotivo(motivo);

    // IntrinsicHeight + Row(stretch) igualan la altura de las dos columnas a
    // la altura natural del contenido (con un mínimo de 640), y el
    // LayoutBuilder externo permite que toda la tarjeta se desplace en vez
    // de desbordar cuando la ventana es más baja que ese contenido.
    final tarjeta = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 640),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _panelFormulario()),
              Expanded(flex: 4, child: _PanelVisual(icono: icono, frase: frase)),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: ColoresApp.grisClaro,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: tarjeta,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Inicio de sesión web de escritorio: dos paneles a toda la ventana. A la
  /// izquierda, [PanelMarcaAccesoWeb]; a la derecha, sobre blanco, el mismo
  /// encabezado y formulario de siempre, centrados y con ancho de lectura.
  /// Solo el formulario se desplaza si la ventana es baja.
  Widget _construirEscritorioWeb() {
    final (icono, frase) = _datosMotivo(motivo);

    final formularioWeb = ColoredBox(
      color: ColoresApp.blanco,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (Navigator.canPop(context)) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: ColoresApp.azulTurqui),
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Volver'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _construirEncabezado(),
                      formulario,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: PanelMarcaAccesoWeb(icono: icono, frase: frase)),
          Expanded(flex: 6, child: formularioWeb),
        ],
      ),
    );
  }

  /// Layout de móvil: bloque visual a sangre arriba (con esquinas inferiores
  /// redondeadas) y, debajo, contenido sobre fondo blanco con título grande
  /// centrado y campos tipo píldora.
  Widget _construirMovil(BuildContext context) {
    final (icono, _) = _datosMotivo(motivo);
    final altoPantalla = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroVisual(
              icono: icono,
              altura: heroGrande ? altoPantalla * 0.42 : 210,
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (paso != null && totalPasos != null) ...[
                      _IndicadorPasos(paso: paso!, totalPasos: totalPasos!),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        height: 1.15,
                        color: ColoresApp.azulTurquiOscuro,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ColoresApp.grisTexto,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    formulario,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque visual superior del layout de móvil: ocupa el lugar de la foto en
/// las referencias de diseño. Para usar una imagen real, basta con reemplazar
/// el degradado por un `Image.asset(..., fit: BoxFit.cover)` dentro del
/// [ClipRRect], manteniendo el mismo alto y el botón de volver.
class _HeroVisual extends StatelessWidget {
  final IconData icono;
  final double altura;

  const _HeroVisual({required this.icono, required this.altura});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: SizedBox(
        height: altura,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColoresApp.azulTurquiOscuro,
                      ColoresApp.azulTurqui,
                      ColoresApp.azulProfundo,
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(top: -60, right: -40, child: _Orbe(diametro: 180)),
            const Positioned(bottom: -70, left: -50, child: _Orbe(diametro: 190)),
            Center(
              child: TarjetaCristal(
                borderRadius: 28,
                padding: const EdgeInsets.all(20),
                child: Icon(
                  icono,
                  size: altura * 0.30,
                  color: ColoresApp.blanco.withValues(alpha: 0.92),
                ),
              ),
            ),
            if (Navigator.canPop(context))
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                child: const _BotonVolver(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Aviso de error reutilizable dentro de los formularios de autenticación,
/// en reemplazo de un `Text` rojo plano.
class BannerError extends StatelessWidget {
  final String mensaje;

  const BannerError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.08),
        border: Border.all(color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: ColoresApp.rojoNoVerificado, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(color: ColoresApp.rojoNoVerificado, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de barritas del indicador de pasos del registro de abogado.
class _IndicadorPasos extends StatelessWidget {
  final int paso;
  final int totalPasos;

  const _IndicadorPasos({required this.paso, required this.totalPasos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalPasos, (indice) {
            final completadaOActiva = indice < paso;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: indice == totalPasos - 1 ? 0 : 6),
                height: 4,
                decoration: BoxDecoration(
                  color: completadaOActiva
                      ? ColoresApp.azulTurqui
                      : ColoresApp.grisTexto.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Paso $paso de $totalPasos',
          style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12),
        ),
      ],
    );
  }
}

/// Botón circular de vidrio para volver atrás, mostrado sobre el layout móvil.
class _BotonVolver extends StatelessWidget {
  const _BotonVolver();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.maybePop(context),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back, color: ColoresApp.blanco, size: 20),
        ),
      ),
    );
  }
}

/// Panel visual del layout de escritorio: gradiente de marca, orbes
/// decorativos, y el ícono + frase del motivo actual.
class _PanelVisual extends StatelessWidget {
  final IconData icono;
  final String frase;

  const _PanelVisual({required this.icono, required this.frase});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresApp.azulTurquiOscuro, ColoresApp.azulTurqui, ColoresApp.azulProfundo],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned(top: -70, right: -50, child: _Orbe(diametro: 200)),
          const Positioned(bottom: -90, left: -70, child: _Orbe(diametro: 220)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TarjetaCristal(
                    borderRadius: 32,
                    padding: const EdgeInsets.all(28),
                    child: Icon(icono, size: 180, color: ColoresApp.blanco.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    frase,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: ColoresApp.blanco,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo grande desenfocado usado como orbe decorativo, análogo al de
/// [FondoJuridico] pero privado a esta plantilla.
class _Orbe extends StatelessWidget {
  final double diametro;

  const _Orbe({required this.diametro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ColoresApp.azulBrillante.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
