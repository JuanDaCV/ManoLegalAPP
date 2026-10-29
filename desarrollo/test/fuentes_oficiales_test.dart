import 'package:desarrollo/vista/administrador/fuentes_oficiales.dart';
import 'package:flutter_test/flutter_test.dart';

/// Protege las dos direcciones oficiales contra una edición accidental: el
/// administrador confía en que estos accesos lo llevan a la fuente oficial.
void main() {
  test('hay exactamente dos fuentes oficiales, con los títulos pedidos', () {
    expect(fuentesOficialesVerificacion.map((f) => f.titulo), [
      'Antecedentes disciplinarios',
      'Vigencia profesional',
    ]);
  });

  test('todas usan HTTPS y un dominio oficial del Estado colombiano', () {
    for (final fuente in fuentesOficialesVerificacion) {
      expect(fuente.direccion.scheme, 'https', reason: fuente.titulo);
      expect(fuente.dominio, endsWith('.gov.co'), reason: fuente.titulo);
    }
  });

  test('antecedentes disciplinarios apunta a la Comisión Nacional de Disciplina Judicial', () {
    expect(fuenteAntecedentesDisciplinarios.dominio, 'antecedentesdisciplinarios.cndj.gov.co');
  });

  test('vigencia profesional apunta al servicio vigente, no a la dirección antigua del SIRNA', () {
    expect(fuenteVigenciaProfesional.dominio, 'vigenciaspublicas.ramajudicial.gov.co');
    expect(fuenteVigenciaProfesional.url, isNot(contains('sirna.ramajudicial.gov.co/Paginas/Certificado.aspx')));
  });
}
