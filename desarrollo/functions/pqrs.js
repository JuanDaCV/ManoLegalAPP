/**
 * PQRS: asignación del radicado y correo de confirmación.
 *
 * El radicado lo genera exclusivamente esta función. Las reglas de Firestore
 * impiden que el cliente escriba `radicado`, `estado` o `correoConfirmacion`;
 * el Admin SDK que usa esta función no pasa por esas reglas, así que es el
 * único camino por el que esos campos aparecen.
 *
 * El correo es una confirmación, no una condición: si falla, la PQRS y su
 * radicado se conservan, y el fallo queda registrado en el propio documento.
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Misma región que la base de datos y que la función de calificaciones: un
// disparador de Firestore de segunda generación debe vivir en esa región.
const REGION = 'us-east1';

// El año del radicado y la fecha del correo se calculan en hora de Colombia:
// una PQRS del 31 de diciembre a las 9 p. m. pertenece a ese año, aunque en
// UTC ya sea 1 de enero.
const ZONA_HORARIA = 'America/Bogota';

// Credenciales de la cuenta de correo de ManoLegal. Viven en Secret Manager
// (`firebase functions:secrets:set`), nunca en el código ni en Firestore.
const usuarioSmtp = defineSecret('PQRS_SMTP_USUARIO');
const contrasenaSmtp = defineSecret('PQRS_SMTP_CONTRASENA');

const ETIQUETAS_TIPO = {
  peticion: 'Petición',
  queja: 'Queja',
  reclamo: 'Reclamo',
  solicitud: 'Solicitud',
};

/** Radicado con el formato PQ-AAAA-NNNNNN. */
function formatearRadicado(anio, numero) {
  return `PQ-${anio}-${String(numero).padStart(6, '0')}`;
}

function anioEnColombia(fecha) {
  return Number(
    new Intl.DateTimeFormat('en-US', { timeZone: ZONA_HORARIA, year: 'numeric' }).format(fecha)
  );
}

function formatearFechaRecepcion(fecha) {
  const texto = new Intl.DateTimeFormat('es-CO', {
    timeZone: ZONA_HORARIA,
    dateStyle: 'long',
    timeStyle: 'short',
  }).format(fecha);
  return `${texto} (hora de Colombia)`;
}

/**
 * Asunto y cuerpo del correo de confirmación. A propósito no incluye la
 * descripción de la PQRS: el correo solo confirma la recepción.
 */
function construirCorreo({ nombre, tipo, radicado, fecha }) {
  const saludo = nombre ? `Hola, ${nombre}.` : 'Hola.';
  return {
    asunto: `ManoLegal — Confirmación de PQRS recibida ${radicado}`,
    texto: [
      saludo,
      '',
      'Hemos recibido correctamente tu PQRS en ManoLegal.',
      '',
      `Tipo: ${ETIQUETAS_TIPO[tipo] ?? tipo}`,
      `Radicado: ${radicado}`,
      `Fecha de recepción: ${formatearFechaRecepcion(fecha)}`,
      '',
      'Guarda este número de radicado para identificar tu solicitud posteriormente.',
      '',
      'Saludos,',
      'Equipo ManoLegal',
    ].join('\n'),
  };
}

/**
 * Asigna el siguiente número del año dentro de una transacción. Devuelve el
 * radicado asignado, o `null` si no había nada que hacer.
 *
 * Firestore serializa las transacciones que tocan el mismo contador, así que
 * dos PQRS simultáneas nunca reciben el mismo número. Y como la entrega de
 * eventos es "al menos una vez", si la PQRS ya tiene radicado no se le asigna
 * otro: así un evento repetido no consume números ni envía otro correo.
 */
