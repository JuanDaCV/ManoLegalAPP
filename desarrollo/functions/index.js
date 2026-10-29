/**
 * Cloud Functions de ManoLegal V2. La de PQRS vive en pqrs.js.
 *
 * La función de calificaciones existe por una razón concreta de seguridad:
 * el promedio de calificación de un abogado no puede calcularse ni escribirse
 * desde el cliente, porque cualquier cliente podría falsificarlo.
 *
 * Las reglas de Firestore prohíben a TODO usuario escribir
 * `calificacionPromedio` y `cantidadResenas`. El Admin SDK que usa esta
 * función no pasa por esas reglas, así que es el único camino por el que esos
 * dos campos cambian.
 */

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();

// Firestore se obtiene dentro del manejador, no en el ámbito del módulo.
// Durante el despliegue, la CLI carga este archivo para descubrir las
// funciones y aborta si esa carga tarda más de 10 segundos; inicializar
// clientes pesados aquí arriba provoca ese tiempo de espera.
// Ver https://firebase.google.com/docs/functions/tips#avoid_deployment_timeouts_during_initialization

// La base de datos de Firestore del proyecto vive en us-east1. Un disparador
// de Firestore de segunda generación debe desplegarse en la misma región.
const REGION = 'us-east1';

const RUTA_RESENAS = 'perfilesPublicosAbogados/{abogadoUid}/resenas/{clienteUid}';

/**
 * Recalcula el promedio y la cantidad de reseñas de un abogado cada vez que
 * una de sus reseñas se crea, se edita o se borra.
 *
 * Recalcula sobre el total en lugar de aplicar un incremento: es un poco más
 * costoso, pero es autocorrectivo. Si una reseña se borra desde la consola de
 * Firebase o una escritura anterior falló a medias, el siguiente evento deja
 * el agregado correcto igual.
 */
exports.recalcularCalificacionAbogado = onDocumentWritten(
  { document: RUTA_RESENAS, region: REGION },
  async (event) => {
    const db = getFirestore();
    const abogadoUid = event.params.abogadoUid;
    const referenciaPerfil = db.doc(`perfilesPublicosAbogados/${abogadoUid}`);

    // Si el perfil público no existe, no se crea uno a medias: un documento
    // con solo estos dos campos aparecería roto en el buscador.
    const perfil = await referenciaPerfil.get();
    if (!perfil.exists) {
      logger.warn(
        `No existe el perfil público ${abogadoUid}; se omite el recálculo.`
      );
      return;
    }

    const resenas = await db
      .collection(`perfilesPublicosAbogados/${abogadoUid}/resenas`)
      .get();

    let suma = 0;
    let cantidad = 0;

    resenas.forEach((documento) => {
      const calificacion = documento.get('calificacion');
      // Ignora cualquier valor fuera de rango en lugar de contaminar el
      // promedio. Las reglas ya lo impiden, pero el agregado no debe depender
      // exclusivamente de ellas.
      if (
        typeof calificacion === 'number' &&
        Number.isInteger(calificacion) &&
        calificacion >= 1 &&
        calificacion <= 5
      ) {
        suma += calificacion;
        cantidad += 1;
      }
    });

    // Sin reseñas el promedio es 0, nunca 5. El campo se mantiene presente
    // (no ausente) porque el buscador ordena por él, y Firestore excluye de
    // un orderBy los documentos que no tienen el campo.
    const promedio =
      cantidad === 0 ? 0 : Math.round((suma / cantidad) * 100) / 100;

    await referenciaPerfil.set(
      { calificacionPromedio: promedio, cantidadResenas: cantidad },
      { merge: true }
    );

    logger.info(
      `Perfil ${abogadoUid}: ${cantidad} reseñas, promedio ${promedio}.`
    );
  }
);

// PQRS: radicado y correo de confirmación. Ver pqrs.js.
exports.procesarNuevaPqrs = require('./pqrs').procesarNuevaPqrs;

// Tarjetas públicas de abogados para visitantes sin sesión. Ver tarjetas.js.
exports.sincronizarTarjetaAbogado = require('./tarjetas').sincronizarTarjetaAbogado;
