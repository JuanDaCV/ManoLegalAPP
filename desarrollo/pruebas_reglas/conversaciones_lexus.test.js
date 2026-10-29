// Pruebas de las reglas de `clientes/{uid}/conversacionesLexus` contra el
// emulador de Firestore. Usan el proyecto `demo-manolegal`: un id con prefijo
// `demo-` nunca toca un proyecto real.
//
// Las escrituras repiten los lotes que hace la app en
// `servicio_conversaciones_lexus_real.dart`; si cambian allí, cambian aquí.

import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const CLIENTE = 'cliente1';
const OTRO_CLIENTE = 'cliente2';
const ABOGADO = 'abogado1';
const ADMINISTRADOR = 'admin1';
const CONVERSACION = 'conv1';

let entorno;

before(async () => {
  entorno = await initializeTestEnvironment({
    projectId: 'demo-manolegal',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await entorno.cleanup();
});

// Cada prueba parte de dos clientes y un abogado; la conversación la crea la
// propia prueba, o la siembra con `sembrar`.
beforeEach(async () => {
  await entorno.clearFirestore();
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    const bd = contexto.firestore();
    await setDoc(doc(bd, 'clientes', CLIENTE), { uid: CLIENTE, nombre: 'Cliente Uno' });
    await setDoc(doc(bd, 'clientes', OTRO_CLIENTE), { uid: OTRO_CLIENTE, nombre: 'Cliente Dos' });
    await setDoc(doc(bd, 'abogados', ABOGADO), { uid: ABOGADO, estado: 'pendiente' });
  });
});

// ---------------------------------------------------------------------------
// Contextos
// ---------------------------------------------------------------------------

const comoDuenio = () =>
  entorno.authenticatedContext(CLIENTE, { email: 'cliente1@prueba.com' }).firestore();
const comoOtroCliente = () =>
  entorno.authenticatedContext(OTRO_CLIENTE, { email: 'cliente2@prueba.com' }).firestore();
const comoAbogado = () =>
  entorno.authenticatedContext(ABOGADO, { email: 'abogado1@prueba.com' }).firestore();
const comoAdministrador = () =>
  entorno.authenticatedContext(ADMINISTRADOR, { email: 'admin@manolegal.com' }).firestore();
const sinSesion = () => entorno.unauthenticatedContext().firestore();

// ---------------------------------------------------------------------------
// Documentos y operaciones, con la forma exacta que escribe la app
// ---------------------------------------------------------------------------

const refConversacion = (bd, uid = CLIENTE, id = CONVERSACION) =>
  doc(bd, 'clientes', uid, 'conversacionesLexus', id);
const refMensaje = (bd, mensajeId, uid = CLIENTE, id = CONVERSACION) =>
  doc(bd, 'clientes', uid, 'conversacionesLexus', id, 'mensajes', mensajeId);

const cabecera = (extra = {}) => ({
  titulo: 'Mi empleador no me paga',
  creadoEn: serverTimestamp(),
  actualizadoEn: serverTimestamp(),
  turnos: 0,
  estado: 'activa',
  ...extra,
});

const mensajeUsuario = (extra = {}) => ({
  autor: 'usuario',
  texto: 'Mi empleador no me paga',
  momento: serverTimestamp(),
  orden: 0,
  estado: 'enviando',
  error: null,
  origen: 'local',
  urgente: false,
  areaSugerida: null,
  enHistorialModelo: false,
  textoParaModelo: null,
  ...extra,
});

const mensajeLexus = (extra = {}) => ({
  autor: 'lexus',
  texto: 'Eso suele depender del contrato.',
  momento: serverTimestamp(),
  orden: 1,
  estado: 'enviado',
  error: null,
  origen: 'modelo',
  urgente: false,
  areaSugerida: 'laboral',
  enHistorialModelo: true,
  textoParaModelo: '{"ambito":"juridico","respuesta":"Eso suele depender del contrato."}',
  ...extra,
});

