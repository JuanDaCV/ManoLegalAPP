# Pruebas de las reglas de Firestore

Verifican `../firestore.rules` contra el emulador de Firestore, sin tocar ningún
proyecto real: usan el id `demo-manolegal` (el prefijo `demo-` impide que el
emulador llegue a un proyecto de verdad). Hoy cubren las conversaciones con
Lexus (`clientes/{uid}/conversacionesLexus`), que el resto de `clientes/{uid}`
siga igual y la lectura pública de `tarjetasAbogados`
(`tarjetas_abogados.test.js`).

## Requisitos

- Node.js (con `npm`).
- Java, que necesita el emulador de Firestore.
- Firebase CLI (`firebase-tools`).

## Primera vez

```bash
npm --prefix pruebas_reglas install
```

## Ejecutar

Desde la carpeta `desarrollo/`:

```bash
firebase emulators:exec --only firestore --project demo-manolegal "npm --prefix pruebas_reglas test"
```

El comando levanta el emulador de Firestore (puerto 8080, el de `firebase.json`),
corre las pruebas y lo apaga. Si el puerto 8080 está ocupado, ciérralo antes.

En Windows, al terminar (incluso bien) puede quedar abierto el proceso `java` del
emulador, y la siguiente ejecución falla con "port taken". Para cerrarlo desde
PowerShell:

```powershell
Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
  Where-Object { $_.CommandLine -match 'cloud-firestore-emulator' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

## Qué se prueba

- El dueño crea una conversación con su primer mensaje en un solo lote y la lee.
- El administrador (`admin@manolegal.com`), otro cliente, un abogado y quien no
  tiene sesión no pueden leer ni escribir.
- Se rechazan campos de más, textos demasiado largos, fechas inventadas, turnos
  que suben de a más de uno o pasan de 30, y reactivar o modificar una
  conversación cerrada.
- No se borra nada y el texto de un mensaje no se puede cambiar.
- Regresión: el administrador y el dueño siguen leyendo `clientes/{uid}`.
- `tarjetasAbogados`: sin sesión se lee una tarjeta y se listan con un límite de
  100 o menos; nadie las escribe; sin sesión no se abre nada más, y los perfiles
  públicos completos siguen exigiendo sesión.

## Sobre los tamaños

Las reglas cuentan los textos en unidades UTF-16 (`size()`), no en caracteres: un
emoji vale 2. La app admite 2000 caracteres, que con emojis llegan a 4000
unidades, por eso las reglas topan el texto en 4000. El límite exacto de 2000
caracteres lo impone la app (`ConfiguracionLexus.largoMaximoMensaje`).
