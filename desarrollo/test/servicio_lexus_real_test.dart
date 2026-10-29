import 'dart:async';

import 'package:desarrollo/controlador/servicio_lexus_real.dart';
import 'package:desarrollo/modelo/error_lexus.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  // Solo se prueba el mapeo de errores: construir el servicio real tocaría
  // Firebase, que no existe en `flutter test`.
  void espera(Object error, TipoErrorLexus tipo) {
    expect(mapearErrorLexus(error).tipo, tipo, reason: error.toString());
  }

  group('mapearErrorLexus', () {
    test('un ErrorLexus pasa sin cambios', () {
      const original = ErrorLexus(TipoErrorLexus.bloqueoSeguridad);

      expect(identical(mapearErrorLexus(original), original), isTrue);
    });

    test(
      'tiempo agotado',
      () => espera(TimeoutException('lento'), TipoErrorLexus.tiempoAgotado),
    );

    test('sin conexión', () {
      espera(
        http.ClientException('Failed host lookup'),
        TipoErrorLexus.sinConexion,
      );
      espera(Exception('XMLHttpRequest error.'), TipoErrorLexus.sinConexion);
      espera(
        Exception('SocketException: Connection refused'),
        TipoErrorLexus.sinConexion,
      );
    });

    test('cuota', () {
      espera(QuotaExceeded('Quota exceeded'), TipoErrorLexus.cuotaExcedida);
      espera(
        ServerException('RESOURCE_EXHAUSTED'),
        TipoErrorLexus.cuotaExcedida,
      );
      espera(ServerException('HTTP 429'), TipoErrorLexus.cuotaExcedida);
    });

    test('saldo de facturación agotado: servicio no disponible', () {
      // Texto real devuelto por la API (429) con el saldo prepago en cero.
      espera(
        ServerException(
          'Your prepayment credits are depleted. Please go to AI Studio to '
          'manage your project and billing.',
        ),
        TipoErrorLexus.modeloNoDisponible,
      );
    });

    test(
      'sin red, aunque el fallo nombre a App Check, es falta de conexión',
      () {
        espera(
          Exception(
            'AppCheck: Fetch server returned an error '
            '(appCheck/fetch-network-error): Failed to fetch',
          ),
          TipoErrorLexus.sinConexion,
        );
        espera(
          Exception('Error getting App Check token: network error'),
          TipoErrorLexus.sinConexion,
        );
      },
    );

    test('App Check, también cuando llega como ServerException o excepción genérica', () {
      espera(
        ServerException('Firebase App Check token is invalid.'),
        TipoErrorLexus.appCheckRechazado,
      );
      espera(
        ServerException('UNAUTHENTICATED'),
        TipoErrorLexus.appCheckRechazado,
      );
      espera(
        Exception('Error getting App Check token'),
        TipoErrorLexus.appCheckRechazado,
      );
      espera(
        Exception('[firebase_app_check/unknown] fallo'),
        TipoErrorLexus.appCheckRechazado,
      );
    });

    test('modelo o servicio no disponible', () {
      espera(
        ServiceApiNotEnabled('projects/p'),
        TipoErrorLexus.modeloNoDisponible,
      );
      espera(
        InvalidApiKey('clave inválida'),
        TipoErrorLexus.modeloNoDisponible,
      );
      espera(UnsupportedUserLocation(), TipoErrorLexus.modeloNoDisponible);
      espera(
        ServerException('models/x is not found'),
        TipoErrorLexus.modeloNoDisponible,
      );
      espera(
        ServerException('API_KEY_SERVICE_BLOCKED'),
        TipoErrorLexus.modeloNoDisponible,
      );
      espera(
        ServerException('PERMISSION_DENIED'),
        TipoErrorLexus.modeloNoDisponible,
      );
      espera(
        FirebaseAIException('Server Error [503]: servicio caído'),
        TipoErrorLexus.modeloNoDisponible,
      );
    });

    test('respuesta inválida', () {
      espera(const FormatException('JSON'), TipoErrorLexus.respuestaInvalida);
      espera(
        FirebaseAISdkException('no se pudo interpretar'),
        TipoErrorLexus.respuestaInvalida,
      );
    });

    test('lo demás es interno', () {
      espera(StateError('algo'), TipoErrorLexus.interno);
      espera(ServerException('algo inesperado'), TipoErrorLexus.interno);
    });
  });
}
