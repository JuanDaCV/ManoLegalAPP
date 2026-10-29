import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../controlador/controlador_autenticacion.dart';
import '../../controlador/servicio_storage.dart';
import '../../modelo/modelo_abogado.dart';
import '../../modelo/modelo_archivo_adjunto.dart';
import '../../modelo/ubicacion_cali.dart';
import '../utilidades/validadores.dart';
import '../widgets_comunes/boton_personalizado.dart';
import '../widgets_comunes/campo_texto_personalizado.dart';
import '../widgets_comunes/plantilla_autenticacion.dart';
import '../widgets_comunes/selector_foto_perfil.dart';
import 'pantalla_registro_abogado_paso3.dart';

/// Paso 2 del registro de abogado: datos profesionales y foto de perfil.
class PantallaRegistroAbogadoPaso2 extends StatefulWidget {
  final String nombre;
  final String apellido;
  final DateTime fechaNacimiento;
  final String telefono;
  final String correo;

  /// `null` cuando el usuario viene del registro con Google (ver
  /// [datosGoogle]): en ese caso el paso 3 completará el registro con
  /// `completarRegistroAbogadoGoogle` en vez de `registrarAbogado`.
  final String? contrasena;

  /// Datos de Google arrastrados desde el paso 1, si el usuario se autenticó
  /// con Google. Se usan aquí solo para intentar precargar la foto de
  /// perfil (ver [_PantallaRegistroAbogadoPaso2State._cargarFotoGoogle]).
  final DatosGoogle? datosGoogle;

  const PantallaRegistroAbogadoPaso2({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.telefono,
    required this.correo,
    required this.contrasena,
    this.datosGoogle,
  });

  @override
  State<PantallaRegistroAbogadoPaso2> createState() => _PantallaRegistroAbogadoPaso2State();
}

