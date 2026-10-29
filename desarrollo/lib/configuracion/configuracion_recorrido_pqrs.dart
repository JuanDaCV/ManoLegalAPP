import '../modelo/modelo_paso_recorrido.dart';
import '../modelo/modelo_recorrido.dart';
import 'configuracion_recorrido_cliente.dart';

/// Recorrido guiado de PQRS. La sección es idéntica para el cliente y el
/// abogado, así que hay una sola configuración; cada usuario guarda su propio
/// estado (la clave lleva el uid).
abstract final class ConfiguracionRecorridoPqrs {
  static const ModeloRecorrido pqrs = ModeloRecorrido(
    id: 'compartido.pqrs',
    prefijoClave: 'manolegal.recorrido.compartido.pqrs.v1.',
    pasos: pasos,
    marcaInicial: MarcaRecorridoId.pqrsCategorias,
    esperaInicial: ConfiguracionRecorridoCliente.esperaBuscador,
    esperaCarga: ConfiguracionRecorridoCliente.esperaResultados,
  );

  /// Solo señala: tocar una categoría o «Radicar una PQRS» abriría el
  /// formulario, y eso lo decide el usuario.
  static const List<ModeloPasoRecorrido> pasos = [
    ModeloPasoRecorrido(
      id: 'bienvenida',
      tipo: TipoPasoRecorrido.bienvenida,
      titulo: 'PQRS',
      descripcion: 'Aquí puedes enviar a ManoLegal peticiones, quejas, reclamos y solicitudes. Te mostramos cómo.',
    ),
    ModeloPasoRecorrido(
      id: 'categorias',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.pqrsCategorias,
      titulo: 'Elige una categoría',
      descripcion: 'Toca la categoría que mejor describe tu caso: Peticiones, Quejas, Reclamos o Solicitudes. Se abre el formulario con ese tipo ya elegido.',
    ),
    ModeloPasoRecorrido(
      id: 'radicar',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.pqrsRadicar,
      titulo: 'Radica una PQRS',
      descripcion: 'Si no sabes qué categoría elegir, toca «Radicar una PQRS» y escoge el tipo dentro del formulario.',
    ),
    ModeloPasoRecorrido(
      id: 'radicado',
      tipo: TipoPasoRecorrido.resaltado,
      marca: MarcaRecorridoId.pqrsNotaRadicado,
      titulo: 'Tu número de radicado',
      descripcion: 'Cuando la envíes, recibirás tu número de radicado en pantalla y en tu correo.',
    ),
    ModeloPasoRecorrido(
      id: 'cierre',
      tipo: TipoPasoRecorrido.cierre,
      titulo: 'Listo',
      descripcion: 'Ya sabes cómo radicar una PQRS cuando la necesites.',
    ),
  ];
}
