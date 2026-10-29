// Pruebas de las reglas de `tarjetasAbogados` (la proyección pública que lee
// un visitante web sin sesión) contra el emulador de Firestore. Usan el
// proyecto `demo-manolegal`: un id con prefijo `demo-` nunca toca un proyecto
// real.
//
// Las consultas repiten las que hace el buscador en
// `servicio_perfil_publico.dart` (orden por calificación y límite de 100); si
// cambian allí, cambian aquí. Además se comprueba que abrir esta colección no
// abre nada más a quien no tiene sesión, y que lo que ya existía sigue igual.

import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const CLIENTE = 'cliente1';
const ABOGADO = 'abogado1';
const OTRO_ABOGADO = 'abogado2';
const ADMINISTRADOR = 'admin1';
const VISITANTE = 'visitante1';

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

// ---------------------------------------------------------------------------
// Documentos, con la forma que escriben la app y la Cloud Function
// ---------------------------------------------------------------------------

const tarjeta = (extra = {}) => ({
  nombreCompleto: 'Laura Prueba',
  nombreBusqueda: 'laura prueba',
  fotoUrl: null,
  especialidad: 'laboral',
  ubicacionGeneral: 'sur',
  sector: '',
  tarifa: null,
  verificado: true,
  calificacionPromedio: 4.5,
  cantidadResenas: 2,
  ...extra,
});

const perfilPublico = (uid, extra = {}) => ({
  uid,
  nombreCompleto: 'Laura Prueba',
  nombreBusqueda: 'laura prueba',
  especialidad: 'laboral',
  verificado: true,
  calificacionPromedio: 4.5,
  cantidadResenas: 2,
  telefonoProfesional: '+573001112233',
  correoContacto: 'contacto@ejemplo.com',
  direccionProfesional: 'Calle 1 # 2-3',
  descripcion: 'Abogada de prueba.',
  ...extra,
});

// Cada prueba parte de un cliente, dos abogados con su perfil público, una
// reseña y las tarjetas que habría escrito la Cloud Function.
beforeEach(async () => {
  await entorno.clearFirestore();
  await entorno.withSecurityRulesDisabled(async (contexto) => {
    const bd = contexto.firestore();
    await setDoc(doc(bd, 'clientes', CLIENTE), { uid: CLIENTE, nombre: 'Cliente Uno' });
    await setDoc(doc(bd, 'abogados', ABOGADO), { uid: ABOGADO, estado: 'verificado' });
    await setDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO), perfilPublico(ABOGADO));
    await setDoc(
      doc(bd, 'perfilesPublicosAbogados', OTRO_ABOGADO),
      perfilPublico(OTRO_ABOGADO, { nombreCompleto: 'Beto Prueba', especialidad: 'civil', calificacionPromedio: 3 }),
    );
    await setDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO, 'resenas', CLIENTE), {
      abogadoUid: ABOGADO,
      clienteUid: CLIENTE,
      calificacion: 5,
      comentario: 'Muy clara.',
    });
    await setDoc(doc(bd, 'tarjetasAbogados', ABOGADO), tarjeta());
    await setDoc(
      doc(bd, 'tarjetasAbogados', OTRO_ABOGADO),
      tarjeta({ nombreCompleto: 'Beto Prueba', nombreBusqueda: 'beto prueba', especialidad: 'civil', calificacionPromedio: 3 }),
    );
  });
});

// ---------------------------------------------------------------------------
// Contextos
// ---------------------------------------------------------------------------

const sinSesion = () => entorno.unauthenticatedContext().firestore();
const comoCliente = () =>
  entorno.authenticatedContext(CLIENTE, { email: 'cliente1@prueba.com' }).firestore();
const comoAbogado = () =>
  entorno.authenticatedContext(ABOGADO, { email: 'abogado1@prueba.com' }).firestore();
const comoAdministrador = () =>
  entorno.authenticatedContext(ADMINISTRADOR, { email: 'admin@manolegal.com' }).firestore();

// La consulta del buscador: verificados, por calificación y con límite.
const consultaBuscador = (bd, coleccion, tope, ...filtros) =>
  query(
    collection(bd, coleccion),
    ...filtros,
    where('verificado', '==', true),
    orderBy('calificacionPromedio', 'desc'),
    limit(tope),
  );

// ---------------------------------------------------------------------------
// Lectura pública de las tarjetas
// ---------------------------------------------------------------------------

describe('un visitante sin sesión y las tarjetas', () => {
  it('lee una tarjeta por su id', async () => {
    const leida = await assertSucceeds(getDoc(doc(sinSesion(), 'tarjetasAbogados', ABOGADO)));
    assert.equal(leida.data().nombreCompleto, 'Laura Prueba');
  });

  it('lista con el límite del buscador (100), en orden de calificación', async () => {
    const resultado = await assertSucceeds(getDocs(consultaBuscador(sinSesion(), 'tarjetasAbogados', 100)));
    assert.equal(resultado.size, 2);
    assert.equal(resultado.docs[0].id, ABOGADO);
  });

  it('lista con un límite menor (20)', async () => {
    await assertSucceeds(getDocs(consultaBuscador(sinSesion(), 'tarjetasAbogados', 20)));
  });

  it('lista filtrando por especialidad, como los filtros del buscador', async () => {
    const resultado = await assertSucceeds(
      getDocs(consultaBuscador(sinSesion(), 'tarjetasAbogados', 100, where('especialidad', 'in', ['civil']))),
    );
    assert.equal(resultado.size, 1);
    assert.equal(resultado.docs[0].id, OTRO_ABOGADO);
  });

  it('lista sin el filtro de verificados (el interruptor del buscador apagado)', async () => {
    await assertSucceeds(
      getDocs(query(collection(sinSesion(), 'tarjetasAbogados'), orderBy('calificacionPromedio', 'desc'), limit(100))),
    );
  });

  it('no lista sin límite', async () => {
    await assertFails(getDocs(collection(sinSesion(), 'tarjetasAbogados')));
    await assertFails(
      getDocs(query(collection(sinSesion(), 'tarjetasAbogados'), orderBy('calificacionPromedio', 'desc'))),
    );
  });

  it('no lista con un límite mayor que 100', async () => {
    await assertFails(getDocs(consultaBuscador(sinSesion(), 'tarjetasAbogados', 101)));
  });
});

