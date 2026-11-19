package com.salescrm.dialer.plugins

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CallLog
import android.telephony.TelephonyManager
import android.telecom.TelecomManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.salescrm.dialer.services.CallForegroundService
import com.salescrm.dialer.services.CrmInCallService

class CallPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methodChannelId = "com.salescrm.dialer/call"
    private val eventChannelId = "com.salescrm.dialer/call_events"
    
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private const val TAG = "CallPlugin"
        private const val REQUEST_CODE_SET_DEFAULT_DIALER = 202
        private var instance: CallPlugin? = null
        var lastDialedNumber: String? = null
        var lastCallStartTime: Long = 0
        private var pendingDefaultDialerResult: MethodChannel.Result? = null

        fun register(flutterEngine: FlutterEngine, activity: Activity) {
            instance = CallPlugin(activity)
            
            val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, instance!!.methodChannelId)
            methodChannel.setMethodCallHandler(instance)

            val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, instance!!.eventChannelId)
            eventChannel.setStreamHandler(instance)
        }

        fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
            if (requestCode == REQUEST_CODE_SET_DEFAULT_DIALER) {
                val isDefault = instance?.isDefaultDialer() ?: false
                Log.i(TAG, "Default dialer dialog result: isDefault = $isDefault")
                try {
                    pendingDefaultDialerResult?.success(isDefault)
                } catch (e: Exception) {
                    Log.w(TAG, "Result already sent: ${e.message}")
                }
                pendingDefaultDialerResult = null
                return true
            }
            return false
        }

        fun sendEvent(eventType: String, phoneNumber: String? = null, durationSeconds: Long? = null, audioPath: String? = null) {
            val plugin = instance
            if (plugin != null) {
                val event = mutableMapOf<String, Any?>()
                event["eventType"] = eventType
                event["phoneNumber"] = phoneNumber ?: lastDialedNumber
                event["duration"] = durationSeconds
                event["audioPath"] = audioPath
                event["timestamp"] = System.currentTimeMillis()
                
                try {
                    plugin.activity.runOnUiThread {
                        plugin.eventSink?.success(event)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending event to Flutter: ${e.message}")
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initiateCall" -> {
                val phoneNumber = call.argument<String>("phoneNumber")
                if (phoneNumber.isNullOrEmpty()) {
                    result.error("INVALID_NUMBER", "Phone number cannot be empty", null)
                    return
                }
                initiateCall(phoneNumber, result)
            }
            "endCall" -> {
                endCall(result)
            }
            "answerCall" -> {
                var answered = com.salescrm.dialer.services.CrmInCallService.answer()
                if (!answered && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    if (telecomManager != null && ContextCompat.checkSelfPermission(activity, android.Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
                        try {
                            telecomManager.acceptRingingCall()
                            answered = true
                        } catch (e: Exception) {
                            Log.e(TAG, "Error acceptRingingCall: ${e.message}")
                        }
                    }
                }
                result.success(answered)
            }
            "rejectCall" -> {
                var rejected = com.salescrm.dialer.services.CrmInCallService.reject()
                if (!rejected && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    if (telecomManager != null && ContextCompat.checkSelfPermission(activity, android.Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
                        try {
                            telecomManager.endCall()
                            rejected = true
                        } catch (e: Exception) {
                            Log.e(TAG, "Error endCall: ${e.message}")
                        }
                    }
                }
                result.success(rejected)
            }
            "checkPermissions" -> {
                result.success(checkPermissions())
            }
            "isDefaultDialer" -> {
                result.success(isDefaultDialer())
            }
            "requestDefaultDialer" -> {
                requestDefaultDialer(result)
            }
            "sendDtmf" -> {
                val digitStr = call.argument<String>("digit") ?: ""
                if (digitStr.isNotEmpty()) {
                    val success = CrmInCallService.playDtmf(digitStr[0])
                    result.success(success)
                } else {
                    result.success(false)
                }
            }
            "getLastCallLog" -> {
                val phone = call.argument<String>("phoneNumber") ?: lastDialedNumber
                result.success(getLastCallDetails(activity, phone))
            }
            "startCallMonitoring" -> {
                startCallMonitoring(result)
            }
            "stopCallMonitoring" -> {
                stopCallMonitoring(result)
            }
            "startVoiceRecording" -> {
                val phone = call.argument<String>("phoneNumber") ?: lastDialedNumber ?: "Manual"
                val path = com.salescrm.dialer.services.CallAudioRecorder.startRecording(activity, phone)
                result.success(path)
            }
            "stopVoiceRecording" -> {
                val path = com.salescrm.dialer.services.CallAudioRecorder.stopRecording()
                result.success(path)
            }
            "getRecordingPath" -> {
                result.success(com.salescrm.dialer.services.CallAudioRecorder.getCurrentRecordingPath())
            }
            "getSimInfo" -> {
                getSimInfo(result)
            }
            "setSpeakerphoneOn" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setSpeakerphoneOn(enabled, result)
            }
            "setMicrophoneMute" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setMicrophoneMute(enabled, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun isDefaultDialer(): Boolean {
        return try {
            val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                telecomManager?.defaultDialerPackage == activity.packageName
            } else {
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun requestDefaultDialer(result: MethodChannel.Result) {
        try {
            if (isDefaultDialer()) {
                result.success(true)
                return
            }
            pendingDefaultDialerResult = result

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = activity.getSystemService(RoleManager::class.java)
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_DIALER)) {
                    if (roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                        pendingDefaultDialerResult = null
                        result.success(true)
                        return
                    }
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                    activity.startActivityForResult(intent, REQUEST_CODE_SET_DEFAULT_DIALER)
                    return
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                    putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, activity.packageName)
                }
                activity.startActivityForResult(intent, REQUEST_CODE_SET_DEFAULT_DIALER)
            } else {
                pendingDefaultDialerResult = null
                result.success(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting default dialer: ${e.message}")
            pendingDefaultDialerResult = null
            result.error("DEFAULT_DIALER_ERROR", e.message, null)
        }
    }

    private fun setSpeakerphoneOn(enabled: Boolean, result: MethodChannel.Result) {
        try {
            CrmInCallService.setSpeaker(enabled)
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager != null) {
                audioManager.mode = AudioManager.MODE_IN_CALL
                audioManager.isSpeakerphoneOn = enabled
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting speakerphone: ${e.message}")
            result.success(false)
        }
    }

    private fun setMicrophoneMute(enabled: Boolean, result: MethodChannel.Result) {
        try {
            CrmInCallService.setMuted(enabled)
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager != null) {
                audioManager.isMicrophoneMute = enabled
            }
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting microphone mute: ${e.message}")
            result.success(false)
        }
    }

    private fun endCall(result: MethodChannel.Result) {
        try {
            var hungUp = CrmInCallService.hangUp()
            if (!hungUp && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                if (telecomManager != null && ContextCompat.checkSelfPermission(activity, android.Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
                    hungUp = telecomManager.endCall()
                    Log.d(TAG, "telecomManager.endCall() returned: $hungUp")
                }
            }
            com.salescrm.dialer.services.CallAudioRecorder.stopRecording()
            result.success(hungUp)
        } catch (e: Exception) {
            Log.e(TAG, "Error ending call: ${e.message}")
            result.success(false)
        }
    }

    private fun checkPermissions(): Boolean {
        val permissions = arrayOf(
            android.Manifest.permission.CALL_PHONE,
            android.Manifest.permission.READ_PHONE_STATE,
            android.Manifest.permission.READ_CALL_LOG,
            android.Manifest.permission.RECORD_AUDIO,
            android.Manifest.permission.ANSWER_PHONE_CALLS
        )
        return permissions.all {
            ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun initiateCall(phoneNumber: String, result: MethodChannel.Result) {
        lastDialedNumber = phoneNumber
        lastCallStartTime = System.currentTimeMillis()

        if (!checkPermissions()) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(
                    android.Manifest.permission.CALL_PHONE,
                    android.Manifest.permission.READ_PHONE_STATE,
                    android.Manifest.permission.READ_CALL_LOG,
                    android.Manifest.permission.RECORD_AUDIO
                ),
                101
            )
        }

        try {
            val serviceIntent = Intent(activity, CallForegroundService::class.java).apply {
                putExtra("phoneNumber", phoneNumber)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                activity.startForegroundService(serviceIntent)
            } else {
                activity.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Foreground service start: ${e.message}")
        }

        try {
            val path = com.salescrm.dialer.services.CallAudioRecorder.startRecording(activity, phoneNumber)
            Log.i(TAG, "Pre-started recording: $path")
        } catch (e: Exception) {
            Log.w(TAG, "Recording pre-start error: ${e.message}")
        }

        try {
            val uri = Uri.parse("tel:$phoneNumber")
            val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                telecomManager != null &&
                ContextCompat.checkSelfPermission(activity, android.Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
                val extras = Bundle().apply {
                    putBoolean(TelecomManager.EXTRA_START_CALL_WITH_SPEAKERPHONE, false)
                }
                telecomManager.placeCall(uri, extras)
                Log.i(TAG, "Placed call via TelecomManager.placeCall: $phoneNumber")
            } else {
                val intent = Intent(Intent.ACTION_CALL).apply {
                    data = uri
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                activity.startActivity(intent)
                Log.i(TAG, "Placed call via Intent.ACTION_CALL: $phoneNumber")
            }

            activity.window.decorView.postDelayed({
                try {
                    val bringToFrontIntent = Intent(activity, activity.javaClass).apply {
                        flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    activity.startActivity(bringToFrontIntent)
                } catch (e: Exception) {
                    Log.w(TAG, "Reorder to front error: ${e.message}")
                }
            }, 300)

            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start call intent: ${e.message}")
            result.error("CALL_FAILED", e.message, null)
        }
    }

    private fun getLastCallDetails(context: Context, targetNumber: String?): Map<String, Any?> {
        val callInfo = mutableMapOf<String, Any?>()
        try {
            if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                return callInfo
            }
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.DATE,
                    CallLog.Calls.TYPE
                ),
                null,
                null,
                "${CallLog.Calls.DATE} DESC LIMIT 5"
            )
            cursor?.use {
                while (it.moveToNext()) {
                    val num = it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER)) ?: ""
                    val cleanNum = num.replace(Regex("[^0-9]"), "")
                    val cleanTarget = targetNumber?.replace(Regex("[^0-9]"), "") ?: ""
                    val last10Target = if (cleanTarget.length >= 10) cleanTarget.substring(cleanTarget.length - 10) else cleanTarget

                    if (cleanTarget.isEmpty() || cleanNum.endsWith(last10Target) || last10Target.isEmpty()) {
                        val duration = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                        val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                        val type = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE))

                        callInfo["number"] = num
                        callInfo["durationSeconds"] = duration
                        callInfo["date"] = date
                        callInfo["type"] = type
                        break
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying CallLog: ${e.message}")
        }
        return callInfo
    }

    private fun startCallMonitoring(result: MethodChannel.Result) {
        try {
            val intent = Intent(activity, CallForegroundService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                activity.startForegroundService(intent)
            } else {
                activity.startService(intent)
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("SERVICE_START_FAILED", e.message, null)
        }
    }

    private fun stopCallMonitoring(result: MethodChannel.Result) {
        try {
            val intent = Intent(activity, CallForegroundService::class.java)
            activity.stopService(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", e.message, null)
        }
    }

    private fun getSimInfo(result: MethodChannel.Result) {
        try {
            val telephonyManager = activity.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val simState = telephonyManager.simState
            val networkOperatorName = telephonyManager.networkOperatorName
            
            val info = mapOf(
                "simState" to simState,
                "operator" to networkOperatorName,
                "isNetworkRoaming" to telephonyManager.isNetworkRoaming
            )
            result.success(info)
        } catch (e: Exception) {
            result.error("SIM_ERROR", e.message, null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}
