package com.example.otokhi001

import android.net.Uri
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kimchheang.otokhi-note/content_uri"
        ).setMethodCallHandler { call, result ->
            if (call.method != "copyContentUriToCache") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val rawUri = call.argument<String>("uri")
            if (rawUri.isNullOrBlank()) {
                result.error("INVALID_URI", "A content URI is required.", null)
                return@setMethodCallHandler
            }

            try {
                val requestedExtension = call.argument<String>("extension") ?: ".jpg"
                val extension = if (requestedExtension.matches(Regex("\\.[A-Za-z0-9]{1,8}"))) {
                    requestedExtension.lowercase()
                } else {
                    ".jpg"
                }
                val output = File.createTempFile("scanned_page_", extension, cacheDir)
                val input = contentResolver.openInputStream(Uri.parse(rawUri))
                    ?: throw IllegalStateException("The scanned page could not be opened.")
                input.use { source ->
                    output.outputStream().use { destination ->
                        source.copyTo(destination)
                    }
                }
                result.success(output.absolutePath)
            } catch (error: Exception) {
                result.error(
                    "COPY_FAILED",
                    "The scanned page could not be copied.",
                    error.localizedMessage
                )
            }
        }
    }
}
