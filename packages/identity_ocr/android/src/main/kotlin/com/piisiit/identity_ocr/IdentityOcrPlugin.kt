package com.piisiit.identity_ocr

import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class IdentityOcrPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (executor.isShutdown) executor = Executors.newSingleThreadExecutor()
        channel = MethodChannel(binding.binaryMessenger, "com.piisiit/identity_ocr")
        channel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "recognize") { result.notImplemented(); return }
        val path = call.argument<String>("path")
        val dataPath = call.argument<String>("dataPath")
        if (path.isNullOrBlank() || dataPath.isNullOrBlank() || !File(path).isFile) {
            result.error("INVALID_IMAGE", "A readable identity photo is required.", null)
            return
        }
        executor.execute {
            var api: TessBaseAPI? = null
            try {
                api = TessBaseAPI()
                check(api.init(dataPath, "khm+eng", TessBaseAPI.OEM_LSTM_ONLY))
                api.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
                api.setImage(File(path))
                val text = api.getUTF8Text() ?: ""
                main.post { result.success(text) }
            } catch (error: Exception) {
                main.post { result.error("OCR_FAILED", "Khmer text could not be read. Please try a clearer photo.", null) }
            } finally {
                api?.recycle()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        executor.shutdown()
    }
}
