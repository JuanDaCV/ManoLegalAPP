import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException, GoogleSignInExceptionCode;

import '../modelo/modelo_abogado.dart';
import '../modelo/modelo_archivo_adjunto.dart';
import '../modelo/modelo_cliente.dart';
import '../modelo/modelo_documento_abogado.dart';
import 'servicio_firestore.dart';
import 'servicio_google.dart';
import 'servicio_storage.dart';

/// Rol resuelto del usuario autenticado.
enum RolUsuario { cliente, abogado, administrador, desconocido, cargando, error }

/// Resultado de [ControladorAutenticacion.autenticarConGoogle].
enum EstadoGoogle { perfilExistente, perfilPendiente, cancelado, error }

/// Datos básicos tomados de la cuenta de Google, usados para autorrellenar
/// el formulario de registro cuando todavía no existe un perfil en Firestore.
class DatosGoogle {
  final String nombre;
  final String apellido;
  final String correo;
  final String? fotoUrl;

  const DatosGoogle({
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.fotoUrl,
  });
}

/// Resultado devuelto por [ControladorAutenticacion.autenticarConGoogle].
/// El mensaje de error, si lo hay, se expone como siempre a través de
/// [ControladorAutenticacion.mensajeError] (el mismo mecanismo que ya usan
/// [ControladorAutenticacion.iniciarSesion] y el resto de métodos).
class ResultadoGoogle {
  final EstadoGoogle estado;
  final DatosGoogle? datos;

  const ResultadoGoogle({required this.estado, this.datos});
}

/// Claves de documentos obligatorios para completar el registro de abogado.
const List<String> _clavesDocumentosObligatorios = [
  'cedula',
  'tarjeta_profesional',
  'certificado_rna',
  'antecedentes',
];

/// Maneja el ciclo de autenticación y la resolución de rol del usuario.
class ControladorAutenticacion extends ChangeNotifier {
  // Debe coincidir con la cuenta de administrador creada manualmente en la consola de Firebase.
  static const String correoAdministrador = 'admin@manolegal.com';

  final ServicioFirestore _servicioFirestore;
  final ServicioStorage _servicioStorage;
  final ServicioGoogle _servicioGoogle;

  ControladorAutenticacion({
    ServicioFirestore? servicioFirestore,
    ServicioStorage? servicioStorage,
    ServicioGoogle? servicioGoogle,
  })  : _servicioFirestore = servicioFirestore ?? ServicioFirestore(),
        _servicioStorage = servicioStorage ?? ServicioStorage(),
        _servicioGoogle = servicioGoogle ?? ServicioGoogle();

  RolUsuario rolActual = RolUsuario.cargando;
  bool cargando = false;
  String? mensajeError;
  String? _uidResuelto;

  /// Evita que [resolverRol] se dispare mientras un registro está en curso:
  /// el usuario de Auth ya existe pero el perfil de Firestore todavía no,
  /// así que resolverlo en ese instante lo clasificaría como "desconocido".
  bool _registroEnCurso = false;

