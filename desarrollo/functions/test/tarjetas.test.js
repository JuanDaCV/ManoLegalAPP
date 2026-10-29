// Pruebas de la proyección pública de abogados (`tarjetasAbogados`). Solo las
// funciones puras: el disparador y el script de inicialización las usan tal
// cual, y lo que hacen con Firestore se prueba contra el emulador.

const { test } = require('node:test');
const assert = require('node:assert/strict');

const { CAMPOS_TARJETA, construirTarjeta, sonTarjetasIguales } = require('../tarjetas_proyeccion');

/** Perfil público completo, como lo escribe la app, con datos inventados. */
function perfilCompleto(extra = {}) {
  return {
    uid: 'abogado1',
    nombreCompleto: 'Laura Prueba',
    nombreBusqueda: 'laura prueba',
    fotoUrl: 'https://ejemplo.com/foto.jpg',
    especialidad: 'laboral',
    aniosExperiencia: 7,
    ubicacionGeneral: 'sur',
    sector: 'Ciudad Jardín',
    direccionProfesional: 'Calle 1 # 2-3',
    tarifa: 150000,
    descripcion: 'Abogada de prueba.',
    experiencia: [{ cargo: 'Asesora', empresa: 'Firma de prueba' }],
    instagram: 'https://instagram.com/prueba',
    facebook: 'https://facebook.com/prueba',
    linkedin: 'https://linkedin.com/in/prueba',
    verificado: true,
    calificacionPromedio: 4.5,
    cantidadResenas: 12,
    telefonoProfesional: '+573001112233',
    correoContacto: 'contacto@ejemplo.com',
    actualizadoEn: new Date('2026-10-01T10:00:00Z'),
    ...extra,
  };
}

test('la tarjeta lleva exactamente los campos de la lista blanca', () => {
  const tarjeta = construirTarjeta(perfilCompleto());

  assert.deepEqual(Object.keys(tarjeta), [...CAMPOS_TARJETA]);
  assert.deepEqual(tarjeta, {
    nombreCompleto: 'Laura Prueba',
    nombreBusqueda: 'laura prueba',
    fotoUrl: 'https://ejemplo.com/foto.jpg',
    especialidad: 'laboral',
    ubicacionGeneral: 'sur',
    sector: 'Ciudad Jardín',
    tarifa: 150000,
    verificado: true,
    calificacionPromedio: 4.5,
    cantidadResenas: 12,
  });
});

test('no filtra datos de contacto, experiencia, descripción ni redes', () => {
  const tarjeta = construirTarjeta(perfilCompleto());

  for (const privado of [
    'telefonoProfesional',
    'correoContacto',
    'direccionProfesional',
    'instagram',
    'facebook',
    'linkedin',
    'experiencia',
    'aniosExperiencia',
    'descripcion',
    'uid',
    'actualizadoEn',
  ]) {
    assert.equal(Object.hasOwn(tarjeta, privado), false, privado);
  }
  const texto = JSON.stringify(tarjeta);
  assert.doesNotMatch(texto, /3001112233|contacto@ejemplo\.com|Calle 1|instagram|Abogada de prueba/);
});

test('devuelve null si el abogado no está verificado', () => {
  assert.equal(construirTarjeta(perfilCompleto({ verificado: false })), null);
  assert.equal(construirTarjeta(perfilCompleto({ verificado: 'true' })), null);
  const { verificado, ...sinVerificado } = perfilCompleto();
  assert.equal(construirTarjeta(sinVerificado), null);
});

test('devuelve null si falta el nombre o la especialidad', () => {
  assert.equal(construirTarjeta(perfilCompleto({ nombreCompleto: '' })), null);
  assert.equal(construirTarjeta(perfilCompleto({ nombreCompleto: '   ' })), null);
  assert.equal(construirTarjeta(perfilCompleto({ nombreCompleto: 42 })), null);
  assert.equal(construirTarjeta(perfilCompleto({ especialidad: '' })), null);
  assert.equal(construirTarjeta(perfilCompleto({ especialidad: null })), null);
  const { especialidad, ...sinEspecialidad } = perfilCompleto();
  assert.equal(construirTarjeta(sinEspecialidad), null);
});