// ---------------------------------------------------------------------------
// Nadie escribe tarjetas: solo la Cloud Function (Admin SDK)
// ---------------------------------------------------------------------------

describe('escritura de tarjetas', () => {
  for (const [quien, contexto] of [
    ['un visitante', sinSesion],
    ['el abogado dueño', comoAbogado],
    ['un cliente', comoCliente],
    ['el administrador', comoAdministrador],
  ]) {
    it(`${quien} no crea, no actualiza ni borra tarjetas`, async () => {
      const bd = contexto();

      await assertFails(setDoc(doc(bd, 'tarjetasAbogados', 'nuevo'), tarjeta()));
      await assertFails(setDoc(doc(bd, 'tarjetasAbogados', ABOGADO), tarjeta({ calificacionPromedio: 5 })));
      await assertFails(updateDoc(doc(bd, 'tarjetasAbogados', ABOGADO), { calificacionPromedio: 5 }));
      await assertFails(updateDoc(doc(bd, 'tarjetasAbogados', ABOGADO), { telefonoProfesional: '+573009998877' }));
      await assertFails(deleteDoc(doc(bd, 'tarjetasAbogados', ABOGADO)));
    });
  }
});

// ---------------------------------------------------------------------------
// Abrir las tarjetas no abre nada más
// ---------------------------------------------------------------------------

describe('un visitante sin sesión fuera de las tarjetas', () => {
  it('no lee ni lista los perfiles públicos completos', async () => {
    const bd = sinSesion();

    await assertFails(getDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO)));
    await assertFails(getDocs(consultaBuscador(bd, 'perfilesPublicosAbogados', 100)));
  });

  it('no lee el documento privado de un abogado', async () => {
    await assertFails(getDoc(doc(sinSesion(), 'abogados', ABOGADO)));
  });

  it('no lee ni lista las reseñas', async () => {
    const bd = sinSesion();

    await assertFails(getDocs(collection(bd, 'perfilesPublicosAbogados', ABOGADO, 'resenas')));
    await assertFails(getDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO, 'resenas', CLIENTE)));
  });

  it('no crea un cliente, una PQRS, una reseña ni una conversación de Lexus', async () => {
    const bd = sinSesion();

    await assertFails(setDoc(doc(bd, 'clientes', VISITANTE), { uid: VISITANTE, nombre: 'Visitante' }));
    await assertFails(
      addDoc(collection(bd, 'pqrs'), {
        uid: VISITANTE,
        tipo: 'peticion',
        descripcion: 'Quiero información.',
        evidencias: [],
        creadoEn: serverTimestamp(),
        actualizadoEn: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO, 'resenas', VISITANTE), {
        abogadoUid: ABOGADO,
        clienteUid: VISITANTE,
        calificacion: 5,
        comentario: 'Reseña sin cuenta.',
        fecha: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(bd, 'clientes', VISITANTE, 'conversacionesLexus', 'conv1'), {
        titulo: 'Consulta sin cuenta',
        creadoEn: serverTimestamp(),
        actualizadoEn: serverTimestamp(),
        turnos: 0,
        estado: 'activa',
      }),
    );
  });
});

// ---------------------------------------------------------------------------
// Regresión: lo que ya existía no cambia
// ---------------------------------------------------------------------------

describe('regresión sobre perfilesPublicosAbogados', () => {
  it('un cliente con sesión sigue leyendo y listando los perfiles públicos', async () => {
    const bd = comoCliente();

    const perfil = await assertSucceeds(getDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO)));
    assert.equal(perfil.data().correoContacto, 'contacto@ejemplo.com');
    const lista = await assertSucceeds(getDocs(consultaBuscador(bd, 'perfilesPublicosAbogados', 100)));
    assert.equal(lista.size, 2);
  });

  it('el abogado dueño sigue editando los campos que le corresponden, pero no su verificación', async () => {
    const bd = comoAbogado();

    await assertSucceeds(
      updateDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO), {
        descripcion: 'Descripción nueva.',
        actualizadoEn: serverTimestamp(),
      }),
    );
    await assertFails(updateDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO), { verificado: false }));
    await assertFails(updateDoc(doc(bd, 'perfilesPublicosAbogados', ABOGADO), { calificacionPromedio: 5 }));
  });

  it('el administrador sigue cambiando la verificación, pero no los agregados', async () => {
    const bd = comoAdministrador();

    await assertSucceeds(
      updateDoc(doc(bd, 'perfilesPublicosAbogados', OTRO_ABOGADO), {
        verificado: false,
        actualizadoEn: serverTimestamp(),
      }),
    );
    await assertFails(updateDoc(doc(bd, 'perfilesPublicosAbogados', OTRO_ABOGADO), { cantidadResenas: 10 }));
  });
});
