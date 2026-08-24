package com.example.vsf_consumer

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Hosts the "vsf_consumer/receipt_saver" method channel used by
 * ReceiptPdfService to save receipt PDFs into the device's
 * public Downloads folder.
 *
 * Storage strategy (no MANAGE_EXTERNAL_STORAGE anywhere):
 *
 *  - Android 10 (API 29)+: MediaStore.Downloads insert via the
 *    ContentResolver. Scoped-storage compliant and requires NO
 *    runtime permission.
 *  - Android 9 (API 28) and below: direct write into the public
 *    Downloads directory, covered by the legacy
 *    WRITE_EXTERNAL_STORAGE permission (declared in the
 *    manifest with maxSdkVersion=28 and requested at runtime
 *    only when actually needed).
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_NAME = "vsf_consumer/receipt_saver"
        private const val SAVE_PDF_METHOD = "savePdf"
        private const val PERMISSION_REQUEST_CODE = 4711
    }

    /** Pending legacy-API save while a permission dialog shows. */
    private var pendingBytes: ByteArray? = null
    private var pendingFileName: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                SAVE_PDF_METHOD -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName")

                    if (bytes == null || fileName.isNullOrEmpty()) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "bytes and fileName are required.",
                            null,
                        )
                    } else {
                        savePdf(bytes, fileName, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // ------------------------------------------------------------
    // SAVE ENTRY POINT
    // ------------------------------------------------------------

    private fun savePdf(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Modern scoped storage: MediaStore.Downloads, no
            // permission required.
            try {
                result.success(saveViaMediaStore(fileName, bytes))
            } catch (e: Exception) {
                result.error(
                    "SAVE_FAILED",
                    e.message ?: "Unable to save PDF to Downloads.",
                    null,
                )
            }
            return
        }

        // Legacy devices (API <= 28): direct public-Downloads
        // write guarded by WRITE_EXTERNAL_STORAGE.
        val granted =
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ) == PackageManager.PERMISSION_GRANTED

        if (granted) {
            saveViaLegacyDownloads(bytes, fileName, result)
            return
        }

        // Stash the request and ask once; the completion continues
        // in onRequestPermissionsResult.
        pendingBytes = bytes
        pendingFileName = fileName
        pendingResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
            PERMISSION_REQUEST_CODE,
        )
    }

    // ------------------------------------------------------------
    // ANDROID 10+: MEDIASTORE.DOWNLOADS (NO PERMISSION NEEDED)
    // ------------------------------------------------------------

    private fun saveViaMediaStore(
        fileName: String,
        bytes: ByteArray,
    ): String {
        val resolver = contentResolver

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            values,
        ) ?: throw IllegalStateException(
            "Could not create the Downloads entry.",
        )

        try {
            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IllegalStateException(
                "Could not open the Downloads output stream.",
            )

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            // Do not leave a pending/partial entry behind.
            runCatching { resolver.delete(uri, null, null) }
            throw e
        }

        // MediaStore de-duplicates display names automatically,
        // so the visible file is exactly Downloads/<fileName>.
        return "Downloads/$fileName"
    }

    // ------------------------------------------------------------
    // ANDROID 9 AND BELOW: DIRECT PUBLIC DOWNLOADS WRITE
    // ------------------------------------------------------------

    private fun saveViaLegacyDownloads(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        try {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS,
            )

            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }

            // Avoid overwriting an earlier receipt with the same
            // name: append " (n)" before the extension.
            var target = File(downloadsDir, fileName)
            var counter = 1
            while (target.exists()) {
                val dotIndex = fileName.lastIndexOf('.')
                val base = if (dotIndex > 0) fileName.substring(0, dotIndex) else fileName
                val extension = if (dotIndex > 0) fileName.substring(dotIndex) else ""

                target = File(downloadsDir, "$base ($counter)$extension")
                counter++
            }

            FileOutputStream(target).use { output ->
                output.write(bytes)
                output.flush()
            }

            result.success(target.absolutePath)
        } catch (e: Exception) {
            result.error(
                "SAVE_FAILED",
                e.message ?: "Unable to save PDF to Downloads.",
                null,
            )
        }
    }

    // ------------------------------------------------------------
    // LEGACY RUNTIME-PERMISSION CALLBACK
    // ------------------------------------------------------------

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != PERMISSION_REQUEST_CODE) {
            return
        }

        val result = pendingResult
        val bytes = pendingBytes
        val fileName = pendingFileName

        pendingResult = null
        pendingBytes = null
        pendingFileName = null

        if (result == null || bytes == null || fileName == null) {
            return
        }

        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            saveViaLegacyDownloads(bytes, fileName, result)
        } else {
            result.error(
                "PERMISSION_DENIED",
                "Storage permission was denied, so the receipt could not be saved to Downloads.",
                null,
            )
        }
    }
}
