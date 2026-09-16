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
 * Hosts two method channels:
 *
 *  - "vsf_consumer/receipt_saver"  -> savePdf  (receipt PDFs to Downloads)
 *  - "vsf_consumer/qr_image_saver" -> saveImage (QR PNGs to Pictures/VSF)
 *
 * Storage strategy (no MANAGE_EXTERNAL_STORAGE anywhere):
 *
 *  - Android 10 (API 29)+: MediaStore inserts via the ContentResolver
 *    (Downloads for PDFs, Images under Pictures/VSF for QRs).
 *    Scoped-storage compliant, requires NO runtime permission.
 *  - Android 9 (API 28) and below: direct write into the legacy
 *    public Downloads/Pictures directories, guarded by
 *    WRITE_EXTERNAL_STORAGE (declared in the manifest with
 *    maxSdkVersion=28 and requested at runtime only when needed).
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_NAME = "vsf_consumer/receipt_saver"
        private const val SAVE_PDF_METHOD = "savePdf"

        private const val IMAGE_CHANNEL_NAME = "vsf_consumer/qr_image_saver"
        private const val SAVE_IMAGE_METHOD = "saveImage"

        private const val PERMISSION_REQUEST_CODE = 4711
    }

    /** Which pending legacy save ("savePdf" or "saveImage") awaits permission. */
    private var pendingMethod: String? = null
    private var pendingBytes: ByteArray? = null
    private var pendingFileName: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Receipt PDF saver -> public Downloads.
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

        // Separate channel for QR image downloads: image saving is
        // never mixed with the receipt-PDF saver above.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            IMAGE_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                SAVE_IMAGE_METHOD -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName")

                    if (bytes == null || fileName.isNullOrEmpty()) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "bytes and fileName are required.",
                            null,
                        )
                    } else {
                        saveImage(bytes, fileName, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // ============================================================
    // PDF (RECEIPT) -> DOWNLOADS
    // ============================================================

    private fun savePdf(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                result.success(saveViaMediaStoreDownloads(fileName, bytes))
            } catch (e: Exception) {
                result.error(
                    "SAVE_FAILED",
                    e.message ?: "Unable to save PDF to Downloads.",
                    null,
                )
            }
            return
        }

        if (hasStoragePermission()) {
            saveViaLegacyDownloads(bytes, fileName, result)
            return
        }

        stashAndRequest(SAVE_PDF_METHOD, bytes, fileName, result)
    }

    // ============================================================
    // QR IMAGE -> PICTURES/VSF
    // ============================================================

    private fun saveImage(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                result.success(saveViaMediaStoreImages(fileName, bytes))
            } catch (e: Exception) {
                result.error(
                    "SAVE_FAILED",
                    e.message ?: "Unable to save QR image to Pictures.",
                    null,
                )
            }
            return
        }

        if (hasStoragePermission()) {
            saveViaLegacyPictures(bytes, fileName, result)
            return
        }

        stashAndRequest(SAVE_IMAGE_METHOD, bytes, fileName, result)
    }

    private fun hasStoragePermission(): Boolean =
        ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
        ) == PackageManager.PERMISSION_GRANTED

    private fun stashAndRequest(
        method: String,
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        pendingMethod = method
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
    // MODERN: MEDIASTORE.DOWNLOADS (PDF, API 29+)
    // ------------------------------------------------------------

    private fun saveViaMediaStoreDownloads(
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
        ) ?: throw IllegalStateException("Could not create the Downloads entry.")

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
            runCatching { resolver.delete(uri, null, null) }
            throw e
        }

        // MediaStore de-duplicates display names automatically,
        // so the visible file is exactly Downloads/<fileName>.
        return "Downloads/$fileName"
    }

    // ------------------------------------------------------------
    // MODERN: MEDIASTORE.IMAGES (QR, API 29+)
    // ------------------------------------------------------------

    private fun saveViaMediaStoreImages(
        fileName: String,
        bytes: ByteArray,
    ): String {
        val resolver = contentResolver

        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.IS_PENDING, 1)
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/VSF",
            )
        }

        val uri = resolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: throw IllegalStateException("Could not create the Pictures entry.")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IllegalStateException(
                "Could not open the Pictures output stream.",
            )

            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            runCatching { resolver.delete(uri, null, null) }
            throw e
        }

        return "Pictures/VSF/$fileName"
    }

    // ------------------------------------------------------------
    // LEGACY (API <= 28): DIRECT PUBLIC DOWNLOADS WRITE
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
    // LEGACY (API <= 28): DIRECT PUBLIC PICTURES WRITE
    // ------------------------------------------------------------

    private fun saveViaLegacyPictures(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        try {
            val picturesBase = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES,
            )

            val vsfDir = File(picturesBase, "VSF")
            if (!vsfDir.exists()) {
                vsfDir.mkdirs()
            }

            var target = File(vsfDir, fileName)
            var counter = 1
            while (target.exists()) {
                val dotIndex = fileName.lastIndexOf('.')
                val base = if (dotIndex > 0) fileName.substring(0, dotIndex) else fileName
                val extension = if (dotIndex > 0) fileName.substring(dotIndex) else ""
                target = File(vsfDir, "$base ($counter)$extension")
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
                e.message ?: "Unable to save QR image to Pictures.",
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

        val method = pendingMethod
        val result = pendingResult
        val bytes = pendingBytes
        val fileName = pendingFileName

        pendingMethod = null
        pendingResult = null
        pendingBytes = null
        pendingFileName = null

        if (result == null || bytes == null || fileName == null) {
            return
        }

        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            if (method == SAVE_IMAGE_METHOD) {
                saveViaLegacyPictures(bytes, fileName, result)
            } else {
                saveViaLegacyDownloads(bytes, fileName, result)
            }
        } else {
            result.error(
                "PERMISSION_DENIED",
                "Storage permission was denied.",
                null,
            )
        }
    }
}
