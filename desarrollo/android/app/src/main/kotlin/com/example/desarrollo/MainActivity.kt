package com.example.desarrollo

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// En Android, `video_player` no evita que la pantalla se apague mientras se
// reproduce un video. La guía "Cómo funciona" tiene videos de más de un minuto,
// así que Flutter le pide a esta actividad, por el canal "manolegal/pantalla",
// que active la bandera FLAG_KEEP_SCREEN_ON solo mientras uno se reproduce y
// que la quite al pausarlo o al salir.
class MainActivity : FlutterActivity() {
    private var canalPantalla: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        canalPantalla = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "manolegal/pantalla").also { canal ->
            canal.setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "mantenerEncendida" -> {
                        val encendida = llamada.arguments as? Boolean
                        if (encendida == null) {
                            resultado.error("argumento_invalido", "Se esperaba un booleano.", null)
                        } else {
                            if (encendida) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            resultado.success(null)
                        }
                    }
                    else -> resultado.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        canalPantalla?.setMethodCallHandler(null)
        canalPantalla = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
