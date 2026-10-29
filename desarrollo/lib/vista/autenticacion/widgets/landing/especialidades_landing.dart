import 'package:flutter/material.dart';

import '../../../../modelo/especialidad_abogado.dart';
import '../../../tema/tema_app.dart';
import 'botones_landing.dart';
import 'caja_icono.dart';
import 'estilos_landing.dart';
import 'estructura_landing.dart';
import 'fila_altura_igual.dart';
import 'navegacion_landing.dart';
import 'revelar_al_desplazar.dart';
import 'tarjeta_landing.dart';

class _InfoEspecialidad {
  const _InfoEspecialidad(this.icono, this.descripcion, [this.etiqueta]);

  final IconData icono;
  final String descripcion;

  /// Si es nula se usa `textoLegible` de la especialidad.
  final String? etiqueta;
}

const Map<EspecialidadAbogado, _InfoEspecialidad> _info = {
  EspecialidadAbogado.laboral: _InfoEspecialidad(
    Icons.work_outline,
    'Contratos de trabajo, despidos, salarios y liquidaciones.',
  ),
  EspecialidadAbogado.penal: _InfoEspecialidad(
    Icons.shield_outlined,
    'Denuncias, defensa y procesos penales.',
  ),
  EspecialidadAbogado.comercial: _InfoEspecialidad(
    Icons.storefront_outlined,
    'Empresas, sociedades y contratos comerciales.',
  ),
  EspecialidadAbogado.civil: _InfoEspecialidad(
    Icons.handshake_outlined,
    'Contratos, deudas y responsabilidad civil.',
  ),
  EspecialidadAbogado.familia: _InfoEspecialidad(
    Icons.family_restroom,
    'Divorcios, custodia, alimentos y asuntos de familia.',
  ),
  EspecialidadAbogado.administrativo: _InfoEspecialidad(
    Icons.account_balance_outlined,
    'Trámites y conflictos con entidades públicas.',
  ),
  EspecialidadAbogado.inmobiliario: _InfoEspecialidad(
    Icons.home_work_outlined,
    'Compraventa, arrendamientos y propiedad raíz.',
  ),
  EspecialidadAbogado.otra: _InfoEspecialidad(
    Icons.more_horiz,
    'Otras especialidades que el abogado indica en su perfil.',
    'Otras áreas',
  ),
};

/// Rejilla con todas las especialidades con las que se registra un abogado.
class EspecialidadesLanding extends StatelessWidget {
  const EspecialidadesLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return SeccionBase(
      color: ColoresApp.grisClaro,
      builder: (context, t, util) {
        final columnas = switch (t) {
          TamanoLanding.compacto => util < 300 ? 1 : 2,
          TamanoLanding.medio => 2,
          _ => 4,
        };
        final especialidades = EspecialidadAbogado.values;
        final filas = <Widget>[];
        for (var i = 0; i < especialidades.length; i += columnas) {
          if (i > 0) {
            filas.add(
              SizedBox(
                height: columnas == 2 && t == TamanoLanding.compacto ? 12 : 20,
              ),
            );
          }
          filas.add(
            FilaAlturaIgual(
              espacio: t == TamanoLanding.compacto ? 12 : 20,
              children: [
                for (var j = 0; j < columnas; j++)
                  RevelarAlDesplazar(
                    retraso: Duration(milliseconds: 60 * j),
                    child: _TarjetaEspecialidad(
                      especialidad: especialidades[i + j],
                      // Dos columnas en un teléfono: tarjeta más compacta.
                      compacta: t == TamanoLanding.compacto && columnas == 2,
                    ),
                  ),
              ],
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RevelarAlDesplazar(
              child: EncabezadoSeccion(
                etiqueta: 'ESPECIALIDADES',
                titulo: 'Encuentra abogados por área del derecho',
                lead:
                    'Estas son las áreas con las que los abogados se '
                    'registran en ManoLegal.',
                tamano: t,
                centrado: true,
              ),
            ),
            const SizedBox(height: 56),
            ...filas,
            const SizedBox(height: 40),
            RevelarAlDesplazar(
              child: Column(
                children: [
                  Text(
                    'La disponibilidad en cada área depende de los abogados '
                    'registrados.',
                    textAlign: TextAlign.center,
                    style: EstilosLanding.cuerpo(
                      tamanio: 14,
                      color: EstilosLanding.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BotonLanding(
                    texto: 'Buscar por especialidad',
                    estilo: EstiloBotonLanding.oscuro,
                    alPresionar: () =>
                        NavegacionLanding.irAExplorar(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaEspecialidad extends StatelessWidget {
  const _TarjetaEspecialidad({
    required this.especialidad,
    this.compacta = false,
  });

  final EspecialidadAbogado especialidad;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final info = _info[especialidad]!;
    return TarjetaLanding(
      padding: EdgeInsets.all(compacta ? 16 : 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CajaIcono(icono: info.icono, conPunto: true),
            SizedBox(height: compacta ? 14 : 20),
            Text(
              info.etiqueta ?? especialidad.textoLegible,
              style: EstilosLanding.titulo(
                tamanio: compacta ? 15.5 : 18,
                alto: 1.25,
                espaciado: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.descripcion,
              style: EstilosLanding.cuerpo(
                tamanio: compacta ? 13.5 : 15,
                color: EstilosLanding.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