// guardarEnvio: crea la conversación si es nueva y escribe el mensaje.
function envio(bd, { id = CONVERSACION, mensajeId = 'u1', nueva = true, conversacion = {}, mensaje = {} } = {}) {
  const lote = writeBatch(bd);
  if (nueva) {
    lote.set(refConversacion(bd, CLIENTE, id), cabecera(conversacion));
  } else {
    lote.update(refConversacion(bd, CLIENTE, id), { actualizadoEn: serverTimestamp() });
  }
  lote.set(refMensaje(bd, mensajeId, CLIENTE, id), mensajeUsuario(mensaje));
  return lote.commit();
}

// guardarRespuesta: el mensaje de la persona pasa a enviado, se guarda el de
// Lexus y suben los turnos.
function respuesta(bd, { mensajeUsuarioId = 'u1', mensajeLexusId = 'l1', lexus = {}, usuario = {} } = {}) {
  const lote = writeBatch(bd);
  lote.update(refMensaje(bd, mensajeUsuarioId), {
    estado: 'enviado',
    error: null,
    enHistorialModelo: true,
    ...usuario,
  });
  lote.set(refMensaje(bd, mensajeLexusId), mensajeLexus(lexus));
  lote.update(refConversacion(bd), { turnos: increment(1), actualizadoEn: serverTimestamp() });
  return lote.commit();
}

// guardarReintento: el mismo mensaje, con nuevo orden y estado enviando.
function reintento(bd, { mensajeId = 'u1', orden = 2 } = {}) {
  const lote = writeBatch(bd);
  lote.update(refMensaje(bd, mensajeId), {
    estado: 'enviando',
    error: null,
    orden,
    momento: serverTimestamp(),
  });
  lote.update(refConversacion(bd), { actualizadoEn: serverTimestamp() });
  return lote.commit();
}

// Siembra directa (sin reglas): una conversación y, si se pide, mensajes.
async function sembrar({ conversacion = {}, mensajes = {} } = {}) {
  const ahora = Timestamp.now();
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    const bd = contexto.firestore();
    await setDoc(refConversacion(bd), {
      titulo: 'Mi empleador no me paga',
      creadoEn: ahora,
      actualizadoEn: ahora,
      turnos: 0,
      estado: 'activa',
      ...conversacion,
    });
    for (const [id, datos] of Object.entries(mensajes)) {
      await setDoc(refMensaje(bd, id), { ...datos, momento: ahora });
    }
  });
}

// Mensajes sin las marcas de tiempo del servidor, para sembrar.
const usuarioSembrado = (extra = {}) => {
  const { momento, ...resto } = mensajeUsuario(extra);
  return resto;
};
const lexusSembrado = (extra = {}) => {
  const { momento, ...resto } = mensajeLexus(extra);
  return resto;
};

// ---------------------------------------------------------------------------
// El dueño
// ---------------------------------------------------------------------------

