package com.salescrm.dialer.services

import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import android.util.Log
import com.salescrm.dialer.plugins.CallPlugin

class CrmInCallService : InCallService() {

    companion object {
        private const val TAG = "CrmInCallService"
        var activeCall: Call? = null
        var instance: CrmInCallService? = null

        fun answer(): Boolean {
            return try {
                val call = activeCall
                if (call != null) {
                    call.answer(android.telecom.VideoProfile.STATE_AUDIO_ONLY)
                    Log.i(TAG, "Call answered via InCallService")
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in answer: ${e.message}")
                false
            }
        }

        fun reject(): Boolean {
            return try {
                val call = activeCall
                if (call != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        call.reject(Call.REJECT_REASON_DECLINED)
                    } else {
                        @Suppress("DEPRECATION")
                        call.reject(false, null)
                    }
                    Log.i(TAG, "Call rejected via InCallService")
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in reject: ${e.message}")
                false
            }
        }

        fun hangUp(): Boolean {
            return try {
                val call = activeCall
                if (call != null) {
                    call.disconnect()
                    Log.i(TAG, "Call disconnected via InCallService")
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in hangUp: ${e.message}")
                false
            }
        }

        fun playDtmf(digit: Char): Boolean {
            return try {
                val call = activeCall
                if (call != null) {
                    call.playDtmfTone(digit)
                    call.stopDtmfTone()
                    Log.i(TAG, "DTMF played: $digit")
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error playing DTMF: ${e.message}")
                false
            }
        }

        fun setSpeaker(speakerOn: Boolean): Boolean {
            return try {
                val srv = instance
                if (srv != null) {
                    val route = if (speakerOn) CallAudioState.ROUTE_SPEAKER else CallAudioState.ROUTE_EARPIECE
                    srv.setAudioRoute(route)
                    Log.i(TAG, "Audio route set to: $route")
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error setting audio route: ${e.message}")
                false
            }
        }

        fun setMuted(muted: Boolean): Boolean {
            return try {
                val srv = instance
                if (srv != null) {
                    srv.setMuted(muted)
                    Log.i(TAG, "Mute set to: $muted")
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error setting muted: ${e.message}")
                false
            }
        }
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            Log.d(TAG, "InCallService call state changed: $state")
            val number = getPhoneNumber(call)
            when (state) {
                Call.STATE_DIALING, Call.STATE_CONNECTING -> {
                    CallPlugin.sendEvent("CALL_DIALING", number)
                }
                Call.STATE_RINGING -> {
                    CallPlugin.sendEvent("CALL_RINGING", number)
                }
                Call.STATE_ACTIVE -> {
                    CallPlugin.sendEvent("CALL_CONNECTED", number)
                }
                Call.STATE_DISCONNECTED -> {
                    CallPlugin.sendEvent("CALL_ENDED", number)
                    if (activeCall == call) {
                        activeCall = null
                    }
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.i(TAG, "CrmInCallService created")
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) {
            instance = null
        }
        Log.i(TAG, "CrmInCallService destroyed")
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        Log.i(TAG, "InCallService onCallAdded: $call")
        activeCall = call
        call.registerCallback(callCallback)

        val number = getPhoneNumber(call)
        if (call.state == Call.STATE_RINGING) {
            CallPlugin.sendEvent("CALL_RINGING", number)
        } else if (call.state == Call.STATE_ACTIVE) {
            CallPlugin.sendEvent("CALL_CONNECTED", number)
        } else {
            CallPlugin.sendEvent("CALL_DIALING", number)
        }

        // Bring our app's MainActivity to front so our InCallScreen is shown exclusively
        try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            if (intent != null) {
                startActivity(intent)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to launch main activity: ${e.message}")
        }
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        Log.i(TAG, "InCallService onCallRemoved: $call")
        call.unregisterCallback(callCallback)
        if (activeCall == call) {
            activeCall = null
        }
    }

    private fun getPhoneNumber(call: Call): String {
        return call.details?.handle?.schemeSpecificPart ?: CallPlugin.lastDialedNumber ?: ""
    }
}
