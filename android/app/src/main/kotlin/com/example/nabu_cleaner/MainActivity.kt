package com.example.nabu_cleaner

import android.graphics.Bitmap
import android.content.Intent
import android.media.ThumbnailUtils
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import android.provider.MediaStore.MediaColumns
import android.util.Size
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

class MainActivity : FlutterActivity() {
    companion object {
        private const val STORAGE_CHANNEL = "nabu_cleaner/storage"
        private const val METHOD_GET_STORAGE_OVERVIEW = "getStorageOverview"
        private const val MEDIA_CHANNEL = "nabu_cleaner/media"
        private const val METHOD_GET_VIDEO_THUMBNAIL = "getVideoThumbnail"
        private const val DELETE_CHANNEL = "nabu_cleaner/delete"
        private const val METHOD_DELETE_FILES = "deleteFiles"
        private const val REQUEST_DELETE_FILES = 9451
    }

    private var pendingDeleteResult: MethodChannel.Result? = null
    private var pendingDeleteRequestedPaths: List<String> = emptyList()
    private var pendingDirectDeletedPaths: List<String> = emptyList()
    private var pendingDirectSkippedPaths: List<String> = emptyList()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_STORAGE_OVERVIEW -> {
                    try {
                        val stat = StatFs(Environment.getDataDirectory().absolutePath)
                        val totalBytes = stat.totalBytes
                        val availableBytes = stat.availableBytes
                        val usedBytes = totalBytes - availableBytes

                        result.success(
                            mapOf(
                                "totalBytes" to totalBytes,
                                "availableBytes" to availableBytes,
                                "usedBytes" to usedBytes
                            )
                        )
                    } catch (e: Exception) {
                        result.error(
                            "STORAGE_READ_ERROR",
                            "Unable to read device storage overview.",
                            e.localizedMessage
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_VIDEO_THUMBNAIL -> {
                    val path = call.argument<String>("path")
                    val maxWidth = call.argument<Int>("maxWidth") ?: 140
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_PATH", "Video path is required.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val thumbnail = createVideoThumbnail(path, maxWidth)
                        if (thumbnail == null) {
                            result.success(null)
                            return@setMethodCallHandler
                        }

                        val stream = ByteArrayOutputStream()
                        thumbnail.compress(Bitmap.CompressFormat.JPEG, 70, stream)
                        val bytes = stream.toByteArray()
                        stream.close()
                        thumbnail.recycle()
                        result.success(bytes)
                    } catch (e: Exception) {
                        result.error(
                            "VIDEO_THUMB_ERROR",
                            "Unable to generate video thumbnail.",
                            e.localizedMessage
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DELETE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_DELETE_FILES -> {
                    val rawPaths = call.argument<List<String>>("paths") ?: emptyList()
                    if (rawPaths.isEmpty()) {
                        result.success(
                            mapOf(
                                "deletedPaths" to emptyList<String>(),
                                "skippedPaths" to emptyList<String>()
                            )
                        )
                        return@setMethodCallHandler
                    }

                    if (pendingDeleteResult != null) {
                        result.error(
                            "DELETE_IN_PROGRESS",
                            "Another delete request is currently running.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val urisByPath = rawPaths.associateWith { mediaUriForPath(it) }
                    val mediaPaths = urisByPath
                        .filterValues { it != null }
                        .keys
                        .toList()
                    val deleteUris = urisByPath.values.filterNotNull().distinct()
                    val directPaths = rawPaths.filter { path -> !mediaPaths.contains(path) }
                    val direct = tryDirectFileDelete(directPaths)

                    if (deleteUris.isEmpty()) {
                        result.success(
                            mapOf(
                                "deletedPaths" to direct.first,
                                "skippedPaths" to direct.second
                            )
                        )
                        return@setMethodCallHandler
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            pendingDeleteResult = result
                            pendingDeleteRequestedPaths = mediaPaths
                            pendingDirectDeletedPaths = direct.first
                            pendingDirectSkippedPaths = direct.second
                            val intentSender = MediaStore.createDeleteRequest(
                                contentResolver,
                                deleteUris
                            ).intentSender
                            startIntentSenderForResult(
                                intentSender,
                                REQUEST_DELETE_FILES,
                                null,
                                0,
                                0,
                                0
                            )
                        } catch (e: Exception) {
                            pendingDeleteResult = null
                            pendingDeleteRequestedPaths = emptyList()
                            pendingDirectDeletedPaths = emptyList()
                            pendingDirectSkippedPaths = emptyList()
                            val fallbackTargets = mediaPaths + directPaths
                            val fallback = tryDirectFileDelete(fallbackTargets)
                            result.success(
                                mapOf(
                                    "deletedPaths" to fallback.first,
                                    "skippedPaths" to fallback.second
                                )
                            )
                        }
                        return@setMethodCallHandler
                    }

                    // Android < 11: best effort direct delete.
                    val oldAndroidTargets = mediaPaths + directPaths
                    val directLegacy = tryDirectFileDelete(oldAndroidTargets)
                    result.success(
                        mapOf(
                            "deletedPaths" to directLegacy.first,
                            "skippedPaths" to directLegacy.second
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != REQUEST_DELETE_FILES) {
            return
        }

        val result = pendingDeleteResult ?: return
        val requested = pendingDeleteRequestedPaths
        val directDeleted = pendingDirectDeletedPaths
        val directSkipped = pendingDirectSkippedPaths
        pendingDeleteResult = null
        pendingDeleteRequestedPaths = emptyList()
        pendingDirectDeletedPaths = emptyList()
        pendingDirectSkippedPaths = emptyList()

        if (resultCode == RESULT_OK) {
            val deleted = directDeleted + requested
            val skipped = directSkipped
            result.success(
                mapOf(
                    "deletedPaths" to deleted,
                    "skippedPaths" to skipped
                )
            )
        } else {
            result.success(
                mapOf(
                    "deletedPaths" to directDeleted,
                    "skippedPaths" to (directSkipped + requested)
                )
            )
        }
    }

    private fun createVideoThumbnail(path: String, maxWidth: Int): Bitmap? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ThumbnailUtils.createVideoThumbnail(
                File(path),
                Size(maxWidth, maxWidth),
                null
            )
        } else {
            ThumbnailUtils.createVideoThumbnail(
                path,
                MediaStore.Video.Thumbnails.MINI_KIND
            )
        }
    }

    private fun mediaUriForPath(path: String): Uri? {
        val file = File(path)
        val fileName = file.name
        val fileSize = if (file.exists()) file.length() else -1L
        val relativePath = extractRelativePath(path)

        // 1) Try broad files collection with modern columns.
        queryByDisplayName(
            collection = MediaStore.Files.getContentUri("external"),
            fileName = fileName,
            fileSize = fileSize,
            relativePath = relativePath
        )?.let { return it }

        // 2) Try dedicated images collection.
        queryByDisplayName(
            collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            fileName = fileName,
            fileSize = fileSize,
            relativePath = relativePath
        )?.let { return it }

        // 3) Try dedicated videos collection.
        queryByDisplayName(
            collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            fileName = fileName,
            fileSize = fileSize,
            relativePath = relativePath
        )?.let { return it }

        // 4) Legacy direct path query (older devices / indexed entries).
        queryByLegacyDataColumn(path)?.let { return it }

        // 5) Force media scan and retrieve generated URI.
        return scanFileAndGetUri(path)
    }

    private fun queryByDisplayName(
        collection: Uri,
        fileName: String,
        fileSize: Long,
        relativePath: String?
    ): Uri? {
        return try {
            val projection = arrayOf(MediaColumns._ID)
            val selectionBuilder = StringBuilder("${MediaColumns.DISPLAY_NAME}=?")
            val args = mutableListOf(fileName)

            if (fileSize >= 0L) {
                selectionBuilder.append(" AND ${MediaColumns.SIZE}=?")
                args.add(fileSize.toString())
            }
            if (relativePath != null) {
                selectionBuilder.append(" AND ${MediaColumns.RELATIVE_PATH}=?")
                args.add(relativePath)
            }

            contentResolver.query(
                collection,
                projection,
                selectionBuilder.toString(),
                args.toTypedArray(),
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return null
                }
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaColumns._ID))
                Uri.withAppendedPath(collection, id.toString())
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun queryByLegacyDataColumn(path: String): Uri? {
        return try {
            val projection = arrayOf(MediaStore.Files.FileColumns._ID)
            val selection = "${MediaStore.Files.FileColumns.DATA}=?"
            val selectionArgs = arrayOf(path)
            contentResolver.query(
                MediaStore.Files.getContentUri("external"),
                projection,
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val id = cursor.getLong(
                        cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                    )
                    return Uri.withAppendedPath(
                        MediaStore.Files.getContentUri("external"),
                        id.toString()
                    )
                }
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun scanFileAndGetUri(path: String): Uri? {
        return try {
            val latch = CountDownLatch(1)
            val holder = AtomicReference<Uri?>(null)
            MediaScannerConnection.scanFile(
                this,
                arrayOf(path),
                null
            ) { _, uri ->
                holder.set(uri)
                latch.countDown()
            }
            latch.await(2, TimeUnit.SECONDS)
            holder.get()
        } catch (_: Exception) {
            null
        }
    }

    private fun extractRelativePath(path: String): String? {
        val normalized = path.replace("\\", "/")
        val root = "/storage/emulated/0/"
        if (!normalized.startsWith(root)) {
            return null
        }

        val relative = normalized.removePrefix(root)
        val lastSlash = relative.lastIndexOf('/')
        if (lastSlash <= 0) {
            return null
        }

        return relative.substring(0, lastSlash + 1)
    }

    private fun tryDirectFileDelete(paths: List<String>): Pair<List<String>, List<String>> {
        val deleted = mutableListOf<String>()
        val skipped = mutableListOf<String>()

        for (path in paths) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    deleted.add(path)
                    continue
                }
                if (file.delete()) {
                    deleted.add(path)
                } else {
                    skipped.add(path)
                }
            } catch (_: Exception) {
                skipped.add(path)
            }
        }
        return Pair(deleted, skipped)
    }
}