  Future<bool> iniciarSesion(String correo, String contrasena) async {
    _iniciarCarga();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: correo, password: contrasena);
      return true;
    } catch (e) {
      mensajeError = _mensajeDesdeExcepcion(e);
      return false;
    } finally {
      _terminarCarga();
    }
  }

  Future<void> cerrarSesion() async {
    await _servicioGoogle.cerrarSesion();
    await FirebaseAuth.instance.signOut();
    rolActual = RolUsuario.cargando;
    _uidResuelto = null;
    _registroEnCurso = false;
    mensajeError = null;
    notifyListeners();
  }

  Future<bool> recuperarContrasena(String correo) async {
    _iniciarCarga();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: correo);
      return true;
    } catch (e) {
      mensajeError = _mensajeDesdeExcepcion(e);
      return false;
    } finally {
      _terminarCarga();
    }
  }

  Future<bool> registrarCliente(ModeloCliente cliente, String contrasena) async {
    _iniciarCarga();
    try {
      _registroEnCurso = true;
      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cliente.correo,
        password: contrasena,
      );
      final uid = credencial.user!.uid;

      try {
        await credencial.user?.sendEmailVerification();
        await _guardarPerfilCliente(uid, cliente);

        _uidResuelto = uid;
        rolActual = RolUsuario.cliente;
        _registroEnCurso = false;
        notifyListeners();
        return true;
      } catch (e) {
        await _borrarUsuarioHuerfano(credencial.user);
        _registroEnCurso = false;
        mensajeError = _mensajeDesdeExcepcion(e);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _registroEnCurso = false;
      mensajeError = _mensajeDesdeExcepcion(e);
      notifyListeners();
      return false;
    } finally {
      _terminarCarga();
    }
  }

  /// Registra un abogado subiendo sus documentos a Firebase Storage (ver
  /// [ServicioStorage]). Las claves de [archivos] son las 6 claves de
  /// documento conocidas (`foto_perfil` incluida; `diploma` opcional).
  ///
  /// Si algo falla después de subir archivos, se borran los ya subidos antes
  /// de propagar el error, y la cuenta de Authentication recién creada se
  /// elimina. El registro no deja restos a medio camino.
  Future<bool> registrarAbogado(
    ModeloAbogado abogadoSinRutas,
    String contrasena,
    Map<String, ModeloArchivoAdjunto> archivos,
  ) async {
    _iniciarCarga();
    try {
      for (final clave in _clavesDocumentosObligatorios) {
        if (archivos[clave] == null) {
          throw ArgumentError('Falta el documento obligatorio: $clave');
        }
      }

      _registroEnCurso = true;
      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: abogadoSinRutas.correo,
        password: contrasena,
      );
      final uid = credencial.user!.uid;

      try {
        await credencial.user?.sendEmailVerification();
        await _guardarPerfilAbogado(uid, abogadoSinRutas, archivos);

        _uidResuelto = uid;
        rolActual = RolUsuario.abogado;
        _registroEnCurso = false;
        notifyListeners();
        return true;
      } catch (e) {
        await _borrarUsuarioHuerfano(credencial.user);
        _registroEnCurso = false;
        mensajeError = _mensajeDesdeExcepcion(e);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _registroEnCurso = false;
      mensajeError = _mensajeDesdeExcepcion(e);
      notifyListeners();
      return false;
    } finally {
      _terminarCarga();
    }
  }

  /// Autentica con Google (ver [ServicioGoogle]) y decide si el usuario ya
  /// tiene un perfil en Firestore o si debe completar el registro.
  ///
  /// Mientras el perfil está pendiente de completar, fija [_registroEnCurso]
  /// para que [resolverRol] no clasifique al usuario como "desconocido"
  /// mientras llena el formulario de registro (igual que en
  /// [registrarCliente]/[registrarAbogado]).
  Future<ResultadoGoogle> autenticarConGoogle() async {
    _iniciarCarga();
    try {
      final credencial = await _servicioGoogle.autenticar();
      final usuario = credencial.user!;
      final uid = usuario.uid;

      final cliente = await _servicioFirestore.obtenerCliente(uid);
      final abogado = cliente != null ? null : await _servicioFirestore.obtenerAbogado(uid);
      if (cliente != null || abogado != null) {
        return const ResultadoGoogle(estado: EstadoGoogle.perfilExistente);
      }

      _registroEnCurso = true;
      final (nombre, apellido) = _partirNombreGoogle(usuario.displayName);
      return ResultadoGoogle(
        estado: EstadoGoogle.perfilPendiente,
        datos: DatosGoogle(
          nombre: nombre,
          apellido: apellido,
          correo: usuario.email ?? '',
          fotoUrl: usuario.photoURL,
        ),
      );
    } catch (e) {
      if (_esCancelacionGoogle(e)) {
        return const ResultadoGoogle(estado: EstadoGoogle.cancelado);
      }
      mensajeError = _mensajeDesdeExcepcion(e);
      return const ResultadoGoogle(estado: EstadoGoogle.error);
    } finally {
      _terminarCarga();
    }
  }

  /// Completa el registro de un cliente que ya se autenticó con Google (ver
  /// [autenticarConGoogle]). A diferencia de [registrarCliente], no hay
  /// rollback si falla: la cuenta de Google ya existe y el usuario puede
  /// simplemente reintentar el formulario.
  Future<bool> completarRegistroClienteGoogle(ModeloCliente cliente) async {
    _iniciarCarga();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw ArgumentError('No hay una sesión de Google activa para completar el registro');
      }
      await _guardarPerfilCliente(uid, cliente);

      _uidResuelto = uid;
      rolActual = RolUsuario.cliente;
      _registroEnCurso = false;
      notifyListeners();
      return true;
    } catch (e) {
      mensajeError = _mensajeDesdeExcepcion(e);
      notifyListeners();
      return false;
    } finally {
      _terminarCarga();
    }
  }

  /// Completa el registro de un abogado que ya se autenticó con Google (ver
  /// [autenticarConGoogle]). Sin rollback, por la misma razón que
  /// [completarRegistroClienteGoogle].
  Future<bool> completarRegistroAbogadoGoogle(
    ModeloAbogado abogadoSinRutas,
    Map<String, ModeloArchivoAdjunto> archivos,
  ) async {
    _iniciarCarga();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw ArgumentError('No hay una sesión de Google activa para completar el registro');
      }
      await _guardarPerfilAbogado(uid, abogadoSinRutas, archivos);

      _uidResuelto = uid;
      rolActual = RolUsuario.abogado;
      _registroEnCurso = false;
      notifyListeners();
      return true;
    } catch (e) {
      mensajeError = _mensajeDesdeExcepcion(e);
      notifyListeners();
      return false;
    } finally {
      _terminarCarga();
    }
  }

  /// Guarda el perfil de un cliente en Firestore con el [uid] ya asignado.
  Future<void> _guardarPerfilCliente(String uid, ModeloCliente cliente) async {
    final clienteConUid = ModeloCliente(
      uid: uid,
      nombre: cliente.nombre,
      apellido: cliente.apellido,
      fechaNacimiento: cliente.fechaNacimiento,
      telefono: cliente.telefono,
      correo: cliente.correo,
    );
    await _servicioFirestore.guardarCliente(clienteConUid);
  }

  /// Sube los documentos de un abogado y guarda su perfil en Firestore con
  /// el [uid] ya asignado.
  Future<void> _guardarPerfilAbogado(
    String uid,
    ModeloAbogado abogadoSinRutas,
    Map<String, ModeloArchivoAdjunto> archivos,
  ) async {
    // Lo que se guarda en Firestore y lo que hay que borrar en Storage no es
    // lo mismo: de la foto se guarda su URL de descarga, pero para borrarla
    // hace falta su ruta. Por eso se llevan dos listas.
    final valoresParaFirestore = <String, String>{};
    final rutasParaBorrar = <String>[];

    try {
      for (final entrada in archivos.entries) {
        if (entrada.key == 'foto_perfil') {
          valoresParaFirestore[entrada.key] =
              await _servicioStorage.subirFotoPerfil(uid, entrada.value);
          rutasParaBorrar.add(ServicioStorage.rutaFotoPerfil(uid));
        } else {
          final ruta = await _servicioStorage.subirDocumento(uid, entrada.key, entrada.value);
          valoresParaFirestore[entrada.key] = ruta;
          rutasParaBorrar.add(ruta);
        }
      }

      final abogadoFinal = ModeloAbogado(
        uid: uid,
        nombre: abogadoSinRutas.nombre,
        apellido: abogadoSinRutas.apellido,
        fechaNacimiento: abogadoSinRutas.fechaNacimiento,
        telefono: abogadoSinRutas.telefono,
        correo: abogadoSinRutas.correo,
        telefonoProfesional: abogadoSinRutas.telefonoProfesional,
        especialidad: abogadoSinRutas.especialidad,
        aniosExperiencia: abogadoSinRutas.aniosExperiencia,
        tarifa: abogadoSinRutas.tarifa,
        descripcion: abogadoSinRutas.descripcion,
        fotoPerfilRuta: valoresParaFirestore['foto_perfil'] ?? '',
        documentos: ModeloDocumentoAbogado(
          cedulaRuta: valoresParaFirestore['cedula']!,
          tarjetaProfesionalRuta: valoresParaFirestore['tarjeta_profesional']!,
          certificadoRnaRuta: valoresParaFirestore['certificado_rna']!,
          diplomaRuta: valoresParaFirestore['diploma'],
          antecedentesRuta: valoresParaFirestore['antecedentes']!,
        ),
        // Todo abogado nace pendiente. Las reglas de Firestore rechazan la
        // creación con cualquier otro estado, así que no basta con fijarlo
        // aquí: tampoco se puede eludir desde fuera de la aplicación.
        estado: 'pendiente',
        ubicacionGeneral: abogadoSinRutas.ubicacionGeneral,
        sector: abogadoSinRutas.sector,
        direccionProfesional: abogadoSinRutas.direccionProfesional,
        correoContacto: abogadoSinRutas.correo,
      );

      // Documento privado y perfil público en un solo lote atómico: o quedan
      // los dos, o no queda ninguno.
      await _servicioFirestore.guardarAbogadoConPerfilPublico(abogadoFinal, esCreacion: true);
    } catch (e) {
      await _limpiarArchivosSubidos(rutasParaBorrar);
      rethrow;
    }
  }

  /// Borra los archivos que ya se habían subido cuando el registro falla más
  /// adelante. Sin esta limpieza quedarían huérfanos en Storage: ocupando
  /// espacio y sin ningún documento de Firestore que los referencie.
  Future<void> _limpiarArchivosSubidos(List<String> rutas) async {
    if (rutas.isEmpty) return;
    try {
      await _servicioStorage.eliminarRutas(rutas);
    } catch (_) {
      // La limpieza es un mejor esfuerzo. Si también falla, el error que se
      // propaga debe seguir siendo el original: es el que explica al usuario
      // por qué no se completó su registro.
    }
  }

  /// Datos de Google del usuario ya autenticado, para autorrellenar el
  /// formulario cuando se llega a completar el registro por un camino
  /// distinto al botón de Google: por ejemplo, al retomar un registro
  /// abandonado desde [EnrutadorInicial]. Devuelve `null` si no hay sesión.
  DatosGoogle? datosGoogleDelUsuarioActual() {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;
    final (nombre, apellido) = _partirNombreGoogle(usuario.displayName);
    return DatosGoogle(
      nombre: nombre,
      apellido: apellido,
      correo: usuario.email ?? '',
      fotoUrl: usuario.photoURL,
    );
  }

  /// Divide el `displayName` de Google en nombre y apellido: el primer
  /// espacio separa el primer token (nombre) del resto (apellido). Si no hay
  /// espacio, todo el texto va a nombre y el apellido queda vacío; ambos
  /// campos siguen siendo editables en el formulario para que el usuario los
  /// corrija si hace falta.
  (String, String) _partirNombreGoogle(String? displayName) {
    final texto = displayName?.trim() ?? '';
    if (texto.isEmpty) return ('', '');
    final indice = texto.indexOf(' ');
    if (indice == -1) return (texto, '');
    return (texto.substring(0, indice), texto.substring(indice + 1).trim());
  }

  /// Indica si [e] representa una cancelación del usuario en el flujo de
  /// Google (cerrar el popup en web, o cancelar el selector de cuenta en
  /// nativo), que no debe tratarse como un error.
  bool _esCancelacionGoogle(Object e) {
    if (e is GoogleSignInException) {
      return e.code == GoogleSignInExceptionCode.canceled;
    }
    if (e is FirebaseAuthException) {
      return e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request';
    }
    return false;
  }

  /// Borra la cuenta de Auth recién creada si algo falló después de crearla
  /// (verificación de correo, guardado del perfil o de los documentos), para
  /// no dejar cuentas huérfanas sin perfil en Firestore.
  Future<void> _borrarUsuarioHuerfano(User? usuario) async {
    try {
      await usuario?.delete();
    } catch (_) {
      // Si no se puede borrar, la cuenta queda huérfana y deberá limpiarse
      // manualmente; no debe ocultar el error original del registro.
    }
  }

  /// Resuelve el rol del usuario autenticado consultando Firestore.
  /// Se llama una sola vez por [uid] (ver [_uidResuelto]).
  Future<void> resolverRol(User usuario) async {
    if (_registroEnCurso) return;
    if (_uidResuelto == usuario.uid) return;
    _uidResuelto = usuario.uid;
    rolActual = RolUsuario.cargando;
    notifyListeners();

    try {
      if (usuario.email == correoAdministrador) {
        rolActual = RolUsuario.administrador;
        notifyListeners();
        return;
      }

      final cliente = await _servicioFirestore.obtenerCliente(usuario.uid);
      if (cliente != null) {
        rolActual = RolUsuario.cliente;
        notifyListeners();
        return;
      }

      final abogado = await _servicioFirestore.obtenerAbogado(usuario.uid);
      if (abogado != null) {
        rolActual = RolUsuario.abogado;
        notifyListeners();
        return;
      }

      rolActual = RolUsuario.desconocido;
      notifyListeners();
    } catch (e) {
      rolActual = RolUsuario.error;
      mensajeError = _mensajeDesdeExcepcion(e);
      notifyListeners();
    }
  }

  /// Reintenta resolver el rol del usuario actualmente autenticado, por
  /// ejemplo tras un error de red mostrado en [EnrutadorInicial].
  Future<void> reintentarResolverRol() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;
    _uidResuelto = null;
    await resolverRol(usuario);
  }

  void _iniciarCarga() {
    cargando = true;
    mensajeError = null;
    notifyListeners();
  }

  void _terminarCarga() {
    cargando = false;
    notifyListeners();
  }

  /// Traduce una excepción técnica a un mensaje entendible para el usuario.
  String _mensajeDesdeExcepcion(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Ese correo ya está registrado';
        case 'weak-password':
          return 'La contraseña es demasiado débil (mínimo 6 caracteres)';
        case 'invalid-email':
          return 'El correo no es válido';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos';
        case 'account-exists-with-different-credential':
          return 'Ese correo ya está registrado con contraseña. Inicia sesión con tu correo y contraseña';
        case 'network-request-failed':
          return 'Sin conexión a internet';
        case 'too-many-requests':
          return 'Demasiados intentos, espera un momento';
        default:
          return 'Ocurrió un error de autenticación';
      }
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'unavailable':
          return 'No se pudo conectar con el servidor. Revisa tu conexión';
        case 'permission-denied':
          return 'No tienes permisos para esta operación';
        default:
          return 'Ocurrió un error al guardar los datos';
      }
    }
    if (e is ArgumentError) {
      return e.message?.toString() ?? 'Ocurrió un error inesperado';
    }
    return 'Ocurrió un error inesperado';
  }
}
