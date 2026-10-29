import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../tema/tema_app.dart';

/// Subtítulo por defecto de [BienvenidaPostLogin], usado cuando quien la usa
/// no pasa uno propio (por ejemplo, la bienvenida del cliente).
const String _subtituloPorDefecto =
    'Desde aquí puedes encontrar al abogado adecuado según lo que necesites, con información clara antes de decidir.';

/// Hero de bienvenida del panel post-login (cliente o abogado).
///
/// Usa como fondo `img/Background_PostLoginCliente.jpg`: una foto de una
/// oficina de abogados en tonos azul marino con detalles dorados. En la
/// pared del fondo de esa foto se lee "LEX & IUSTITIA ABOGADOS", una firma
/// ficticia de la imagen de stock, sin relación con ManoLegal, que no debe
/// competir con la marca propia. Por eso se superpone un velo degradado de
/// [ColoresApp.azulTurquiOscuro]: más opaco (~0.92) del lado donde va el
/// texto y más translúcido (~0.45) del lado opuesto en escritorio, para que
/// la foto siga aportando ambiente sin dejar leer el cartel ficticio y sin
/// comprometer el contraste del texto blanco. En móvil, con el texto
/// centrado, el velo es parejo (ambos lados ~0.85) en vez de direccional.
class BienvenidaPostLogin extends StatelessWidget {
  final String nombre;
  final bool esEscritorio;

  /// Subtítulo bajo el título de bienvenida. Si es `null`, se usa el texto
  /// por defecto (pensado para el cliente).
  final String? subtitulo;

  /// Título completo de la bienvenida. Si es `null`, se saluda por [nombre];
  /// el visitante web, que no tiene nombre, usa un saludo neutro.
  final String? titulo;

  const BienvenidaPostLogin({
    super.key,
    required this.nombre,
    required this.esEscritorio,
    this.subtitulo,
    this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: esEscritorio ? 320 : 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('img/Background_PostLoginCliente.jpg', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: esEscritorio ? Alignment.centerLeft : Alignment.topCenter,
                  end: esEscritorio ? Alignment.centerRight : Alignment.bottomCenter,
                  colors: [
                    ColoresApp.azulTurquiOscuro.withValues(alpha: esEscritorio ? 0.92 : 0.86),
                    ColoresApp.azulTurquiOscuro.withValues(alpha: esEscritorio ? 0.45 : 0.82),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: esEscritorio ? 48 : 24, vertical: 24),
              child: Column(
                crossAxisAlignment: esEscritorio ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: ColoresApp.dorado, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    titulo ?? 'Bienvenido a ManoLegal, $nombre',
                    textAlign: esEscritorio ? TextAlign.left : TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: ColoresApp.blanco,
                      fontWeight: FontWeight.w800,
                      fontSize: esEscritorio ? 30 : 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: esEscritorio ? 460 : 320),
                    child: Text(
                      subtitulo ?? _subtituloPorDefecto,
                      textAlign: esEscritorio ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(color: ColoresApp.blanco, fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
