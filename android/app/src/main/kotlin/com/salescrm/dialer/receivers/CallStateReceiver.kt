package com.salescrm.dialer.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.CallLog
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.salescrm.dialer.plugins.CallPlugin

class CallStateReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallStateReceiver"
        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var isIncoming = false
        private var savedNumber: String? = null
        private var offhookTime: Long = 0
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_NEW_OUTGOING_CALL) {
            savedNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
            isIncoming = false
            Log.d(TAG, "Outgoing call dialed to: $savedNumber")
            CallPlugin.sendEvent("CALL_DIALING", savedNumber)
            return
        }

        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            
            var state = TelephonyManager.CALL_STATE_IDLE
            when (stateStr) {
                TelephonyManager.EXTRA_STATE_IDLE -> state = TelephonyManager.CALL_STATE_IDLE
                TelephonyManager.EXTRA_STATE_OFFHOOK -> state = TelephonyManager.CALL_STATE_OFFHOOK
                TelephonyManager.EXTRA_STATE_RINGING -> state = TelephonyManager.CALL_STATE_RINGING
            }

            onCallStateChanged(context, state, number ?: savedNumber ?: CallPlugin.lastDialedNumber)
        }
    }

    private fun onCallStateChanged(context: Context, state: Int, number: String?) {
        if (lastState == state) {
            return
        }

        val targetNum = number ?: CallPlugin.lastDialedNumber

        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                isIncoming = true
                savedNumber = targetNum
                Log.d(TAG, "Incoming call ringing from: $savedNumber")
                CallPlugin.sendEvent("CALL_RINGING", savedNumber)
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                offhookTime = System.currentTimeMillis()
                val activeNum = targetNum ?: "Unknown"
                com.salescrm.dialer.services.CallAudioRecorder.startRecording(context, activeNum)
                if (lastState != TelephonyManager.CALL_STATE_RINGING) {
                    isIncoming = false
                    Log.d(TAG, "Outgoing call started: $targetNum")
                    CallPlugin.sendEvent("CALL_STARTED", targetNum)
                } else {
                    isIncoming = true
                    Log.d(TAG, "Incoming call answered: $targetNum")
                    CallPlugin.sendEvent("CALL_CONNECTED", targetNum)
                }
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                var durationSeconds: Long = 0
                val now = System.currentTimeMillis()
                if (offhookTime > 0) {
                    durationSeconds = (now - offhookTime) / 1000
                    offhookTime = 0
                } else if (CallPlugin.lastCallStartTime > 0) {
                    durationSeconds = (now - CallPlugin.lastCallStartTime) / 1000
                }

                // Stop audio recorder and get recorded file path
                val recordingPath = com.salescrm.dialer.services.CallAudioRecorder.stopRecording()

                // Check CallLog for exact carrier duration if available
                val callLogDuration = getLatestCallDuration(context, targetNum)
                if (callLogDuration > 0) {
                    durationSeconds = callLogDuration
                }

                if (lastState == TelephonyManager.CALL_STATE_RINGING) {
                    Log.d(TAG, "Call missed/rejected: $targetNum")
                    if (isIncoming) {
                        CallPlugin.sendEvent("CALL_MISSED", targetNum)
                    } else {
                        CallPlugin.sendEvent("CALL_REJECTED", targetNum)
                    }
                } else {
                    Log.d(TAG, "Call ended: $targetNum, Duration: ${durationSeconds}s, Audio: $recordingPath")
                    CallPlugin.sendEvent("CALL_ENDED", targetNum, durationSeconds, recordingPath)
                }

                // Bring MainActivity back to foreground so the agent sees the CRM disposition sheet
                try {
                    val bringToFront = Intent(context, com.salescrm.dialer.MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    context.startActivity(bringToFront)
                } catch (e: Exception) {
                    Log.w(TAG, "Could not bring MainActivity to foreground: ${e.message}")
                }
            }
        }
        lastState = state
    }

    private fun getLatestCallDuration(context: Context, targetNumber: String?): Long {
        try {
            if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                return 0
            }
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.DURATION),
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
                        val dur = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                        if (dur > 0) return dur
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching call duration from log: ${e.message}")
        }
        return 0
    }
}