describe('el dueño de la conversación', () => {
  it('la crea junto con su primer mensaje en un solo lote y la lee de vuelta', async () => {
    const bd = comoDuenio();

    await assertSucceeds(envio(bd));

    const conversacion = await assertSucceeds(getDoc(refConversacion(bd)));
    assert(conversacion.exists());
    assert.equal(conversacion.data().estado, 'activa');
    assert.equal(conversacion.data().turnos, 0);

    const mensaje = await assertSucceeds(getDoc(refMensaje(bd, 'u1')));
    assert.equal(mensaje.data().texto, 'Mi empleador no me paga');
    assert.equal(mensaje.data().estado, 'enviando');

    // Las dos consultas que hace la app al cargar.
    const reciente = await assertSucceeds(
      getDocs(query(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus'), orderBy('actualizadoEn', 'desc'), limit(1))),
    );
    assert.equal(reciente.size, 1);
    const mensajes = await assertSucceeds(
      getDocs(query(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus', CONVERSACION, 'mensajes'), orderBy('orden'))),
    );
    assert.equal(mensajes.size, 1);
  });

  it('completa un turno: respuesta del modelo, turnos +1 y mensaje enviado', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));

    await assertSucceeds(respuesta(bd));

    const conversacion = await getDoc(refConversacion(bd));
    assert.equal(conversacion.data().turnos, 1);
    const usuario = await getDoc(refMensaje(bd, 'u1'));
    assert.equal(usuario.data().estado, 'enviado');
    assert.equal(usuario.data().enHistorialModelo, true);
  });

  it('guarda una respuesta local (sin textoParaModelo ni área)', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));

    await assertSucceeds(
      respuesta(bd, {
        usuario: { enHistorialModelo: false },
        lexus: {
          origen: 'local',
          areaSugerida: null,
          enHistorialModelo: false,
          textoParaModelo: null,
        },
      }),
    );
  });

  it('acepta mensajes sin las claves opcionales ausentes', async () => {
    const bd = comoDuenio();
    const { error, areaSugerida, textoParaModelo, ...sinOpcionales } = mensajeUsuario();
    const lote = writeBatch(bd);
    lote.set(refConversacion(bd), cabecera());
    lote.set(refMensaje(bd, 'u1'), sinOpcionales);

    await assertSucceeds(lote.commit());
  });

  it('marca un mensaje como fallido y lo reintenta con nuevo orden', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));

    await assertSucceeds(
      updateDoc(refMensaje(bd, 'u1'), { estado: 'fallido', error: 'sinConexion' }),
    );
    await assertSucceeds(reintento(bd, { orden: 2 }));

    const mensaje = await getDoc(refMensaje(bd, 'u1'));
    assert.equal(mensaje.data().estado, 'enviando');
    assert.equal(mensaje.data().error, null);
    assert.equal(mensaje.data().orden, 2);
  });

  it('un segundo mensaje de la misma conversación actualiza la actividad', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));
    await assertSucceeds(respuesta(bd));

    await assertSucceeds(
      envio(bd, { nueva: false, mensajeId: 'u2', mensaje: { orden: 2 } }),
    );
  });

  it('cierra la conversación y también puede expirarla, sin tocar la actividad', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));
    await assertSucceeds(updateDoc(refConversacion(bd), { estado: 'cerrada' }));

    await assertSucceeds(envio(bd, { id: 'conv2', mensajeId: 'u1' }));
    await assertSucceeds(updateDoc(refConversacion(bd, CLIENTE, 'conv2'), { estado: 'expirada' }));
  });

  it('el último turno (29 a 30) pasa, aunque la persona ya no pueda escribir más', async () => {
    await sembrar({ conversacion: { turnos: 29 }, mensajes: { u1: usuarioSembrado() } });

    await assertSucceeds(respuesta(comoDuenio()));

    const conversacion = await getDoc(refConversacion(comoDuenio()));
    assert.equal(conversacion.data().turnos, 30);
  });

  it('el título admite 121 unidades y no 122, ni vacío', async () => {
    const bd = comoDuenio();

    await assertSucceeds(envio(bd, { conversacion: { titulo: 'a'.repeat(121) } }));
    await assertFails(envio(bd, { id: 'conv2', conversacion: { titulo: 'a'.repeat(122) } }));
    await assertFails(envio(bd, { id: 'conv3', conversacion: { titulo: '' } }));
  });

  it('exige las fechas del servidor: no admite una fecha inventada', async () => {
    const bd = comoDuenio();

    await assertFails(envio(bd, { conversacion: { creadoEn: Timestamp.now() } }));
    await assertFails(envio(bd, { conversacion: { actualizadoEn: Timestamp.fromDate(new Date('2020-01-01')) } }));
    await assertFails(envio(bd, { mensaje: { momento: Timestamp.now() } }));
  });

  it('solo crea conversaciones activas y en cero turnos', async () => {
    const bd = comoDuenio();

    await assertFails(envio(bd, { conversacion: { estado: 'cerrada' } }));
    await assertFails(envio(bd, { conversacion: { turnos: 1 } }));
    await assertFails(envio(bd, { conversacion: { estado: 'otra' } }));
  });
});

// ---------------------------------------------------------------------------
// Quien no es el dueño
// ---------------------------------------------------------------------------

