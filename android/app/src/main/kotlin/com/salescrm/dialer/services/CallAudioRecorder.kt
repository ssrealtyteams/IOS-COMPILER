package com.salescrm.dialer.services

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object CallAudioRecorder {
    private const val TAG = "CallAudioRecorder"

    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var currentRecordingFile: File? = null

    fun startRecording(context: Context, phoneNumber: String): String? {
        if (isRecording && currentRecordingFile != null) {
            val file = currentRecordingFile!!
            if (file.exists() && System.currentTimeMillis() - file.lastModified() < 20000) {
                Log.i(TAG, "Reusing active voice recording for call: ${file.absolutePath}")
                return file.absolutePath
            }
            Log.w(TAG, "Stopping previous stale recording session")
            stopRecording()
        }

        try {
            val baseDir = context.getExternalFilesDir(null) ?: context.filesDir
            val dir = File(baseDir, "call_recordings").apply {
                if (!exists()) mkdirs()
            }

            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val sanitizedNumber = phoneNumber.replace(Regex("[^0-9+]"), "")
            val file = File(dir, "CALL_${sanitizedNumber}_${timestamp}.m4a")
            file.setReadable(true, false)
            currentRecordingFile = file

            val audioSources = listOf(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                MediaRecorder.AudioSource.MIC,
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                MediaRecorder.AudioSource.DEFAULT
            )

            var recorder: MediaRecorder? = null
            var started = false

            for (source in audioSources) {
                try {
                    val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        MediaRecorder(context)
                    } else {
                        @Suppress("DEPRECATION")
                        MediaRecorder()
                    }
                    r.setAudioSource(source)
                    r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                    r.setAudioEncodingBitRate(128000)
                    r.setAudioSamplingRate(44100)
                    r.setAudioChannels(1)
                    r.setOutputFile(file.absolutePath)
                    r.prepare()
                    r.start()
                    recorder = r
                    started = true
                    Log.i(TAG, "Voice recording successfully started using AudioSource $source at: ${file.absolutePath}")
                    break
                } catch (e: Exception) {
                    Log.w(TAG, "AudioSource $source failed to initialize: ${e.message}")
                    try { recorder?.release() } catch (_: Exception) {}
                    recorder = null
                }
            }

            if (!started || recorder == null) {
                Log.e(TAG, "All audio sources failed to start voice recording")
                cleanup()
                return null
            }

            mediaRecorder = recorder
            isRecording = true
            return file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Fatal error starting voice recorder: ${e.message}", e)
            cleanup()
            return null
        }
    }

    fun stopRecording(): String? {
        if (!isRecording || mediaRecorder == null) {
            Log.d(TAG, "No active recording to stop")
            return currentRecordingFile?.takeIf { it.exists() && it.length() > 0 }?.absolutePath
        }

        val filePath = currentRecordingFile?.absolutePath
        try {
            mediaRecorder?.apply {
                try {
                    stop()
                } catch (e: Exception) {
                    Log.w(TAG, "Error during mediaRecorder.stop(): ${e.message}")
                }
                reset()
                release()
            }
            Log.i(TAG, "Voice recording stopped successfully: $filePath (Size: ${currentRecordingFile?.length()} bytes)")
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaRecorder: ${e.message}", e)
        } finally {
            cleanup()
        }

        // Return path only if file exists and has data
        val file = currentRecordingFile ?: (if (filePath != null) File(filePath) else null)
        return if (file != null && file.exists() && file.length() > 0) {
            file.setReadable(true, false)
            file.absolutePath
        } else {
            null
        }
    }

    fun isRecordingActive(): Boolean = isRecording

    fun getCurrentRecordingPath(): String? = currentRecordingFile?.absolutePath

    private fun cleanup() {
        mediaRecorder = null
        isRecording = false
    }
}
