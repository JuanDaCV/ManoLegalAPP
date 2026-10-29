import 'package:flutter/material.dart';

import '../../../../modelo/modelo_pqrs.dart';

/// Ícono de cada tipo de PQRS. Son los mismos que usaban las tarjetas de la
/// sección, así las tarjetas y el formulario hablan el mismo idioma visual.
IconData iconoTipoPqrs(TipoPqrs tipo) {
  return switch (tipo) {
    TipoPqrs.peticion => Icons.description_outlined,
    TipoPqrs.queja => Icons.sentiment_dissatisfied_outlined,
    TipoPqrs.reclamo => Icons.report_problem_outlined,
    TipoPqrs.solicitud => Icons.request_page_outlined,
  };
}