async function asignarRadicado(db, referenciaPqrs, anio) {
  const referenciaContador = db.doc(`contadoresPqrs/${anio}`);
  return db.runTransaction(async (transaccion) => {
    const pqrs = await transaccion.get(referenciaPqrs);
    if (!pqrs.exists || pqrs.get('radicado')) return null;

    const contador = await transaccion.get(referenciaContador);
    const ultimoNumero = contador.exists ? contador.get('ultimoNumero') ?? 0 : 0;
    const numero = ultimoNumero + 1;
    const radicado = formatearRadicado(anio, numero);

    transaccion.set(referenciaContador, {
      ultimoNumero: numero,
      actualizadoEn: FieldValue.serverTimestamp(),
    });
    transaccion.update(referenciaPqrs, {
      radicado,
      estado: 'recibida',
      actualizadoEn: FieldValue.serverTimestamp(),
    });
    return radicado;
  });
}

/** Nombre para el saludo: el del perfil de ManoLegal, o el de la cuenta. */
async function obtenerNombre(db, uid, nombreCuenta) {
  for (const coleccion of ['clientes', 'abogados']) {
    const perfil = await db.doc(`${coleccion}/${uid}`).get();
    const nombre = perfil.exists ? perfil.get('nombre') : null;
    if (typeof nombre === 'string' && nombre.trim()) return nombre.trim();
  }
  return nombreCuenta?.trim() || null;
}

async function enviarCorreo({ para, asunto, texto }) {
  // Se carga aquí y no arriba: durante el despliegue la CLI carga este
  // archivo para descubrir las funciones, y conviene que esa carga sea mínima.
  const nodemailer = require('nodemailer');
  const remitente = usuarioSmtp.value();
  const transporte = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: { user: remitente, pass: contrasenaSmtp.value() },
  });
  await transporte.sendMail({
    from: { name: 'ManoLegal', address: remitente },
    to: para,
    subject: asunto,
    text: texto,
  });
}

exports.procesarNuevaPqrs = onDocumentCreated(
  { document: 'pqrs/{pqrsId}', region: REGION, secrets: [usuarioSmtp, contrasenaSmtp] },
  async (event) => {
    const instantanea = event.data;
    if (!instantanea) return;
    const { pqrsId } = event.params;
    const datos = instantanea.data();
    const db = getFirestore();

    const creadoEn = datos.creadoEn?.toDate?.() ?? new Date(event.time);
    const radicado = await asignarRadicado(db, instantanea.ref, anioEnColombia(creadoEn));
    if (!radicado) {
      logger.info(`PQRS ${pqrsId}: ya tenía radicado; se omite.`);
      return;
    }
    logger.info(`PQRS ${pqrsId}: radicado ${radicado} asignado.`);

    // Destinatario: el correo de la cuenta autenticada, tomado de
    // Authentication, no un dato que haya escrito el cliente.
    try {
      const cuenta = await getAuth().getUser(datos.uid);
      if (!cuenta.email) throw new Error('La cuenta no tiene un correo registrado.');
      const nombre = await obtenerNombre(db, datos.uid, cuenta.displayName);
      const { asunto, texto } = construirCorreo({ nombre, tipo: datos.tipo, radicado, fecha: creadoEn });
      await enviarCorreo({ para: cuenta.email, asunto, texto });
      await instantanea.ref.update({
        correoConfirmacion: { estado: 'enviado', fecha: FieldValue.serverTimestamp() },
      });
      logger.info(`PQRS ${pqrsId}: correo de confirmación enviado.`);
    } catch (error) {
      // Sin reintento automático: reintentar todo el evento podría enviar el
      // correo dos veces. El fallo queda registrado para reenviarlo después.
      const mensaje = String(error?.message ?? error).slice(0, 300);
      logger.error(`PQRS ${pqrsId}: no se pudo enviar el correo de confirmación: ${mensaje}`);
      await instantanea.ref
        .update({
          correoConfirmacion: { estado: 'fallido', error: mensaje, fecha: FieldValue.serverTimestamp() },
        })
        .catch((e) => logger.error(`PQRS ${pqrsId}: tampoco se pudo registrar el fallo: ${e.message}`));
    }
  }
);

// Funciones puras, exportadas solo para las pruebas.
exports.formatearRadicado = formatearRadicado;
exports.anioEnColombia = anioEnColombia;
exports.construirCorreo = construirCorreo;
