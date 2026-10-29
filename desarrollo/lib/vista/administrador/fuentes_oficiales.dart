import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Una plataforma oficial externa que el administrador consulta para
/// confirmar la situación profesional de un abogado.
///
/// ManoLegal solo abre la página oficial: no hace scraping, no automatiza el
/// formulario, no rellena datos, no guarda resultados y no introduce
/// credenciales. La consulta la hace el administrador en el sitio oficial.
class FuenteOficialVerificacion {
  final String titulo;
  final String entidad;
  final String descripcion;
  final String url;
  final IconData icono;

  const FuenteOficialVerificacion({
    required this.titulo,
    required this.entidad,
    required this.descripcion,
    required this.url,
    required this.icono,
  });

  Uri get direccion => Uri.parse(url);

  /// Dominio visible, para que el administrador sepa a qué sitio va a salir.
  String get dominio => direccion.host;
}

/// Consulta de sanciones vigentes y antecedentes disciplinarios de abogados.
///
/// URL verificada el 24/09/2026. La Comisión Nacional de Disciplina Judicial
/// opera ahora bajo el dominio `cndj.gov.co`; la consulta pide tipo y número
/// de documento del abogado.
const FuenteOficialVerificacion fuenteAntecedentesDisciplinarios = FuenteOficialVerificacion(
  titulo: 'Antecedentes disciplinarios',
  entidad: 'Comisión Nacional de Disciplina Judicial',
  descripcion: 'Consulta de sanciones vigentes y antecedentes disciplinarios de abogados.',
  url: 'https://antecedentesdisciplinarios.cndj.gov.co/',
  icono: Icons.policy_outlined,
);

/// Certificado de vigencia de la tarjeta profesional de abogado.
///
/// URL verificada el 24/09/2026. La dirección histórica del SIRNA,
/// `https://sirna.ramajudicial.gov.co/Paginas/Certificado.aspx`, responde hoy
/// 404: el servicio vigente es este. Pide la calidad (abogado), el tipo y el
/// número de documento.
const FuenteOficialVerificacion fuenteVigenciaProfesional = FuenteOficialVerificacion(
  titulo: 'Vigencia profesional',
  entidad: 'Rama Judicial · Registro Nacional de Abogados',
  descripcion: 'Certificado de vigencia de la tarjeta profesional de abogado.',
  url: 'https://vigenciaspublicas.ramajudicial.gov.co/Certificados.aspx',
  icono: Icons.badge_outlined,
);

const List<FuenteOficialVerificacion> fuentesOficialesVerificacion = [
  fuenteAntecedentesDisciplinarios,
  fuenteVigenciaProfesional,
];

/// Abre la fuente oficial fuera de la aplicación: una pestaña nueva en Web y
/// el navegador del sistema en móvil. Si no se puede abrir, lo informa.
Future<void> abrirFuenteOficial(BuildContext context, FuenteOficialVerificacion fuente) async {
  final mensajero = ScaffoldMessenger.of(context);
  void informarFallo() {
    mensajero.showSnackBar(
      SnackBar(content: Text('No se pudo abrir ${fuente.dominio}. Revisa tu conexión e inténtalo de nuevo.')),
    );
  }

  try {
    final abierta = await launchUrl(fuente.direccion, mode: LaunchMode.externalApplication);
    if (!abierta) informarFallo();
  } catch (_) {
    informarFallo();
  }
}
