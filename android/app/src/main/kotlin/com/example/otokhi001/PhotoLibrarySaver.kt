package com.kimchheang.pii_note

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

/** Publishes downloaded images to the system photo library. */
class PhotoLibrarySaver(private val activity: Activity) {
    private data class PhotoSave(val bytes: ByteArray, val fileName: String, val result: MethodChannel.Result)
    private var pendingPhotoSave: PhotoSave? = null
    private val photoPermissionRequest = 7341

    fun savePhoto(bytes: ByteArray?, fileName: String?, result: MethodChannel.Result) {
        val extension = fileName?.substringAfterLast('.', "")?.lowercase()
        val mimeType = extension?.let { MimeTypeMap.getSingleton().getMimeTypeFromExtension(it) }
        if (bytes == null || bytes.isEmpty() || fileName.isNullOrBlank() ||
            mimeType == null || !mimeType.startsWith("image/")) {
            result.error("INVALID_IMAGE", "Valid image data is required.", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            if (pendingPhotoSave != null) {
                result.error("PHOTO_SAVE_BUSY", "Another photo save is waiting for permission.", null)
                return
            }
            pendingPhotoSave = PhotoSave(bytes, fileName, result)
            activity.requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), photoPermissionRequest)
            return
        }
        Thread {
            var inserted: Uri? = null
            var legacyFile: File? = null
            try {
                val displayName = "${File(fileName).nameWithoutExtension}_${UUID.randomUUID()}.$extension"
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
                    put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Pii Note")
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    } else {
                        @Suppress("DEPRECATION")
                        val folder = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Pii Note")
                        if (!folder.exists() && !folder.mkdirs()) error("Photo folder could not be created.")
                        legacyFile = File(folder, displayName)
                        @Suppress("DEPRECATION")
                        put(MediaStore.Images.Media.DATA, legacyFile!!.absolutePath)
                    }
                }
                val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                }
                val uri = activity.contentResolver.insert(collection, values)
                    ?: error("Photo entry could not be created.")
                inserted = uri
                val stream = activity.contentResolver.openOutputStream(uri)
                    ?: error("Photo entry could not be opened.")
                stream.use { it.write(bytes) }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val published = ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }
                    if (activity.contentResolver.update(uri, published, null, null) != 1) {
                        error("Photo could not be published.")
                    }
                }
                activity.runOnUiThread { result.success(uri.toString()) }
            } catch (error: Exception) {
                inserted?.let { uri -> runCatching { activity.contentResolver.delete(uri, null, null) } }
                legacyFile?.let { file -> runCatching { file.delete() } }
                activity.runOnUiThread {
                    result.error("PHOTO_SAVE_FAILED", "The image could not be saved to the photo library.", null)
                }
            }
        }.start()
    }

    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (requestCode != photoPermissionRequest) return
        val pending = pendingPhotoSave ?: return
        pendingPhotoSave = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            savePhoto(pending.bytes, pending.fileName, pending.result)
        } else {
            pending.result.error("PHOTO_PERMISSION_DENIED", "Allow saving photos in Settings.", null)
        }
    }

    fun close() {
        pendingPhotoSave?.result?.error("PHOTO_SAVE_CANCELLED", "Photo saving was interrupted.", null)
        pendingPhotoSave = null
    }

}
