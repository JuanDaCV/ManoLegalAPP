// Implementación para plataformas que no son Web.
//
// Reexporta sin cambios la implementación móvil y agrega las dos funciones de
// reserva de pestaña que usa la versión Web. Fuera del navegador no hay
// pestañas ni bloqueador de ventanas emergentes, así que no hacen nada.
export 'abridor_archivo_movil.dart';

/// Sin efecto fuera de Web. Ver la versión de `abridor_archivo_web.dart`.
bool reservarPestanaDocumento() => false;

/// Sin efecto fuera de Web. Ver la versión de `abridor_archivo_web.dart`.
void cancelarPestanaReservada() {}
