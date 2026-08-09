package com.example.mobile

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.agdata.mobile/downloader")
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    if (bytes == null || fileName == null) {
                        result.error("INVALID_ARGS", "bytes e fileName são obrigatórios", null)
                        return@setMethodCallHandler
                    }
                    saveFile(bytes, fileName, mimeType, result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveFile(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        result: MethodChannel.Result,
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ — usa MediaStore.Downloads (não precisa de permissão de escrita)
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val uri = contentResolver.insert(collection, values)
                if (uri != null) {
                    contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                    values.clear()
                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                    contentResolver.update(uri, values, null, null)
                    result.success("Downloads/$fileName")
                } else {
                    result.error("INSERT_FAILED", "MediaStore insert retornou null", null)
                }
            } else {
                // Android 9 e inferior — escrita direta (requer WRITE_EXTERNAL_STORAGE no manifest)
                val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                dir.mkdirs()
                val file = File(dir, fileName)
                file.writeBytes(bytes)
                result.success(file.absolutePath)
            }
        } catch (e: Exception) {
            result.error("SAVE_ERROR", e.message, null)
        }
    }
}