test('devuelve null sin datos', () => {
  assert.equal(construirTarjeta(undefined), null);
  assert.equal(construirTarjeta(null), null);
  assert.equal(construirTarjeta('perfil'), null);
});

test('los opcionales ausentes quedan con valores por defecto explícitos', () => {
  const tarjeta = construirTarjeta({
    nombreCompleto: 'Laura Prueba',
    especialidad: 'civil',
    verificado: true,
  });

  assert.deepEqual(tarjeta, {
    nombreCompleto: 'Laura Prueba',
    nombreBusqueda: null,
    fotoUrl: null,
    especialidad: 'civil',
    ubicacionGeneral: null,
    sector: '',
    tarifa: null,
    verificado: true,
    calificacionPromedio: 0,
    cantidadResenas: 0,
  });
});

test('sanea los tipos sin inventar datos', () => {
  const tarjeta = construirTarjeta(
    perfilCompleto({
      nombreBusqueda: 7,
      fotoUrl: { url: 'x' },
      ubicacionGeneral: 3,
      sector: null,
      tarifa: '150000',
      calificacionPromedio: 'cinco',
    })
  );

  assert.equal(tarjeta.nombreBusqueda, null);
  assert.equal(tarjeta.fotoUrl, null);
  assert.equal(tarjeta.ubicacionGeneral, null);
  assert.equal(tarjeta.sector, '');
  assert.equal(tarjeta.tarifa, null);
  assert.equal(tarjeta.calificacionPromedio, 0);
});

test('la tarifa y la calificación deben ser números finitos', () => {
  const infinita = construirTarjeta(perfilCompleto({ tarifa: Infinity, calificacionPromedio: NaN }));
  assert.equal(infinita.tarifa, null);
  assert.equal(infinita.calificacionPromedio, 0);

  const nula = construirTarjeta(perfilCompleto({ tarifa: null }));
  assert.equal(nula.tarifa, null);
});

test('la cantidad de reseñas debe ser un entero no negativo', () => {
  assert.equal(construirTarjeta(perfilCompleto({ cantidadResenas: -3 })).cantidadResenas, 0);
  assert.equal(construirTarjeta(perfilCompleto({ cantidadResenas: 2.5 })).cantidadResenas, 0);
  assert.equal(construirTarjeta(perfilCompleto({ cantidadResenas: '4' })).cantidadResenas, 0);
  assert.equal(construirTarjeta(perfilCompleto({ cantidadResenas: 0 })).cantidadResenas, 0);
  assert.equal(construirTarjeta(perfilCompleto({ cantidadResenas: 9 })).cantidadResenas, 9);
});

test('es determinista: el mismo perfil da tarjetas iguales', () => {
  const a = construirTarjeta(perfilCompleto());
  const b = construirTarjeta(perfilCompleto({ descripcion: 'Otra descripción', telefonoProfesional: '+570000000000' }));

  assert.equal(sonTarjetasIguales(a, b), true);
});

test('compara campo por campo, incluidos los campos de más', () => {
  const base = construirTarjeta(perfilCompleto());

  assert.equal(sonTarjetasIguales(base, { ...base }), true);
  assert.equal(sonTarjetasIguales(base, { ...base, calificacionPromedio: 4.6 }), false);
  assert.equal(sonTarjetasIguales(base, { ...base, fotoUrl: null }), false);
  assert.equal(sonTarjetasIguales(base, { ...base, telefonoProfesional: '+573001112233' }), false);
  const { sector, ...sinSector } = base;
  assert.equal(sonTarjetasIguales(base, sinSector), false);
  assert.equal(sonTarjetasIguales(base, { ...sinSector, otro: '' }), false);
  assert.equal(sonTarjetasIguales(base, null), false);
  assert.equal(sonTarjetasIguales(null, null), true);
});
