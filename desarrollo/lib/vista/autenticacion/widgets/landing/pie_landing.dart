import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../configuracion/configuracion_landing.dart';
import '../../../tema/tema_app.dart';
import 'barra_landing.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'navegacion_landing.dart';
import 'simbolo_manolegal.dart';

/// Pie de página sobre el azul más profundo de la paleta.
class PieLanding extends StatelessWidget {
  const PieLanding({super.key, required this.alIrA, required this.alDescargar});

  final void Function(SeccionLanding) alIrA;
  final VoidCallback alDescargar;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EstilosLanding.noche,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 1,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00C9A227),
                    Color(0x99C9A227),
                    Color(0x00C9A227),
                  ],
                ),
              ),
            ),
          ),
          SeccionBase(
            relleno: 64,
            builder: (context, t, util) {
              final marca = _ColumnaMarca();
              final plataforma = _Columna(
                titulo: 'Plataforma',
                hijos: [
                  for (final s in SeccionLanding.values)
                    _EnlacePie(texto: s.etiqueta, alTocar: () => alIrA(s)),
                ],
              );
              final cuenta = _Columna(
                titulo: 'Cuenta',
                hijos: [
                  _EnlacePie(
                    texto: 'Ingresar',
                    alTocar: () => NavegacionLanding.irAInicioSesion(context),
                  ),
                  _EnlacePie(
                    texto: 'Crear cuenta',
                    alTocar: () => NavegacionLanding.irARegistro(context),
                  ),
                  _EnlacePie(texto: 'Descargar la app', alTocar: alDescargar),
                ],
              );
              const contacto = _ColumnaContacto();
              final Widget columnas = switch (t) {
                TamanoLanding.compacto => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    marca,
                    const SizedBox(height: 40),
                    plataforma,
                    const SizedBox(height: 32),
                    cuenta,
                    const SizedBox(height: 32),
                    contacto,
                  ],
                ),
                TamanoLanding.medio => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: marca),
                        const SizedBox(width: 32),
                        Expanded(child: plataforma),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cuenta),
                        const SizedBox(width: 32),
                        const Expanded(child: contacto),
                      ],
                    ),
                  ],
                ),
                _ => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: marca),
                    const SizedBox(width: 48),
                    Expanded(flex: 2, child: plataforma),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: cuenta),
                    const SizedBox(width: 24),
                    const Expanded(flex: 3, child: contacto),
                  ],
                ),
              };
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  columnas,
                  const SizedBox(height: 48),
                  const Divider(height: 1, color: Color(0x14FFFFFF)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '© ${DateTime.now().year} ManoLegal · Cali, Colombia',
                      style: const TextStyle(
                        fontSize: 13,
                        color: EstilosLanding.textoSobreAzulSuave,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColumnaMarca extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const MarcaLanding(),
        const SizedBox(height: 20),
        Text(
          'Justicia accesible, verificada.',
          style: EstilosLanding.titulo(
            tamanio: 18,
            color: ColoresApp.blanco,
            alto: 1.3,
            espaciado: 0,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            'Directorio de abogados en Cali con verificación documental y '
            'orientación inicial con IA.',
            style: EstilosLanding.cuerpo(
              tamanio: 14.5,
              color: EstilosLanding.textoSobreAzulSuave,
            ),
          ),
        ),
      ],
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(titulo, style: _estiloTituloColumna),
        ),
        const SizedBox(height: 8),
        ...hijos,
      ],
    );
  }
}

const TextStyle _estiloTituloColumna = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
  color: ColoresApp.blanco,
);

class _EnlacePie extends StatelessWidget {
  const _EnlacePie({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) =>
                estados.contains(WidgetState.hovered) ||
                    estados.contains(WidgetState.focused)
                ? ColoresApp.blanco
                : ColoresApp.blanco.withValues(alpha: 0.78),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          alignment: Alignment.centerLeft,
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        onPressed: alTocar,
        child: Text(texto, textAlign: TextAlign.start),
      ),
    );
  }
}

class _ColumnaContacto extends StatelessWidget {
  const _ColumnaContacto();

  static const TextStyle _estiloTexto = TextStyle(
    fontSize: 14.5,
    height: 1.55,
    color: EstilosLanding.textoSobreAzulSuave,
  );

  @override
  Widget build(BuildContext context) {
    final redes = ConfiguracionLanding.redesSociales();
    final todasPendientes = redes.every((r) => !r.disponible);
    final correo = ConfiguracionLanding.correoContacto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: const Text('Contacto', style: _estiloTituloColumna),
        ),
        const SizedBox(height: 12),
        const Text(
          'Peticiones, quejas o reclamos: sección PQRS, después de ingresar.',
          style: _estiloTexto,
        ),
        if (correo != null) ...[
          const SizedBox(height: 8),
          SelectableText(correo, style: _estiloTexto),
        ],
        const SizedBox(height: 8),
        const Text('Cali, Colombia', style: _estiloTexto),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: const Text('Redes', style: _estiloTituloColumna),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final red in redes) _BotonRed(red: red)],
        ),
        if (todasPendientes) ...[
          const SizedBox(height: 12),
          const Text('Redes oficiales: próximamente', style: _estiloTexto),
        ],
      ],
    );
  }
}

class _BotonRed extends StatelessWidget {
  const _BotonRed({required this.red});

  final OpcionEnlace red;

  FaIconData get _icono => switch (red.tipo) {
    TipoEnlace.instagram => FontAwesomeIcons.instagram,
    TipoEnlace.facebook => FontAwesomeIcons.facebook,
    TipoEnlace.tiktok => FontAwesomeIcons.tiktok,
    _ => FontAwesomeIcons.xTwitter,
  };

  @override
  Widget build(BuildContext context) {
    final icono = FaIcon(_icono, size: 18, color: ColoresApp.blanco);
    final decoracion = BoxDecoration(
      shape: BoxShape.circle,
      color: ColoresApp.blanco.withValues(alpha: 0.10),
      border: Border.all(color: ColoresApp.blanco.withValues(alpha: 0.18)),
    );
    if (!red.disponible) {
      return Opacity(
        opacity: 0.45,
        child: Tooltip(
          message: '${red.nombre}: próximamente',
          child: Semantics(
            label: '${red.nombre}: próximamente',
            enabled: false,
            excludeSemantics: true,
            child: SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: decoracion,
                child: Center(child: icono),
              ),
            ),
          ),
        ),
      );
    }
    return Tooltip(
      message: '${red.nombre} (se abre en una pestaña nueva)',
      child: SizedBox(
        width: 44,
        height: 44,
        child: DecoratedBox(
          decoration: decoracion,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => NavegacionLanding.abrirEnlace(red.url),
            icon: icono,
          ),
        ),
      ),
    );
  }
}
