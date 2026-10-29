/**
 * Proyección pública de un abogado: `tarjetasAbogados/{uid}`.
 *
 * Es lo único que un visitante web sin sesión puede leer del directorio. Las
 * reglas de Firestore no protegen campo por campo, así que en lugar de abrir
 * `perfilesPublicosAbogados` (que también tiene teléfonos, correo, dirección
 * y redes) se copia aquí solo lo que muestra la tarjeta del buscador y lo que
 * usa su búsqueda por texto.
 *
 * Funciones puras, sin Firebase: las usan el disparador (`tarjetas.js`), el
 * script de inicialización y las pruebas, así que las tres aplican
 * exactamente la misma lista blanca.
 */

/**
 * Lista blanca de campos de la tarjeta, en orden fijo. Cualquier campo que no
 * esté aquí nunca llega a la proyección pública.
 *
 * `sector` no se muestra: solo lo usa la búsqueda por texto del buscador
 * (`filtros_abogados.dart`).
 */
const CAMPOS_TARJETA = Object.freeze([
  'nombreCompleto',
  'nombreBusqueda',
  'fotoUrl',
  'especialidad',
  'ubicacionGeneral',
  'sector',
  'tarifa',
  'verificado',
  'calificacionPromedio',
  'cantidadResenas',
]);

function esTextoConContenido(valor) {
  return typeof valor === 'string' && valor.trim().length > 0;
}

function textoONulo(valor) {
  return typeof valor === 'string' ? valor : null;
}

function numeroFinitoONulo(valor) {
  return typeof valor === 'number' && Number.isFinite(valor) ? valor : null;
}

/**
 * Tarjeta pública de un perfil, o `null` si ese perfil no debe publicarse.
 *
 * Devuelve `null` si el abogado no está verificado (decisión de privacidad:
 * los pendientes nunca son visibles sin sesión) o si le faltan el nombre o la
 * especialidad, sin los cuales la tarjeta saldría rota.
 *
 * Sanea los tipos sin inventar datos: lo que no tiene el tipo esperado queda
 * en `null` (o en 0 para los agregados, que el buscador necesita presentes
 * porque ordena por la calificación y Firestore excluye de un `orderBy` los
 * documentos sin ese campo). Los opcionales se escriben siempre, con `null`
 * explícito, para que dos tarjetas del mismo perfil sean idénticas.
 */
function construirTarjeta(datos) {
  if (!datos || typeof datos !== 'object') return null;
  if (datos.verificado !== true) return null;
  if (!esTextoConContenido(datos.nombreCompleto)) return null;
  if (!esTextoConContenido(datos.especialidad)) return null;

  const calificacion = numeroFinitoONulo(datos.calificacionPromedio);
  const resenas = datos.cantidadResenas;

  return {
    nombreCompleto: datos.nombreCompleto,
    // Si falta, la app la deriva del nombre al leerla (`fromMap`): aquí no se
    // calcula para no duplicar esa normalización.
    nombreBusqueda: textoONulo(datos.nombreBusqueda),
    fotoUrl: textoONulo(datos.fotoUrl),
    especialidad: datos.especialidad,
    ubicacionGeneral: textoONulo(datos.ubicacionGeneral),
    sector: typeof datos.sector === 'string' ? datos.sector : '',
    tarifa: numeroFinitoONulo(datos.tarifa),
    verificado: true,
    calificacionPromedio: calificacion ?? 0,
    cantidadResenas: Number.isInteger(resenas) && resenas >= 0 ? resenas : 0,
  };
}

/**
 * Verdadero si las dos tarjetas tienen exactamente los mismos campos y
 * valores. Todos los valores de una tarjeta son primitivos, así que basta una
 * comparación estricta campo por campo. Un campo de más (por ejemplo, de una
 * versión anterior de la tarjeta) cuenta como diferencia, para que el
 * siguiente `set` lo elimine.
 */
function sonTarjetasIguales(a, b) {
  if (a == null || b == null) return a == null && b == null;
  const clavesA = Object.keys(a);
  const clavesB = Object.keys(b);
  if (clavesA.length !== clavesB.length) return false;
  return clavesA.every(
    (clave) => Object.prototype.hasOwnProperty.call(b, clave) && a[clave] === b[clave]
  );
}

module.exports = { CAMPOS_TARJETA, construirTarjeta, sonTarjetasIguales };
