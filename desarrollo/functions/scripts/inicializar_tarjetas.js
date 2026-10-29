/**
 * Inicializa (o repara) `tarjetasAbogados` a partir de
 * `perfilesPublicosAbogados`.
 *
 * El disparador `sincronizarTarjetaAbogado` solo actúa cuando un perfil se
 * escribe; los abogados que ya existían antes de desplegarlo no tienen
 * tarjeta hasta que su perfil vuelva a cambiar. Este script las crea de una
 * vez con la misma `construirTarjeta` del disparador, así que el resultado es
 * idéntico. Es idempotente: ejecutarlo dos veces no cambia nada la segunda.
 *
 * Uso, desde `desarrollo/`:
 *
 *   Simulación (por defecto, no escribe nada; solo cuenta):
 *     node functions/scripts/inicializar_tarjetas.js
 *
 *   Aplicar los cambios:
 *     node functions/scripts/inicializar_tarjetas.js --aplicar
 *
 *   Contra el emulador de Firestore (recomendado para probar):
 *     FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=demo-manolegal \
 *       node functions/scripts/inicializar_tarjetas.js
 *
 * ADVERTENCIA: sin FIRESTORE_EMULATOR_HOST se conecta al proyecto REAL con las
 * credenciales por defecto de la máquina. Ejecutarlo contra producción
 * requiere autorización explícita, y siempre primero en simulación para
 * revisar los conteos antes de usar --aplicar.
 *
 * Solo imprime conteos: nunca nombres, correos ni ningún otro dato personal.
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const { construirTarjeta, sonTarjetasIguales } = require('../tarjetas_proyeccion');

const PROYECTO = process.env.GCLOUD_PROJECT || 'claude-manolegal';

// Un lote de Firestore admite hasta 500 operaciones; se deja margen.
const OPERACIONES_POR_LOTE = 400;

/** Qué haría el script con cada tarjeta, sin escribir nada todavía. */
function planificar(perfiles, tarjetas) {
  const plan = { escrituras: [], borrados: [], creadas: 0, actualizadas: 0, sinCambios: 0, omitidos: 0 };

  for (const perfil of perfiles.docs) {
    const tarjeta = construirTarjeta(perfil.data());
    const actual = tarjetas.get(perfil.id);
    if (!tarjeta) {
      // No verificado o incompleto: no se publica, y si tenía tarjeta se retira.
      plan.omitidos += 1;
      if (actual) plan.borrados.push(perfil.id);
    } else if (actual && sonTarjetasIguales(actual, tarjeta)) {
      plan.sinCambios += 1;
    } else {
      plan.escrituras.push({ uid: perfil.id, tarjeta });
      if (actual) plan.actualizadas += 1;
      else plan.creadas += 1;
    }
  }

  // Tarjetas cuyo perfil ya no existe.
  const conPerfil = new Set(perfiles.docs.map((perfil) => perfil.id));
  for (const uid of tarjetas.keys()) {
    if (!conPerfil.has(uid)) plan.borrados.push(uid);
  }
  return plan;
}

async function aplicar(db, plan) {
  const operaciones = [
    ...plan.escrituras.map(({ uid, tarjeta }) => (lote) => lote.set(db.doc(`tarjetasAbogados/${uid}`), tarjeta)),
    ...plan.borrados.map((uid) => (lote) => lote.delete(db.doc(`tarjetasAbogados/${uid}`))),
  ];
  for (let inicio = 0; inicio < operaciones.length; inicio += OPERACIONES_POR_LOTE) {
    const lote = db.batch();
    operaciones.slice(inicio, inicio + OPERACIONES_POR_LOTE).forEach((operar) => operar(lote));
    await lote.commit();
  }
}

async function main() {
  const escribir = process.argv.includes('--aplicar');
  const emulador = process.env.FIRESTORE_EMULATOR_HOST;

  console.log(
    emulador
      ? `Destino: emulador de Firestore en ${emulador} (proyecto ${PROYECTO}).`
      : `Destino: proyecto REAL ${PROYECTO}.`
  );
  console.log(escribir ? 'Modo: APLICAR (escribe en Firestore).' : 'Modo: simulación (no escribe nada).');

  initializeApp({ projectId: PROYECTO });
  const db = getFirestore();

  const [perfiles, existentes] = await Promise.all([
    db.collection('perfilesPublicosAbogados').get(),
    db.collection('tarjetasAbogados').get(),
  ]);
  const tarjetas = new Map(existentes.docs.map((documento) => [documento.id, documento.data()]));
  const plan = planificar(perfiles, tarjetas);

  const verbo = escribir ? '' : ' (se haría)';
  console.log(`Perfiles públicos leídos: ${perfiles.size}`);
  console.log(`Tarjetas por crear${verbo}: ${plan.creadas}`);
  console.log(`Tarjetas por actualizar${verbo}: ${plan.actualizadas}`);
  console.log(`Tarjetas sin cambios: ${plan.sinCambios}`);
  console.log(`Perfiles omitidos (no verificados o incompletos): ${plan.omitidos}`);
  console.log(`Tarjetas por borrar${verbo} (sin perfil o no publicables): ${plan.borrados.length}`);

  if (!escribir) {
    console.log('Nada se escribió. Revisa los conteos y repite con --aplicar.');
    return;
  }
  await aplicar(db, plan);
  console.log('Listo: los cambios se aplicaron.');
}

main().catch((error) => {
  console.error(`Error: ${error?.message ?? error}`);
  process.exitCode = 1;
});
