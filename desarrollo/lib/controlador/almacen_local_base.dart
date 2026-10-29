/// Almacén local de pares clave-valor del dispositivo: `localStorage` en Web
/// y un archivo JSON en móvil. Las claves y los valores son texto.
///
/// Lo usa el recorrido guiado, que solo necesita recordar «ya lo vi», por lo
/// que no vale la pena una dependencia de persistencia para esto.
abstract interface class AlmacenLocal {
  /// Devuelve el valor de [clave], o `null` si no hay ninguno.
  ///
  /// Lanza si el almacén no se puede leer. No devuelve `null` en ese caso:
  /// confundir «no puedo leer» con «no hay nada» haría reaparecer el
  /// recorrido en cada visita a quien ya lo vio.
  Future<String?> leer(String clave);

  /// Guarda [valor] bajo [clave]. Es de mejor esfuerzo: si el almacén no deja
  /// escribir (navegador en modo privado, disco lleno), no lanza.
  Future<void> escribir(String clave, String valor);

  /// Borra [clave]. Igual que [escribir], es de mejor esfuerzo.
  Future<void> borrar(String clave);
}
