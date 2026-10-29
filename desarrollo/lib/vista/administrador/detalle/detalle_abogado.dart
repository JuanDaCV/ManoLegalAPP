import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../controlador/controlador_administrador.dart';
import '../../../controlador/filtros_administrador.dart';
import '../../../modelo/modelo_abogado.dart';
import '../../../modelo/modelo_perfil_abogado.dart';
import '../../../modelo/ubicacion_cali.dart';
import '../../compartido/widgets/avatar_abogado.dart';
import '../../tema/tema_app.dart';
import '../estilos_administrador.dart';
import '../fuentes_oficiales.dart';
import '../widgets/boton_copiar.dart';
import '../widgets/chip_estado_verificacion.dart';
import 'acciones_administrativas.dart';
import 'documentos_verificacion.dart';

/// Detalle administrativo de un abogado: identidad, contacto, datos
/// profesionales, documentos de verificación y acciones.
///
/// Recibe solo el [uid] y busca al abogado en la lista en tiempo real del
/// controlador en cada reconstrucción. Así, al verificarlo, el estado cambia
/// en pantalla por el propio stream de Firestore, sin cerrar el detalle.
///
/// Se muestra como panel lateral en escritorio y como pantalla completa en
/// móvil. Al eliminar la cuenta se cierra devolviendo el correo, para que el
/// panel muestre el aviso de que la cuenta de Authentication sigue activa.
class DetalleAbogado extends StatefulWidget {
  final String uid;
  final bool pantallaCompleta;

  const DetalleAbogado({super.key, required this.uid, required this.pantallaCompleta});

  @override
  State<DetalleAbogado> createState() => _DetalleAbogadoState();
}

class _DetalleAbogadoState extends State<DetalleAbogado> {
  /// Última versión conocida del abogado. Si desaparece del stream, por
  /// ejemplo mientras se elimina, el detalle la sigue mostrando con un aviso
  /// en lugar de quedar en blanco de golpe.
  ModeloAbogado? _ultimoConocido;
  AccionAdministrativa? _accionEnCurso;

  Future<void> _cambiarVerificacion(ModeloAbogado abogado, bool verificar) async {
    final administrador = context.read<ControladorAdministrador>();
    final mensajero = ScaffoldMessenger.of(context);

    setState(() => _accionEnCurso = AccionAdministrativa.verificacion);
    final error = await administrador.cambiarEstado(abogado.uid, verificar);
    if (mounted) setState(() => _accionEnCurso = null);

    mensajero.showSnackBar(
      SnackBar(content: Text(error ?? (verificar ? 'Abogado verificado.' : 'Abogado marcado como no verificado.'))),
    );
  }

  Future<void> _regenerarPerfil(ModeloAbogado abogado) async {
    final administrador = context.read<ControladorAdministrador>();
    final mensajero = ScaffoldMessenger.of(context);

    setState(() => _accionEnCurso = AccionAdministrativa.regeneracion);
    final error = await administrador.regenerarPerfilPublico(abogado.uid);
    if (mounted) setState(() => _accionEnCurso = null);

    mensajero.showSnackBar(SnackBar(content: Text(error ?? 'Perfil público actualizado en el buscador.')));
  }