describe('quien no es el dueño', () => {
  beforeEach(async () => {
    await sembrar({
      conversacion: { turnos: 1 },
      mensajes: { u1: usuarioSembrado({ estado: 'enviado' }), l1: lexusSembrado() },
    });
  });

  it('el administrador no puede leer ni listar conversaciones ni mensajes', async () => {
    const bd = comoAdministrador();

    await assertFails(getDoc(refConversacion(bd)));
    await assertFails(getDocs(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus')));
    await assertFails(
      getDocs(query(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus'), orderBy('actualizadoEn', 'desc'), limit(1))),
    );
    await assertFails(getDoc(refMensaje(bd, 'u1')));
    await assertFails(getDocs(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus', CONVERSACION, 'mensajes')));
  });

  it('el administrador tampoco puede escribir ni borrar', async () => {
    const bd = comoAdministrador();

    await assertFails(updateDoc(refConversacion(bd), { estado: 'cerrada' }));
    await assertFails(updateDoc(refMensaje(bd, 'u1'), { estado: 'fallido', error: 'interno' }));
    await assertFails(envio(bd, { id: 'conv2' }));
    await assertFails(deleteDoc(refConversacion(bd)));
    await assertFails(deleteDoc(refMensaje(bd, 'u1')));
  });

  it('otro cliente no puede leer ni escribir', async () => {
    const bd = comoOtroCliente();

    await assertFails(getDoc(refConversacion(bd)));
    await assertFails(getDocs(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus')));
    await assertFails(getDoc(refMensaje(bd, 'u1')));
    await assertFails(getDocs(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus', CONVERSACION, 'mensajes')));
    await assertFails(updateDoc(refConversacion(bd), { actualizadoEn: serverTimestamp() }));
    await assertFails(envio(bd, { id: 'conv2' }));
    await assertFails(
      setDoc(refMensaje(bd, 'u9'), mensajeUsuario({ orden: 5 })),
    );
  });

  it('un abogado no puede leer ni escribir las de un cliente', async () => {
    const bd = comoAbogado();

    await assertFails(getDoc(refConversacion(bd)));
    await assertFails(getDocs(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus')));
    await assertFails(updateDoc(refConversacion(bd), { estado: 'cerrada' }));
  });

  it('sin sesión no se lee ni se escribe', async () => {
    const bd = sinSesion();

    await assertFails(getDoc(refConversacion(bd)));
    await assertFails(getDocs(collection(bd, 'clientes', CLIENTE, 'conversacionesLexus')));
    await assertFails(updateDoc(refConversacion(bd), { estado: 'cerrada' }));
  });
});

describe('quien no tiene documento en clientes', () => {
  it('un abogado no puede crear una conversación en su propia ruta', async () => {
    const bd = comoAbogado();
    const lote = writeBatch(bd);
    lote.set(doc(bd, 'clientes', ABOGADO, 'conversacionesLexus', CONVERSACION), cabecera());
    lote.set(
      doc(bd, 'clientes', ABOGADO, 'conversacionesLexus', CONVERSACION, 'mensajes', 'u1'),
      mensajeUsuario(),
    );

    await assertFails(lote.commit());
  });
});

// ---------------------------------------------------------------------------
// Validación de datos
// ---------------------------------------------------------------------------

describe('validación de la conversación y de sus mensajes', () => {
  it('rechaza campos extra en la conversación y en el mensaje', async () => {
    const bd = comoDuenio();

    await assertFails(envio(bd, { conversacion: { administrador: 'admin@manolegal.com' } }));
    await assertFails(envio(bd, { id: 'conv2', mensaje: { copia: 'texto' } }));
  });

  it('rechaza una conversación o un mensaje al que le falta un campo obligatorio', async () => {
    const bd = comoDuenio();
    const { titulo, ...sinTitulo } = cabecera();
    const { orden, ...sinOrden } = mensajeUsuario();

    const sinTituloLote = writeBatch(bd);
    sinTituloLote.set(refConversacion(bd), sinTitulo);
    sinTituloLote.set(refMensaje(bd, 'u1'), mensajeUsuario());
    await assertFails(sinTituloLote.commit());

    const sinOrdenLote = writeBatch(bd);
    sinOrdenLote.set(refConversacion(bd, CLIENTE, 'conv2'), cabecera());
    sinOrdenLote.set(refMensaje(bd, 'u1', CLIENTE, 'conv2'), sinOrden);
    await assertFails(sinOrdenLote.commit());
  });

  // size() cuenta unidades UTF-16 (un emoji vale 2), no caracteres. La app
  // admite 2000 caracteres del usuario, que con emojis llegan a 4000
  // unidades, así que ese es el tope de las reglas; los 2000 caracteres
  // exactos los impone la app (`ConfiguracionLexus.largoMaximoMensaje`).
  it('acepta 2000 caracteres con emojis y tildes (1000 emojis y 1000 «á»)', async () => {
    const bd = comoDuenio();
    const texto = '😀'.repeat(1000) + 'á'.repeat(1000);
    assert.equal([...texto].length, 2000);

    await assertSucceeds(envio(bd, { mensaje: { texto } }));
  });

  it('acepta el peor caso de la app: 2000 emojis seguidos (4000 unidades UTF-16)', async () => {
    const bd = comoDuenio();
    const texto = '😀'.repeat(2000);
    assert.equal([...texto].length, 2000);
    assert.equal(texto.length, 4000);

    await assertSucceeds(envio(bd, { mensaje: { texto } }));
  });

  it('el texto del usuario admite hasta 4000 unidades y rechaza 4001, 2001 emojis o vacío', async () => {
    const bd = comoDuenio();

    await assertSucceeds(envio(bd, { mensaje: { texto: 'a'.repeat(4000) } }));
    await assertFails(envio(bd, { id: 'conv2', mensaje: { texto: 'a'.repeat(4001) } }));
    await assertFails(envio(bd, { id: 'conv3', mensaje: { texto: '😀'.repeat(2001) } }));
    await assertFails(envio(bd, { id: 'conv4', mensaje: { texto: '' } }));
  });

  it('el título de 60 emojis y la elipsis (121 unidades) cabe', async () => {
    const bd = comoDuenio();
    const titulo = '😀'.repeat(60) + '…';
    assert.equal(titulo.length, 121);

    await assertSucceeds(envio(bd, { conversacion: { titulo } }));
  });

  it('el texto de Lexus admite 4000 unidades', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));

    await assertSucceeds(respuesta(bd, { lexus: { texto: 'b'.repeat(4000) } }));
  });

  it('rechaza un texto de Lexus de 4001 unidades', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));

    await assertFails(respuesta(bd, { lexus: { texto: 'b'.repeat(4001) } }));
  });

  it('rechaza un textoParaModelo de más de 20000 y admite 20000', async () => {
    const bd = comoDuenio();
    await assertSucceeds(envio(bd));

    await assertFails(respuesta(bd, { lexus: { textoParaModelo: 'j'.repeat(20001) } }));
    await assertSucceeds(respuesta(bd, { lexus: { textoParaModelo: 'j'.repeat(20000) } }));
  });

  it('rechaza orden fuera de 0 a 499, no entero o con valores de otro tipo', async () => {
    const bd = comoDuenio();

    await assertSucceeds(envio(bd, { mensaje: { orden: 499 } }));
    await assertFails(envio(bd, { id: 'conv2', mensaje: { orden: 500 } }));
    await assertFails(envio(bd, { id: 'conv3', mensaje: { orden: -1 } }));
    await assertFails(envio(bd, { id: 'conv4', mensaje: { orden: 1.5 } }));
    await assertFails(envio(bd, { id: 'conv5', mensaje: { urgente: 'si' } }));
    await assertFails(envio(bd, { id: 'conv6', mensaje: { enHistorialModelo: 1 } }));
  });

  it('rechaza error y areaSugerida de más de 40 caracteres o que no sean texto', async () => {
    const bd = comoDuenio();

    await assertSucceeds(envio(bd, { mensaje: { error: 'sinConexion', areaSugerida: 'laboral' } }));
    await assertFails(envio(bd, { id: 'conv2', mensaje: { error: 'e'.repeat(41) } }));
    await assertFails(envio(bd, { id: 'conv3', mensaje: { areaSugerida: 'a'.repeat(41) } }));
    await assertFails(envio(bd, { id: 'conv4', mensaje: { error: 5 } }));
  });

  it('rechaza autor, estado y origen fuera de sus conjuntos', async () => {
    const bd = comoDuenio();

    await assertFails(envio(bd, { mensaje: { autor: 'administrador' } }));
    await assertFails(envio(bd, { id: 'conv2', mensaje: { estado: 'leido' } }));
    await assertFails(envio(bd, { id: 'conv3', mensaje: { origen: 'externo' } }));
  });
});

// ---------------------------------------------------------------------------
// Turnos y estado
// ---------------------------------------------------------------------------

describe('turnos y estado de la conversación', () => {
  it('rechaza subir los turnos en más de uno', async () => {
    await sembrar({ conversacion: { turnos: 3 } });

    await assertFails(
      updateDoc(refConversacion(comoDuenio()), { turnos: increment(2), actualizadoEn: serverTimestamp() }),
    );
    await assertSucceeds(
      updateDoc(refConversacion(comoDuenio()), { turnos: increment(1), actualizadoEn: serverTimestamp() }),
    );
  });

  it('rechaza bajar los turnos', async () => {
    await sembrar({ conversacion: { turnos: 3 } });

    await assertFails(updateDoc(refConversacion(comoDuenio()), { turnos: 2 }));
  });

  it('rechaza pasar de 30 turnos', async () => {
    await sembrar({ conversacion: { turnos: 30 } });

    await assertFails(
      updateDoc(refConversacion(comoDuenio()), { turnos: increment(1), actualizadoEn: serverTimestamp() }),
    );
  });

  it('rechaza una actividad con fecha distinta a la del servidor', async () => {
    await sembrar();

    await assertFails(updateDoc(refConversacion(comoDuenio()), { actualizadoEn: Timestamp.now() }));
  });

  it('rechaza cambiar el título o la fecha de creación', async () => {
    await sembrar();
    const bd = comoDuenio();

    await assertFails(updateDoc(refConversacion(bd), { titulo: 'Otro título' }));
    await assertFails(updateDoc(refConversacion(bd), { creadoEn: serverTimestamp() }));
  });

  it('una conversación cerrada no se reactiva ni se modifica', async () => {
    await sembrar({ conversacion: { estado: 'cerrada' } });
    const bd = comoDuenio();

    await assertFails(updateDoc(refConversacion(bd), { estado: 'activa' }));
    await assertFails(updateDoc(refConversacion(bd), { estado: 'expirada' }));
    await assertFails(updateDoc(refConversacion(bd), { actualizadoEn: serverTimestamp() }));
    await assertFails(updateDoc(refConversacion(bd), { turnos: increment(1) }));
  });

  it('una conversación expirada tampoco se reactiva', async () => {
    await sembrar({ conversacion: { estado: 'expirada' } });

    await assertFails(updateDoc(refConversacion(comoDuenio()), { estado: 'activa' }));
  });

  it('no se agregan mensajes a una conversación cerrada', async () => {
    await sembrar({ conversacion: { estado: 'cerrada' } });
    const bd = comoDuenio();

    await assertFails(setDoc(refMensaje(bd, 'u2'), mensajeUsuario({ orden: 3 })));
    await assertFails(setDoc(refMensaje(bd, 'l2'), mensajeLexus({ orden: 4 })));
  });

  it('no se modifican mensajes de una conversación cerrada', async () => {
    await sembrar({
      conversacion: { estado: 'cerrada' },
      mensajes: { u1: usuarioSembrado({ estado: 'fallido', error: 'interno' }) },
    });

    await assertFails(reintento(comoDuenio()));
    await assertFails(updateDoc(refMensaje(comoDuenio(), 'u1'), { estado: 'enviado' }));
  });

  it('no se crea un mensaje de la persona cuando ya hay 30 turnos', async () => {
    await sembrar({ conversacion: { turnos: 30 } });

    await assertFails(setDoc(refMensaje(comoDuenio(), 'u31'), mensajeUsuario({ orden: 60 })));
  });

  it('con 29 turnos todavía se crea un mensaje de la persona', async () => {
    await sembrar({ conversacion: { turnos: 29 } });

    await assertSucceeds(setDoc(refMensaje(comoDuenio(), 'u30'), mensajeUsuario({ orden: 58 })));
  });

  it('no se agregan mensajes a una conversación que no existe', async () => {
    await assertFails(setDoc(refMensaje(comoDuenio(), 'u1', CLIENTE, 'no-existe'), mensajeUsuario()));
  });
});

// ---------------------------------------------------------------------------
// Inmutabilidad y borrado
// ---------------------------------------------------------------------------

describe('mensajes inmutables y sin borrado', () => {
  beforeEach(async () => {
    await sembrar({
      conversacion: { turnos: 1 },
      mensajes: { u1: usuarioSembrado({ estado: 'enviado', enHistorialModelo: true }), l1: lexusSembrado() },
    });
  });

  it('el texto de un mensaje de la persona no se puede actualizar', async () => {
    const bd = comoDuenio();

    await assertFails(updateDoc(refMensaje(bd, 'u1'), { texto: 'Otra cosa' }));
    await assertFails(updateDoc(refMensaje(bd, 'u1'), { autor: 'lexus' }));
    await assertFails(updateDoc(refMensaje(bd, 'u1'), { textoParaModelo: 'inyectado' }));
    await assertFails(updateDoc(refMensaje(bd, 'u1'), { origen: 'modelo' }));
  });

  it('un mensaje de Lexus no se puede actualizar', async () => {
    const bd = comoDuenio();

    await assertFails(updateDoc(refMensaje(bd, 'l1'), { texto: 'Cambiado' }));
    await assertFails(updateDoc(refMensaje(bd, 'l1'), { estado: 'fallido' }));
  });

  it('el estado de entrega de un mensaje de la persona sí se actualiza', async () => {
    const bd = comoDuenio();

    await assertSucceeds(updateDoc(refMensaje(bd, 'u1'), { estado: 'fallido', error: 'cuotaExcedida' }));
  });

  it('no se borran conversaciones ni mensajes', async () => {
    const bd = comoDuenio();

    await assertFails(deleteDoc(refConversacion(bd)));
    await assertFails(deleteDoc(refMensaje(bd, 'u1')));
    await assertFails(deleteDoc(refMensaje(bd, 'l1')));
  });
});

// ---------------------------------------------------------------------------
// Regresión: lo que ya existía no cambia
// ---------------------------------------------------------------------------

describe('regresión sobre clientes/{uid}', () => {
  it('el administrador sigue leyendo el documento de un cliente', async () => {
    await assertSucceeds(getDoc(doc(comoAdministrador(), 'clientes', CLIENTE)));
    await assertSucceeds(getDocs(collection(comoAdministrador(), 'clientes')));
  });

  it('el dueño sigue leyendo su propio documento y actualizándolo', async () => {
    const bd = comoDuenio();

    const cliente = await assertSucceeds(getDoc(doc(bd, 'clientes', CLIENTE)));
    assert.equal(cliente.data().nombre, 'Cliente Uno');
    await assertSucceeds(updateDoc(doc(bd, 'clientes', CLIENTE), { nombre: 'Cliente Uno Editado' }));
  });

  it('otro cliente sigue sin leer el documento ajeno', async () => {
    await assertFails(getDoc(doc(comoOtroCliente(), 'clientes', CLIENTE)));
  });

  it('la regla de las conversaciones no abre otras subcolecciones', async () => {
    await entorno.withSecurityRulesDisabled(async (contexto) => {
      await setDoc(doc(contexto.firestore(), 'clientes', CLIENTE, 'otraSubcoleccion', 'x'), { a: 1 });
    });

    await assertFails(getDoc(doc(comoDuenio(), 'clientes', CLIENTE, 'otraSubcoleccion', 'x')));
    await assertFails(getDoc(doc(comoAdministrador(), 'clientes', CLIENTE, 'otraSubcoleccion', 'x')));
  });
});
