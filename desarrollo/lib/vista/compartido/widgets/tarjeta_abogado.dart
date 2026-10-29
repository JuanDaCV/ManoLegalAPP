import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../modelo/modelo_paso_recorrido.dart';
import '../../../modelo/modelo_resultado_abogado.dart';
import '../../tema/tema_app.dart';
import 'avatar_abogado.dart';
import 'recorrido/ambito_recorrido.dart';

/// Tarjeta de resultado de búsqueda: resume los datos de un abogado y ofrece
/// acceso a su perfil. Cambia de layout horizontal (escritorio) a vertical
/// (móvil) sin perder ningún dato, y se mantiene compacta para poder
/// comparar varios resultados de un vistazo.
class TarjetaAbogado extends StatelessWidget {
  final ModeloResultadoAbogado abogado;
  final VoidCallback onVerPerfil;
  final bool esEscritorio;

  /// Marca la insignia "Verificado" y el botón "Ver perfil" para que el
  /// recorrido guiado pueda señalarlos. Solo lo activa la primera tarjeta de
  /// Inicio: el recorrido explica una tarjeta, no todas, y Lexus y la landing
  /// usan esta misma tarjeta sin recorrido. Sin un ámbito de recorrido encima,
  /// la marca no agrega nada al árbol.
  final bool marcarParaRecorrido;

  const TarjetaAbogado({
    super.key,
    required this.abogado,
    required this.onVerPerfil,
    required this.esEscritorio,
    this.marcarParaRecorrido = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarAbogado(
      iniciales: abogado.iniciales,
      fotoUrl: abogado.fotoUrl,
      tamanio: esEscritorio ? 72 : 64,
    );
    final datos = _DatosPrincipales(abogado: abogado, marcarInsignia: marcarParaRecorrido);
    final tarifaYBoton = _TarifaYBoton(
      abogado: abogado,
      onVerPerfil: onVerPerfil,
      esEscritorio: esEscritorio,
      marcarVerPerfil: marcarParaRecorrido,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: esEscritorio
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: datos),
                const SizedBox(width: 16),
                tarifaYBoton,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [avatar, const SizedBox(width: 12), Expanded(child: datos)]),
                const SizedBox(height: 14),
                tarifaYBoton,
              ],
            ),
    );
  }
}

class _DatosPrincipales extends StatelessWidget {
  final ModeloResultadoAbogado abogado;
  final bool marcarInsignia;

  const _DatosPrincipales({required this.abogado, this.marcarInsignia = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                abogado.nombreCompleto,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ColoresApp.azulTurquiOscuro),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (abogado.verificado) ...[
              const SizedBox(width: 8),
              if (marcarInsignia)
                const MarcaRecorrido(id: MarcaRecorridoId.insignia, child: _InsigniaVerificado())
              else
                const _InsigniaVerificado(),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(abogado.especialidad, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
        const SizedBox(height: 6),
        // Un abogado sin reseñas no muestra estrellas ni un número: pintar
        // cinco estrellas vacías o un 0.0 sugeriría una mala calificación, y
        // pintar 5.0 sugeriría una excelente. Ninguna de las dos es cierta.
        if (!abogado.tieneResenas)
          const Text(
            'Sin reseñas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColoresApp.grisTexto),
          )
        else
          Row(
            children: [
              _EstrellasCalificacion(calificacion: abogado.calificacion),
              const SizedBox(width: 6),
              Text(
                abogado.calificacion.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColoresApp.azulTurquiOscuro),
              ),
              const SizedBox(width: 4),
              Text(
                '(${abogado.cantidadResenas})',
                style: const TextStyle(fontSize: 12, color: ColoresApp.grisTexto),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: ColoresApp.grisTexto),
            const SizedBox(width: 4),
            Text(abogado.ubicacion, style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

/// Insignia "Verificado": nunca depende solo del color para transmitir el
/// estado (va siempre con ícono + texto).
class _InsigniaVerificado extends StatelessWidget {
  const _InsigniaVerificado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ColoresApp.verdeVerificado.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 13, color: ColoresApp.verdeVerificado),
          SizedBox(width: 4),
          Text('Verificado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ColoresApp.verdeVerificado)),
        ],
      ),
    );
  }
}

/// Fila de 5 estrellas (llenas/media/vacías) en dorado, según [calificacion].
class _EstrellasCalificacion extends StatelessWidget {
  final double calificacion;

  const _EstrellasCalificacion({required this.calificacion});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (indice) {
        final valorEstrella = indice + 1;
        final IconData icono;
        if (calificacion >= valorEstrella) {
          icono = Icons.star;
        } else if (calificacion >= valorEstrella - 0.5) {
          icono = Icons.star_half;
        } else {
          icono = Icons.star_border;
        }
        return Icon(icono, size: 16, color: ColoresApp.dorado);
      }),
    );
  }
}

class _TarifaYBoton extends StatelessWidget {
  final ModeloResultadoAbogado abogado;
  final VoidCallback onVerPerfil;
  final bool esEscritorio;
  final bool marcarVerPerfil;

  const _TarifaYBoton({
    required this.abogado,
    required this.onVerPerfil,
    required this.esEscritorio,
    this.marcarVerPerfil = false,
  });

  @override
  Widget build(BuildContext context) {
    // La tarifa es opcional. Mostrar "$0" cuando el abogado no la declaró
    // sería informar un precio que no existe, así que en ese caso se dice
    // explícitamente que no está publicada.
    final tarifa = abogado.tarifaDesde;
    final textoTarifa = tarifa == null
        ? 'Tarifa no publicada'
        : 'Desde \$${NumberFormat.decimalPattern('es_CO').format(tarifa)} COP';

    final botonVerPerfil = SizedBox(
      width: esEscritorio ? 140 : double.infinity,
      child: ElevatedButton(
        onPressed: onVerPerfil,
        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
        child: const Text('Ver perfil'),
      ),
    );

    final contenido = [
      Text(
        textoTarifa,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: tarifa == null ? ColoresApp.grisTexto : ColoresApp.azulTurquiOscuro,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 8),
      if (marcarVerPerfil)
        MarcaRecorrido(id: MarcaRecorridoId.verPerfil, child: botonVerPerfil)
      else
        botonVerPerfil,
    ];

    return esEscritorio
        ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: contenido)
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: contenido);
  }
}
