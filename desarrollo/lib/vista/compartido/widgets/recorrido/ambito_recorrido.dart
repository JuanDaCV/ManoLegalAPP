import 'package:flutter/widgets.dart';

import '../../../../modelo/modelo_paso_recorrido.dart';
import 'registro_marcas_recorrido.dart';

/// Pone el [RegistroMarcasRecorrido] al alcance de los [MarcaRecorrido] que
/// están debajo. Sin este ámbito las marcas no hacen nada.
class AmbitoRecorrido extends InheritedWidget {
  const AmbitoRecorrido({
    super.key,
    required this.registro,
    required super.child,
  });

  final RegistroMarcasRecorrido registro;

  static AmbitoRecorrido? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AmbitoRecorrido>();
  }

  @override
  bool updateShouldNotify(AmbitoRecorrido oldWidget) =>
      registro != oldWidget.registro;
}

/// Marca [child] como un elemento que el recorrido guiado puede señalar.
///
/// Sin un [AmbitoRecorrido] por encima devuelve [child] tal cual, sin agregar
/// nada al árbol: así los widgets compartidos (el buscador, la tarjeta de
/// abogado) se pueden marcar sin cambiar las pantallas que no tienen
/// recorrido, como la landing o el perfil público.
class MarcaRecorrido extends StatelessWidget {
  const MarcaRecorrido({super.key, required this.id, required this.child});

  final MarcaRecorridoId id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ambito = AmbitoRecorrido.maybeOf(context);
    if (ambito == null) return child;
    return _RegistradorMarca(id: id, registro: ambito.registro, child: child);
  }
}

/// Registra su propio contexto como la marca [id] mientras está montado.
///
/// No agrega ningún `RenderObject`: su contexto resuelve al mismo render
/// object que [child], así que no cambia el layout.
class _RegistradorMarca extends StatefulWidget {
  const _RegistradorMarca({
    required this.id,
    required this.registro,
    required this.child,
  });

  final MarcaRecorridoId id;
  final RegistroMarcasRecorrido registro;
  final Widget child;

  @override
  State<_RegistradorMarca> createState() => _RegistradorMarcaState();
}

class _RegistradorMarcaState extends State<_RegistradorMarca> {
  /// Se registra aquí y no en `initState` porque `Visibility.of` depende de un
  /// `InheritedWidget`: así, cuando una pestaña oculta de un `IndexedStack`
  /// se muestra (o al revés), la marca se vuelve a registrar con su estado.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registrar();
  }

  @override
  void didUpdateWidget(_RegistradorMarca oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        !identical(oldWidget.registro, widget.registro)) {
      oldWidget.registro.liberar(oldWidget.id, this);
      _registrar();
    }
  }

  @override
  void dispose() {
    widget.registro.liberar(widget.id, this);
    super.dispose();
  }

  void _registrar() {
    widget.registro.registrar(
      widget.id,
      context,
      propietario: this,
      visible: Visibility.of(context),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