  Future<void> _eliminar(ModeloAbogado abogado) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => _DialogoConfirmarEliminacion(abogado: abogado),
    );
    if (confirmado != true || !mounted) return;

    final administrador = context.read<ControladorAdministrador>();
    final mensajero = ScaffoldMessenger.of(context);
    // Se captura antes del `await`: al borrarse, el abogado sale del stream y
    // el detalle se reconstruye, pero su ruta sigue abierta hasta cerrarla.
    final navegador = Navigator.of(context);
    final correo = abogado.correo;

    setState(() => _accionEnCurso = AccionAdministrativa.eliminacion);
    final error = await administrador.eliminarAbogado(abogado.uid);

    if (error != null) {
      if (mounted) setState(() => _accionEnCurso = null);
      mensajero.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // Solo se cierra si Firebase aceptó el borrado. El correo permite al
    // panel mostrar el aviso de que la cuenta de Authentication sigue activa.
    navegador.pop(correo);
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAdministrador>();
    final actual = controlador.abogados.where((abogado) => abogado.uid == widget.uid).firstOrNull;
    if (actual != null) _ultimoConocido = actual;
    final abogado = actual ?? _ultimoConocido;
    final eliminado = actual == null && abogado != null && !controlador.cargandoAbogados;

    final Widget cuerpo;
    if (abogado == null) {
      cuerpo = _NoDisponible(cargando: controlador.cargandoAbogados);
    } else {
      final verificado = estaVerificado(abogado);
      cuerpo = Column(
        children: [
          _Cabecera(abogado: abogado, onCerrar: widget.pantallaCompleta ? null : () => Navigator.of(context).pop()),
          if (eliminado) const _AvisoEliminado(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _ContenidoDetalle(
                abogado: abogado,
                zonaRiesgo: ZonaRiesgoAbogado(
                  ocupada: eliminado || _accionEnCurso != null,
                  eliminando: _accionEnCurso == AccionAdministrativa.eliminacion,
                  onEliminar: () => _eliminar(abogado),
                ),
              ),
            ),
          ),
          BarraAccionesAdministrativas(
            verificado: verificado,
            accionEnCurso: _accionEnCurso,
            deshabilitada: eliminado,
            onCambiarVerificacion: () => _cambiarVerificacion(abogado, !verificado),
            onRegenerarPerfil: () => _regenerarPerfil(abogado),
            onCerrar: widget.pantallaCompleta ? null : () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    if (widget.pantallaCompleta) {
      return Scaffold(
        backgroundColor: ColoresApp.grisClaro,
        appBar: AppBar(
          title: const Text('Detalle del abogado'),
          backgroundColor: ColoresApp.azulTurquiOscuro,
        ),
        body: cuerpo,
      );
    }
    // Un Scaffold propio también en el panel lateral: así los avisos de las
    // acciones aparecen dentro del panel y no detrás de él.
    return Scaffold(backgroundColor: ColoresApp.grisClaro, body: cuerpo);
  }
}

class _Cabecera extends StatelessWidget {
  final ModeloAbogado abogado;
  final VoidCallback? onCerrar;

  const _Cabecera({required this.abogado, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    // Se reutiliza el modelo de presentación del perfil para las iniciales y
    // la foto. La foto se carga por URL, como en el resto de la app: el
    // panel anterior la pedía a Storage como si fuera una ruta y siempre
    // terminaba mostrando la inicial.
    final perfil = ModeloPerfilAbogado.desdeAbogadoPrivado(abogado);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: EstilosAdmin.degradadoMarca),
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarAbogado(iniciales: perfil.iniciales, fotoUrl: perfil.fotoUrl, tamanio: 58),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${abogado.nombre} ${abogado.apellido}',
                    style: EstilosAdmin.titulo(tamanio: 20, color: ColoresApp.blanco),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    abogado.especialidad.textoLegible,
                    style: const TextStyle(color: EstilosAdmin.textoSobreOscuro, fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  ChipEstadoVerificacion(verificado: estaVerificado(abogado), sobreFondoOscuro: true),
                ],
              ),
            ),
            if (onCerrar != null)
              IconButton(
                onPressed: onCerrar,
                tooltip: 'Cerrar detalle',
                icon: const Icon(Icons.close_rounded, color: ColoresApp.blanco),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoDetalle extends StatelessWidget {
  final ModeloAbogado abogado;
  final Widget zonaRiesgo;

  const _ContenidoDetalle({required this.abogado, required this.zonaRiesgo});

  @override
  Widget build(BuildContext context) {
    final perfil = ModeloPerfilAbogado.desdeAbogadoPrivado(abogado);
    final edad = perfil.edad;
    final tarifa = abogado.tarifa;
    final redes = [
      if (_tieneValor(abogado.instagram)) 'Instagram: ${abogado.instagram}',
      if (_tieneValor(abogado.facebook)) 'Facebook: ${abogado.facebook}',
      if (_tieneValor(abogado.linkedin)) 'LinkedIn: ${abogado.linkedin}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Bloque(
          titulo: 'Datos principales',
          icono: Icons.person_outline_rounded,
          child: _GrillaDatos(
            children: [
              _Dato(etiqueta: 'Correo', valor: abogado.correo, copiable: true),
              _Dato(etiqueta: 'Teléfono', valor: abogado.telefono),
              _Dato(etiqueta: 'Teléfono profesional', valor: abogado.telefonoProfesional),
              _Dato(etiqueta: 'Especialidad', valor: abogado.especialidad.textoLegible),
              _Dato(
                etiqueta: 'Experiencia',
                valor: abogado.aniosExperiencia == 1 ? '1 año' : '${abogado.aniosExperiencia} años',
              ),
              _Dato(
                etiqueta: 'Tarifa de consulta',
                valor: tarifa == null ? 'No publicada' : '\$${NumberFormat.decimalPattern('es_CO').format(tarifa)} COP',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Bloque(
          titulo: 'Documentos de verificación',
          icono: Icons.folder_open_rounded,
          child: DocumentosVerificacion(abogado: abogado),
        ),
        const SizedBox(height: 16),
        const _Bloque(
          titulo: 'Validar en fuentes oficiales',
          icono: Icons.travel_explore_rounded,
          child: _FuentesOficiales(),
        ),
        const SizedBox(height: 16),
        _Bloque(
          titulo: 'Identidad',
          icono: Icons.badge_outlined,
          child: _GrillaDatos(
            children: [
              _Dato(etiqueta: 'Nombre', valor: abogado.nombre),
              _Dato(etiqueta: 'Apellido', valor: abogado.apellido),
              _Dato(
                etiqueta: 'Fecha de nacimiento',
                valor: '${DateFormat('dd/MM/yyyy').format(abogado.fechaNacimiento)}'
                    '${edad == null ? '' : ' · $edad años'}',
              ),
              _Dato(etiqueta: 'UID', valor: abogado.uid, copiable: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Bloque(
          titulo: 'Perfil profesional',
          icono: Icons.work_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Dato(etiqueta: 'Descripción', valor: abogado.descripcion),
              const SizedBox(height: 14),
              _Dato(
                etiqueta: 'Experiencia profesional registrada',
                valor: abogado.experiencia.isEmpty
                    ? ''
                    : abogado.experiencia
                        .map((item) => item.anio == null ? item.titulo : '${item.titulo} (${item.anio})')
                        .join('\n'),
              ),
              if (redes.isNotEmpty) ...[
                const SizedBox(height: 14),
                _Dato(etiqueta: 'Redes', valor: redes.join('\n')),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Bloque(
          titulo: 'Ubicación',
          icono: Icons.place_outlined,
          child: _GrillaDatos(
            children: [
              _Dato(etiqueta: 'Zona', valor: abogado.ubicacionGeneral?.textoLegible ?? ''),
              _Dato(etiqueta: 'Sector', valor: abogado.sector),
              _Dato(etiqueta: 'Dirección profesional', valor: abogado.direccionProfesional),
            ],
          ),
        ),
        const SizedBox(height: 16),
        zonaRiesgo,
      ],
    );
  }

  static bool _tieneValor(String? valor) => valor != null && valor.trim().isNotEmpty;
}

/// Tarjeta blanca con título, usada por cada bloque del detalle.
class _Bloque extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;

  const _Bloque({required this.titulo, required this.icono, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EstilosAdmin.tarjeta.copyWith(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, size: 19, color: ColoresApp.azulTurqui),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Reparte los datos en dos columnas cuando hay ancho y en una cuando no.
class _GrillaDatos extends StatelessWidget {
  final List<Widget> children;

  const _GrillaDatos({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        const separacion = 16.0;
        final columnas = restricciones.maxWidth >= 420 ? 2 : 1;
        final ancho = (restricciones.maxWidth - separacion * (columnas - 1)) / columnas;
        return Wrap(
          spacing: separacion,
          runSpacing: 14,
          children: [for (final hijo in children) SizedBox(width: ancho, child: hijo)],
        );
      },
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool copiable;

  const _Dato({required this.etiqueta, required this.valor, this.copiable = false});

  @override
  Widget build(BuildContext context) {
    final vacio = valor.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(color: ColoresApp.grisTexto, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SelectableText(
                vacio ? 'No registrado' : valor,
                style: TextStyle(
                  color: vacio ? ColoresApp.grisTexto : ColoresApp.azulTurquiOscuro,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            if (copiable && !vacio) BotonCopiar(valor: valor, etiqueta: etiqueta),
          ],
        ),
      ],
    );
  }
}

class _FuentesOficiales extends StatelessWidget {
  const _FuentesOficiales();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambas consultas piden el número de documento del abogado. ManoLegal no lo guarda como dato: '
          'léelo en la cédula que cargó al registrarse. Los sitios se abren fuera de la aplicación y '
          'ManoLegal no consulta ni guarda sus resultados.',
          style: TextStyle(color: ColoresApp.grisTexto, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final fuente in fuentesOficialesVerificacion)
              Tooltip(
                message: '${fuente.entidad} · ${fuente.dominio}',
                child: OutlinedButton.icon(
                  onPressed: () => abrirFuenteOficial(context, fuente),
                  icon: Icon(fuente.icono, size: 18),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(fuente.titulo, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new_rounded, size: 14),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: BorderSide(color: ColoresApp.azulTurqui.withValues(alpha: 0.4)),
                    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AvisoEliminado extends StatelessWidget {
  const _AvisoEliminado();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColoresApp.rojoNoVerificado.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Text(
        'Este abogado ya no existe en la base de datos. Se muestra la última versión conocida.',
        style: TextStyle(color: ColoresApp.rojoNoVerificado, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _NoDisponible extends StatelessWidget {
  final bool cargando;

  const _NoDisponible({required this.cargando});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: cargando
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 40, color: ColoresApp.grisTexto),
                  const SizedBox(height: 12),
                  const Text(
                    'Este abogado ya no está disponible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColoresApp.azulTurquiOscuro, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
                ],
              ),
      ),
    );
  }
}

class _DialogoConfirmarEliminacion extends StatelessWidget {
  final ModeloAbogado abogado;

  const _DialogoConfirmarEliminacion({required this.abogado});

  @override
  Widget build(BuildContext context) {
    const estiloItem = TextStyle(color: ColoresApp.azulTurquiOscuro, fontSize: 14, height: 1.5);
    return AlertDialog(
      title: Text('¿Eliminar la cuenta de ${abogado.nombre} ${abogado.apellido}?'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Esta acción es permanente y borra:', style: estiloItem),
          SizedBox(height: 6),
          Text('•  Sus datos privados en Firestore', style: estiloItem),
          Text('•  Su perfil público en el buscador', style: estiloItem),
          Text('•  Sus documentos y su foto en Storage', style: estiloItem),
          SizedBox(height: 12),
          Text(
            'No borra su cuenta de inicio de sesión (Firebase Authentication): hay que eliminarla '
            'manualmente en Firebase Console.',
            style: TextStyle(color: ColoresApp.rojoNoVerificado, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresApp.rojoNoVerificado,
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const Text('Eliminar definitivamente'),
        ),
      ],
    );
  }
}
