// =============================================================================
// MÉTRICAS DE DEMOSTRACIÓN DEL PANEL DEL ABOGADO
// -----------------------------------------------------------------------------
// Este archivo ya no contiene ningún perfil ficticio: el perfil del abogado se
// carga de Firestore a través de ControladorPerfilAbogado.
//
// Lo único que queda son las tres métricas que todavía no se pueden calcular,
// porque dependen de módulos que no existen: no hay registro de visitas al
// perfil, no hay módulo de solicitudes y no hay registro de contactos. El
// panel las muestra marcadas como demostrativas para no presentarlas como si
// fueran datos reales. Las otras tres métricas del panel (verificación,
// reputación y completitud) sí salen de Firebase.
// =============================================================================

/// Métricas del bloque "Panel" que aún no tienen origen real.
class MetricasMockPanelAbogado {
  final int visualizaciones;
  final int solicitudesRecibidas;
  final int contactos;

  const MetricasMockPanelAbogado({
    required this.visualizaciones,
    required this.solicitudesRecibidas,
    required this.contactos,
  });
}

const MetricasMockPanelAbogado metricasMockPanelAbogado = MetricasMockPanelAbogado(
  visualizaciones: 128,
  solicitudesRecibidas: 12,
  contactos: 7,
);
