package com.walka.cargosort

import android.content.Context
import android.view.Choreographer
import android.view.SurfaceView
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import com.google.android.filament.View.AntiAliasing
import com.google.android.filament.utils.ModelViewer
import com.google.android.filament.utils.Utils
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.nio.ByteBuffer
import kotlin.math.cos
import kotlin.math.sin

class NativeFilamentSceneView(
    context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
) : PlatformView, MethodChannel.MethodCallHandler {
    companion object {
        const val VIEW_TYPE = "cargame/native_filament_scene"
        private const val MODEL_ASSET = "assets/3d/runtime/models/cargame_native_slice_v1.glb"
        private val movableNames = setOf(
            "cargo.demo.electronics",
            "cargo.demo.food",
            "delivery.electronics",
            "delivery.food",
        )

        init {
            Utils.init()
        }
    }

    private val root = FrameLayout(context)
    private val surfaceView = SurfaceView(context)
    private val status = TextView(context)
    private val channel = MethodChannel(messenger, "$VIEW_TYPE/$viewId")
    private val modelViewer = ModelViewer(surfaceView, manipulator = null)
    private val baseTransforms = mutableMapOf<String, FloatArray>()
    private var disposed = false
    private var rendering = false
    private var surfaceEverAttached = false
    private var viewerDestroyedByDetach = false
    private var yaw = 0.82
    private var cameraHeight = 8.7
    private var activeCameraPreset = "overview"
    private var frameCount = 0L
    private var lastFrameTimeNanos = 0L
    private var fpsEstimate = 0.0

    private val frameCallback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            if (!disposed && rendering) {
                if (lastFrameTimeNanos != 0L && frameTimeNanos > lastFrameTimeNanos) {
                    val instantaneousFps =
                        1_000_000_000.0 / (frameTimeNanos - lastFrameTimeNanos).toDouble()
                    fpsEstimate =
                        if (fpsEstimate == 0.0) {
                            instantaneousFps
                        } else {
                            (fpsEstimate * 0.9) + (instantaneousFps * 0.1)
                        }
                }
                lastFrameTimeNanos = frameTimeNanos
                frameCount += 1
                modelViewer.render(frameTimeNanos)
                Choreographer.getInstance().postFrameCallback(this)
            }
        }
    }

    init {
        root.setBackgroundColor(0xff07111d.toInt())
        root.addView(
            surfaceView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        status.text = "Loading native 3D…"
        status.setTextColor(0xffffffff.toInt())
        status.setPadding(20, 16, 20, 16)
        root.addView(
            status,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        surfaceView.addOnAttachStateChangeListener(
            object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(view: View) {
                    surfaceEverAttached = true
                }

                override fun onViewDetachedFromWindow(view: View) {
                    // ModelViewer installs its own detach listener and destroys its
                    // engine/resources when the SurfaceView leaves the window.
                    viewerDestroyedByDetach = true
                }
            },
        )

        channel.setMethodCallHandler(this)
        configureRenderer()
        loadModel(context)
        applyCameraPreset("overview")

        root.addOnAttachStateChangeListener(
            object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(view: View) = startRendering()
                override fun onViewDetachedFromWindow(view: View) = stopRendering()
            },
        )
    }

    private fun configureRenderer() {
        modelViewer.view.antiAliasing = AntiAliasing.FXAA
        modelViewer.view.dynamicResolutionOptions =
            modelViewer.view.dynamicResolutionOptions.apply {
                enabled = true
                quality = com.google.android.filament.View.QualityLevel.MEDIUM
            }
        modelViewer.view.ambientOcclusionOptions =
            modelViewer.view.ambientOcclusionOptions.apply { enabled = true }
        modelViewer.view.bloomOptions =
            modelViewer.view.bloomOptions.apply { enabled = true }
    }

    private fun loadModel(context: Context) {
        try {
            val flutterLoader = FlutterInjector.instance().flutterLoader()
            val lookupKey = flutterLoader.getLookupKeyForAsset(MODEL_ASSET)
            val bytes = context.assets.open(lookupKey).use { it.readBytes() }
            modelViewer.loadModelGlb(ByteBuffer.wrap(bytes))
            cacheTransforms()
            status.text = "Native Filament • GLB • PBR"
            status.postDelayed({ status.visibility = View.GONE }, 1400)
        } catch (error: Throwable) {
            status.text = "Native 3D load failed: ${error.javaClass.simpleName}"
        }
    }

    private fun cacheTransforms() {
        val asset = modelViewer.asset ?: return
        val transformManager = modelViewer.engine.transformManager
        for (name in movableNames) {
            val entity = asset.getFirstEntityByName(name)
            if (entity == 0) continue
            val instance = transformManager.getInstance(entity)
            if (instance == 0) continue
            val matrix = FloatArray(16)
            transformManager.getTransform(instance, matrix)
            baseTransforms[name] = matrix
        }
    }

    private fun startRendering() {
        if (rendering || disposed || viewerDestroyedByDetach) return
        rendering = true
        lastFrameTimeNanos = 0L
        Choreographer.getInstance().postFrameCallback(frameCallback)
    }

    private fun stopRendering() {
        rendering = false
        lastFrameTimeNanos = 0L
        Choreographer.getInstance().removeFrameCallback(frameCallback)
    }

    private fun updateOrbitCamera() {
        activeCameraPreset = "custom"
        val eyeX = cos(yaw) * 13.2
        val eyeY = cameraHeight
        val eyeZ = sin(yaw) * 13.2
        modelViewer.camera.lookAt(
            eyeX,
            eyeY,
            eyeZ,
            0.0,
            0.9,
            0.0,
            0.0,
            1.0,
            0.0,
        )
    }

    private fun applyCameraPreset(preset: String): Boolean {
        val normalized = preset.lowercase()
        val camera =
            when (normalized) {
                "overview" -> doubleArrayOf(9.0, 8.7, 9.3, 0.0, 0.9, 0.0)
                "warehouse" -> doubleArrayOf(-0.8, 6.3, 10.8, -5.6, 1.4, 2.4)
                "docks" -> doubleArrayOf(10.5, 5.8, 1.2, 4.2, 0.7, -0.1)
                else -> return false
            }
        activeCameraPreset = normalized
        modelViewer.camera.lookAt(
            camera[0],
            camera[1],
            camera[2],
            camera[3],
            camera[4],
            camera[5],
            0.0,
            1.0,
            0.0,
        )
        return true
    }

    private fun setPosition(name: String, x: Double, y: Double, z: Double) {
        val asset = modelViewer.asset ?: return
        val base = baseTransforms[name] ?: return
        val entity = asset.getFirstEntityByName(name)
        if (entity == 0) return
        val transformManager = modelViewer.engine.transformManager
        val instance = transformManager.getInstance(entity)
        if (instance == 0) return
        val matrix = base.copyOf()
        matrix[12] = x.toFloat()
        matrix[13] = y.toFloat()
        matrix[14] = z.toFloat()
        transformManager.setTransform(instance, matrix)
    }

    private fun setScale(name: String, multiplier: Float) {
        val asset = modelViewer.asset ?: return
        val base = baseTransforms[name] ?: return
        val entity = asset.getFirstEntityByName(name)
        if (entity == 0) return
        val transformManager = modelViewer.engine.transformManager
        val instance = transformManager.getInstance(entity)
        if (instance == 0) return
        val current = FloatArray(16)
        transformManager.getTransform(instance, current)
        val matrix = base.copyOf()
        matrix[0] *= multiplier
        matrix[5] *= multiplier
        matrix[10] *= multiplier
        matrix[12] = current[12]
        matrix[13] = current[13]
        matrix[14] = current[14]
        transformManager.setTransform(instance, matrix)
    }

    private fun resetEntity(name: String) {
        val asset = modelViewer.asset ?: return
        val matrix = baseTransforms[name]?.copyOf() ?: return
        val entity = asset.getFirstEntityByName(name)
        if (entity == 0) return
        val manager = modelViewer.engine.transformManager
        val instance = manager.getInstance(entity)
        if (instance != 0) manager.setTransform(instance, matrix)
    }

    private fun number(arguments: Map<*, *>, key: String): Double =
        (arguments[key] as? Number)?.toDouble() ?: 0.0

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "setCargoWorldPosition" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    setPosition(
                        args["id"] as? String ?: return result.success(false),
                        number(args, "x"),
                        number(args, "y"),
                        number(args, "z"),
                    )
                    result.success(true)
                }
                "setCargoSelected" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    val id = args["id"] as? String ?: return result.success(false)
                    setScale(id, if (args["selected"] == true) 1.08f else 1.0f)
                    result.success(true)
                }
                "setTargetHover" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    val id = args["id"] as? String ?: return result.success(false)
                    setScale(id, if (args["hovered"] == true) 1.05f else 1.0f)
                    result.success(true)
                }
                "orbitBy" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    yaw -= number(args, "dx") * 0.008
                    cameraHeight =
                        (cameraHeight + number(args, "dy") * 0.025).coerceIn(5.8, 12.5)
                    updateOrbitCamera()
                    result.success(true)
                }
                "setCameraPreset" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    val preset = args["preset"] as? String ?: return result.success(false)
                    result.success(applyCameraPreset(preset))
                }
                "resetCamera" -> result.success(applyCameraPreset("overview"))
                "resetCargo" -> {
                    resetEntity("cargo.demo.electronics")
                    resetEntity("cargo.demo.food")
                    result.success(true)
                }
                "rendererInfo" -> result.success(
                    mapOf(
                        "renderer" to "Google Filament",
                        "version" to "1.74.0",
                        "asset" to MODEL_ASSET,
                        "nativeGpu" to true,
                        "bloom" to true,
                        "cameraPreset" to activeCameraPreset,
                        "frameCount" to frameCount,
                        "fpsEstimate" to fpsEstimate,
                    ),
                )
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.error("native_filament_error", error.message, error.javaClass.name)
        }
    }

    override fun getView(): View = root

    override fun dispose() {
        if (disposed) return
        disposed = true
        stopRendering()
        channel.setMethodCallHandler(null)

        if (!viewerDestroyedByDetach) {
            if (surfaceView.isAttachedToWindow) {
                // Removing the SurfaceView triggers ModelViewer's own detach
                // listener, which performs complete engine/resource teardown.
                root.removeView(surfaceView)
            } else if (!surfaceEverAttached) {
                // A PlatformView that never reached the window cannot receive a
                // detach callback, so release it explicitly exactly once.
                modelViewer.destroy()
                viewerDestroyedByDetach = true
            }
        }
    }
}
