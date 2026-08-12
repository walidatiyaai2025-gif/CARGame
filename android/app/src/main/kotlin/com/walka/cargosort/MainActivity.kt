package com.walka.cargosort

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            NativeFilamentSceneView.VIEW_TYPE,
            NativeFilamentSceneFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
    }
}
