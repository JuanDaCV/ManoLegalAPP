/**
 * Tarjetas públicas de abogados: mantiene `tarjetasAbogados/{uid}` al día con
 * `perfilesPublicosAbogados/{uid}`, que es su única fuente.
 *
 * Las reglas de Firestore prohíben a todo usuario escribir en
 * `tarjetasAbogados`; el Admin SDK que usa esta función no pasa por esas
 * reglas, así que es el único camino por el que una tarjeta aparece, cambia o
 * desaparece. Qué campos lleva la tarjeta lo decide `tarjetas_proyeccion.js`.
 */

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { getFirestore } = require('firebase-admin/firestore');

const { construirTarjeta, sonTarjetasIguales } = require('./tarjetas_proyeccion');

// Misma región que la base de datos y que las demás funciones: un disparador
// de Firestore de segunda generación debe vivir en esa región.
const REGION = 'us-east1';

/**
 * Crea, actualiza o borra la tarjeta pública de un abogado cada vez que su
 * perfil público se escribe.
 *
 * No usa los datos del evento: vuelve a leer el perfil. Los eventos pueden
 * llegar repetidos o en otro orden, y así el resultado siempre refleja el
 * estado actual del perfil, sin importar cuál llegó primero.
 *
 * La tarjeta se reescribe completa (`set` sin `merge`), y solo si cambió: un
 * campo que ya no esté en la lista blanca desaparece, y un evento que no
 * cambia nada visible no gasta una escritura.
 *
 * No hay bucle con `recalcularCalificacionAbogado`: esa función reescribe el
 * perfil, este disparador corre una vez y escribe en otra colección, que no
 * dispara a ninguna de las dos.
 */
exports.sincronizarTarjetaAbogado = onDocumentWritten(
  { document: 'perfilesPublicosAbogados/{uid}', region: REGION },
  async (event) => {
    const db = getFirestore();
    const uid = event.params.uid;
    const referenciaTarjeta = db.doc(`tarjetasAbogados/${uid}`);

    const [perfil, tarjetaActual] = await Promise.all([
      db.doc(`perfilesPublicosAbogados/${uid}`).get(),
      referenciaTarjeta.get(),
    ]);

    // Perfil borrado, no verificado o incompleto: no debe tener tarjeta.
    const tarjeta = perfil.exists ? construirTarjeta(perfil.data()) : null;
    if (!tarjeta) {
      if (tarjetaActual.exists) {
        await referenciaTarjeta.delete();
        logger.info(`Perfil ${uid}: tarjeta pública retirada.`);
      }
      return;
    }

    if (tarjetaActual.exists && sonTarjetasIguales(tarjetaActual.data(), tarjeta)) {
      logger.info(`Perfil ${uid}: la tarjeta pública ya estaba al día.`);
      return;
    }

    await referenciaTarjeta.set(tarjeta);
    logger.info(`Perfil ${uid}: tarjeta pública ${tarjetaActual.exists ? 'actualizada' : 'creada'}.`);
  }
);