class _PantallaRegistroAbogadoPaso2State extends State<PantallaRegistroAbogadoPaso2> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoProfesionalControlador = TextEditingController();
  final _aniosExperienciaControlador = TextEditingController();
  final _tarifaControlador = TextEditingController();
  final _descripcionControlador = TextEditingController();
  final _sectorControlador = TextEditingController();
  final _direccionProfesionalControlador = TextEditingController();
  EspecialidadAbogado _especialidad = EspecialidadAbogado.civil;

  /// Zona general en la que atiende el abogado. Es obligatoria porque el
  /// buscador filtra por ella. No se confunde con la dirección profesional:
  /// la zona es la referencia amplia que ve el cliente en la tarjeta, la
  /// dirección es el lugar concreto de atención.
  UbicacionCali? _ubicacionGeneral;

  ModeloArchivoAdjunto? _foto;

  @override
  void initState() {
    super.initState();
    _cargarFotoGoogle();
  }

  /// Intenta usar la foto de perfil de Google como foto inicial (mejor
  /// esfuerzo). La foto siempre fue opcional en este flujo, así que
  /// cualquier fallo (CORS en web, sin red, formato inesperado, etc.) se
  /// ignora en silencio: el usuario simplemente la elige a mano, como ya
  /// podía hacer antes de que existiera este atajo.
  Future<void> _cargarFotoGoogle() async {
    final url = widget.datosGoogle?.fotoUrl;
    if (url == null) return;
    try {
      final respuesta = await http.get(Uri.parse('$url=s400'));
      if (respuesta.statusCode != 200) return;
      final bytes = respuesta.bodyBytes;
      if (bytes.isEmpty || bytes.length > ServicioStorage.tamanioMaximoFotoBytes) return;
      if (!mounted) return;
      setState(() {
        _foto = ModeloArchivoAdjunto(
          nombreArchivo: 'foto_perfil.jpg',
          tipoContenido: 'image/jpeg',
          tamanio: bytes.length,
          bytes: bytes,
        );
      });
    } catch (_) {
      // Ignorado a propósito: la foto sigue siendo opcional.
    }
  }

  @override
  void dispose() {
    _telefonoProfesionalControlador.dispose();
    _aniosExperienciaControlador.dispose();
    _tarifaControlador.dispose();
    _descripcionControlador.dispose();
    _sectorControlador.dispose();
    _direccionProfesionalControlador.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaRegistroAbogadoPaso3(
          nombre: widget.nombre,
          apellido: widget.apellido,
          fechaNacimiento: widget.fechaNacimiento,
          telefono: widget.telefono,
          correo: widget.correo,
          contrasena: widget.contrasena,
          telefonoProfesional: '+57${_telefonoProfesionalControlador.text.trim()}',
          especialidad: _especialidad,
          aniosExperiencia: int.parse(_aniosExperienciaControlador.text.trim()),
          tarifa: _tarifaControlador.text.trim().isEmpty ? null : double.parse(_tarifaControlador.text.trim()),
          descripcion: _descripcionControlador.text.trim(),
          ubicacionGeneral: _ubicacionGeneral,
          sector: _sectorControlador.text.trim(),
          direccionProfesional: _direccionProfesionalControlador.text.trim(),
          fotoPerfil: _foto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlantillaAutenticacion(
      motivo: MotivoAutenticacion.abogadoPerfil,
      titulo: 'Cuéntanos tu experiencia',
      subtitulo: 'Esta información se mostrará en tu perfil público una vez verificado.',
      paso: 2,
      totalPasos: 3,
      formulario: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Volver'),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Padding(padding: EdgeInsets.only(right: 8), child: Text('+57')),
                Expanded(
                  child: CampoTextoPersonalizado(
                    etiqueta: 'Teléfono profesional',
                    controlador: _telefonoProfesionalControlador,
                    validador: validarTelefonoColombiano,
                    tecladoTipo: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EspecialidadAbogado>(
              initialValue: _especialidad,
              decoration: const InputDecoration(labelText: 'Especialidad'),
              items: EspecialidadAbogado.values
                  .map((valor) => DropdownMenuItem(value: valor, child: Text(valor.textoLegible)))
                  .toList(),
              onChanged: (valor) => setState(() => _especialidad = valor!),
            ),
            const SizedBox(height: 16),
            CampoTextoPersonalizado(
              etiqueta: 'Años de experiencia',
              controlador: _aniosExperienciaControlador,
              tecladoTipo: TextInputType.number,
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) return 'Ingresa tus años de experiencia';
                if (int.tryParse(valor.trim()) == null) return 'Ingresa un número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CampoTextoPersonalizado(
              etiqueta: 'Tarifa por consulta (opcional)',
              controlador: _tarifaControlador,
              tecladoTipo: TextInputType.number,
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) return null;
                if (double.tryParse(valor.trim()) == null) return 'Ingresa un valor válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UbicacionCali>(
              initialValue: _ubicacionGeneral,
              decoration: const InputDecoration(labelText: 'Zona donde atiendes'),
              items: UbicacionCali.values
                  .map((valor) => DropdownMenuItem(value: valor, child: Text(valor.textoLegible)))
                  .toList(),
              onChanged: (valor) => setState(() => _ubicacionGeneral = valor),
              validator: (valor) => valor == null ? 'Selecciona la zona donde atiendes' : null,
            ),
            const SizedBox(height: 16),
            CampoTextoPersonalizado(
              etiqueta: 'Sector o barrio (opcional)',
              controlador: _sectorControlador,
              pista: 'Ejemplo: Granada, San Fernando',
            ),
            const SizedBox(height: 16),
            CampoTextoPersonalizado(
              etiqueta: 'Dirección profesional (opcional)',
              controlador: _direccionProfesionalControlador,
              pista: 'Dirección de tu oficina de atención',
            ),
            const SizedBox(height: 16),
            CampoTextoPersonalizado(
              etiqueta: 'Descripción profesional',
              controlador: _descripcionControlador,
              contadorMaximo: 300,
              validador: validarDescripcionAbogado,
            ),
            const SizedBox(height: 16),
            SelectorFotoPerfil(
              fotoInicial: _foto,
              onFotoSeleccionada: (foto) => setState(() => _foto = foto),
            ),
            const SizedBox(height: 16),
            BotonPersonalizado(texto: 'Continuar', onPressed: _continuar),
          ],
        ),
      ),
    );
  }
}
