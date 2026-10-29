// Pruebas de las partes puras de la función de PQRS. Usan el ejecutor de
// pruebas que trae Node (`npm test`), sin dependencias adicionales. La
// transacción del radicado se prueba contra el emulador de Firestore.

const { test } = require('node:test');
const assert = require('node:assert/strict');

const { formatearRadicado, anioEnColombia, construirCorreo } = require('../pqrs');

test('el radicado tiene el formato PQ-AAAA-NNNNNN', () => {
  assert.equal(formatearRadicado(2026, 1), 'PQ-2026-000001');
  assert.equal(formatearRadicado(2026, 123), 'PQ-2026-000123');
  assert.equal(formatearRadicado(2027, 999999), 'PQ-2027-999999');
});

test('el año del radicado se toma en hora de Colombia', () => {
  // 1 de enero de 2027 a las 03:00 UTC es todavía 31 de diciembre de 2026
  // a las 10:00 p. m. en Colombia (UTC-5).
  assert.equal(anioEnColombia(new Date('2027-01-01T03:00:00Z')), 2026);
  assert.equal(anioEnColombia(new Date('2027-01-01T05:00:00Z')), 2027);
});

test('el correo confirma tipo, radicado y fecha', () => {
  const { asunto, texto } = construirCorreo({
    nombre: 'Laura',
    tipo: 'peticion',
    radicado: 'PQ-2026-000123',
    fecha: new Date('2026-09-27T15:30:00Z'),
  });

  assert.equal(asunto, 'ManoLegal — Confirmación de PQRS recibida PQ-2026-000123');
  assert.match(texto, /^Hola, Laura\./);
  assert.match(texto, /Tipo: Petición/);
  assert.match(texto, /Radicado: PQ-2026-000123/);
  // 15:30 UTC son las 10:30 a. m. en Colombia.
  assert.match(texto, /Fecha de recepción: 27 de septiembre de 2026.*10:30.*\(hora de Colombia\)/);
  assert.match(texto, /Equipo ManoLegal$/);
});

test('el correo no incluye la descripción de la PQRS', () => {
  // construirCorreo ni siquiera recibe la descripción: se comprueba que no
  // la acepte por error aunque se la pasen.
  const { texto } = construirCorreo({
    nombre: 'Laura',
    tipo: 'queja',
    radicado: 'PQ-2026-000001',
    fecha: new Date(),
    descripcion: 'Detalle privado de la queja',
  });
  assert.doesNotMatch(texto, /Detalle privado/);
});

test('sin nombre, el saludo queda neutro', () => {
  const { texto } = construirCorreo({ nombre: null, tipo: 'reclamo', radicado: 'PQ-2026-000002', fecha: new Date() });
  assert.match(texto, /^Hola\.\n/);
  assert.match(texto, /Tipo: Reclamo/);
});
