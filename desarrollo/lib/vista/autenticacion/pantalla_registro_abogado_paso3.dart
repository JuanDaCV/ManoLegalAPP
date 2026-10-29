import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_autenticacion.dart';
import '../../modelo/modelo_abogado.dart';
import '../../modelo/modelo_archivo_adjunto.dart';
import '../../modelo/modelo_documento_abogado.dart';
import '../../modelo/ubicacion_cali.dart';
import '../tema/tema_app.dart';
import '../widgets_comunes/boton_personalizado.dart';
import '../widgets_comunes/plantilla_autenticacion.dart';
import '../widgets_comunes/selector_documento.dart';

/// Paso 3 (final) del registro de abogado: documentos de verificación.
class PantallaRegistroAbogadoPaso3 extends StatefulWidget {
  final String nombre;
  final String apellido;
  final DateTime fechaNacimiento;
  final String telefono;
  final String correo;

  /// `null` cuando el usuario se registró con Google: en ese caso se llama
  /// a `completarRegistroAbogadoGoogle` en vez de `registrarAbogado`.
  final String? contrasena;
  final String telefonoProfesional;
  final EspecialidadAbogado especialidad;
  final int aniosExperiencia;
  final double? tarifa;
  final String descripcion;

  /// Zona general de atención, usada por el buscador y los filtros.
  final UbicacionCali? ubicacionGeneral;

  /// Sector o barrio dentro de la zona. Opcional.
  final String sector;

  /// Dirección concreta de la oficina de atención. Opcional, y distinta de
  /// [ubicacionGeneral]: esta es el lugar exacto, aquella la referencia
  /// amplia que se muestra en la tarjeta de resultados.
  final String direccionProfesional;

  final ModeloArchivoAdjunto? fotoPerfil;

  const PantallaRegistroAbogadoPaso3({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.telefono,
    required this.correo,
    required this.contrasena,
    required this.telefonoProfesional,
    required this.especialidad,
    required this.aniosExperiencia,
    required this.tarifa,
    required this.descripcion,
    required this.ubicacionGeneral,
    required this.sector,
    required this.direccionProfesional,
    required this.fotoPerfil,
  });

  @override
  State<PantallaRegistroAbogadoPaso3> createState() => _PantallaRegistroAbogadoPaso3State();
}

class _PantallaRegistroAbogadoPaso3State extends State<PantallaRegistroAbogadoPaso3> {
  ModeloArchivoAdjunto? _cedula;
  ModeloArchivoAdjunto? _tarjetaProfesional;
  ModeloArchivoAdjunto? _certificadoRna;
  ModeloArchivoAdjunto? _diploma;
  ModeloArchivoAdjunto? _antecedentes;

  bool get _documentosObligatoriosCompletos =>
      _cedula != null && _tarjetaProfesional != null && _certificadoRna != null && _antecedentes != null;

  Future<void> _finalizarRegistro() async {
    final controlador = context.read<ControladorAutenticacion>();

    final archivos = <String, ModeloArchivoAdjunto>{
      'cedula': _cedula!,
      'tarjeta_profesional': _tarjetaProfesional!,
      'certificado_rna': _certificadoRna!,
      'antecedentes': _antecedentes!,
    };
    if (_diploma != null) archivos['diploma'] = _diploma!;
    if (widget.fotoPerfil != null) archivos['foto_perfil'] = widget.fotoPerfil!;

    final abogadoSinRutas = ModeloAbogado(
      uid: '',
      nombre: widget.nombre,
      apellido: widget.apellido,
      fechaNacimiento: widget.fechaNacimiento,
      telefono: widget.telefono,
      correo: widget.correo,
      telefonoProfesional: widget.telefonoProfesional,
      especialidad: widget.especialidad,
      aniosExperiencia: widget.aniosExperiencia,
      tarifa: widget.tarifa,
      descripcion: widget.descripcion,
      fotoPerfilRuta: '',
      documentos: const ModeloDocumentoAbogado(
        cedulaRuta: '',
        tarjetaProfesionalRuta: '',
        certificadoRnaRuta: '',
        antecedentesRuta: '',
      ),
      estado: 'pendiente',
      ubicacionGeneral: widget.ubicacionGeneral,
      sector: widget.sector,
      direccionProfesional: widget.direccionProfesional,
      correoContacto: widget.correo,
    );

    final contrasena = widget.contrasena;
    final ok = contrasena == null
        ? await controlador.completarRegistroAbogadoGoogle(abogadoSinRutas, archivos)
        : await controlador.registrarAbogado(abogadoSinRutas, contrasena, archivos);
    if (ok && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorAutenticacion>();

    return PlantillaAutenticacion(
      motivo: MotivoAutenticacion.abogadoDocumentos,
      titulo: 'Verifica tu identidad',
      subtitulo: 'Sube tus documentos para que tu perfil quede verificado ante los clientes.',
      paso: 3,
      totalPasos: 3,
      formulario: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver'),
            ),
          ),
          const Text(
            'Solo se aceptan archivos PDF de máximo 1 MB por documento.',
            style: TextStyle(color: ColoresApp.grisTexto, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SelectorDocumento(
            etiqueta: 'Cédula',
            esObligatorio: true,
            onArchivoSeleccionado: (archivo) => setState(() => _cedula = archivo),
          ),
          SelectorDocumento(
            etiqueta: 'Tarjeta profesional',
            esObligatorio: true,
            onArchivoSeleccionado: (archivo) => setState(() => _tarjetaProfesional = archivo),
          ),
          SelectorDocumento(
            etiqueta: 'Certificado RNA/SIRNA',
            esObligatorio: true,
            onArchivoSeleccionado: (archivo) => setState(() => _certificadoRna = archivo),
          ),
          SelectorDocumento(
            etiqueta: 'Diploma',
            esObligatorio: false,
            onArchivoSeleccionado: (archivo) => setState(() => _diploma = archivo),
          ),
          SelectorDocumento(
            etiqueta: 'Antecedentes disciplinarios',
            esObligatorio: true,
            onArchivoSeleccionado: (archivo) => setState(() => _antecedentes = archivo),
          ),
          if (controlador.mensajeError != null) ...[
            const SizedBox(height: 4),
            BannerError(mensaje: controlador.mensajeError!),
          ],
          const SizedBox(height: 24),
          BotonPersonalizado(
            texto: 'Finalizar registro',
            cargando: controlador.cargando,
            onPressed: _documentosObligatoriosCompletos ? _finalizarRegistro : null,
          ),
        ],
      ),
    );
  }
}
