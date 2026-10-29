// Punto de entrada del almacén local: elige la implementación según la
// plataforma, con el mismo mecanismo que `abridor_archivo.dart`. En Web usa
// `localStorage` (no hay disco ni `path_provider`); en el resto, un archivo.
//
// Ambas implementaciones exponen `crearAlmacenLocal()`.
export 'almacen_local_base.dart';
export 'almacen_local_nativo.dart'
    if (dart.library.js_interop) 'almacen_local_web.dart';
