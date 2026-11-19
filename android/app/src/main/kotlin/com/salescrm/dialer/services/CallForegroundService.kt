package com.salescrm.dialer.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.salescrm.dialer.MainActivity
import com.salescrm.dialer.receivers.CallStateReceiver
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class CallForegroundService : Service() {

    private val TAG = "CallForegroundService"
    private val CHANNEL_ID = "CallMonitorServiceChannel"
    private val NEW_LEADS_CHANNEL_ID = "new_leads_channel_v1"
    private val NOTIFICATION_ID = 1

    private var callStateReceiver: CallStateReceiver? = null
    private var receiverRegistered = false
    private var isServiceRunning = false
    private var leadSyncThread: Thread? = null

    override fun onCreate() {
        super.onCreate()
        try {
            createNotificationChannels()

            // Register receiver for phone state changes
            callStateReceiver = CallStateReceiver()
            val filter = IntentFilter().apply {
                addAction(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
                addAction(Intent.ACTION_NEW_OUTGOING_CALL)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(callStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(callStateReceiver, filter)
            }
            receiverRegistered = true
            isServiceRunning = true

        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("SS Realty CRM")
                .setContentText("Real-time lead & call tracking active")
                .setSmallIcon(android.R.drawable.ic_menu_call)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setOngoing(true)
                .build()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                var fgsType = android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    fgsType = fgsType or android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                }
                try {
                    fgsType = fgsType or android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                    startForeground(NOTIFICATION_ID, notification, fgsType)
                } catch (e: Exception) {
                    Log.w(TAG, "Fallback to dataSync startForeground on Android 14: ${e.message}")
                    try {
                        startForeground(NOTIFICATION_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
                    } catch (e2: Exception) {
                        Log.e(TAG, "Fatal startForeground error: ${e2.message}")
                    }
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "Fallback to basic startForeground: ${e.message}")
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground: ${e.message}")
        }

        return START_STICKY
    }

    private fun startLeadSyncLoop() {
        // Disabled: Lead sync is handled with real-time timers and reactive updates by Dart's NewLeadSyncService
    }

    private fun checkNewLeadsFromApi() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val token = prefs.getString("flutter.auth_access_token", null)
        if (token.isNullOrEmpty()) {
            return
        }

        val knownJson = prefs.getString("flutter.known_lead_ids", null)
        val knownSet = mutableSetOf<String>()
        if (!knownJson.isNullOrEmpty()) {
            try {
                val array = JSONArray(knownJson)
                for (i in 0 until array.length()) {
                    knownSet.add(array.getString(i))
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error parsing known leads: ${e.message}")
            }
        }

        val url = URL("https://ssrealty.org/api/mobile/leads")
        val conn = url.openConnection() as HttpURLConnection
        try {
            conn.requestMethod = "GET"
            conn.setRequestProperty("Authorization", "Bearer $token")
            conn.setRequestProperty("Accept", "application/json")
            conn.connectTimeout = 8000
            conn.readTimeout = 10000

            if (conn.responseCode == 200) {
                val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                val leadsArray = when {
                    responseText.trim().startsWith("[") -> JSONArray(responseText)
                    responseText.trim().startsWith("{") -> {
                        val obj = JSONObject(responseText)
                        when {
                            obj.has("leads") -> obj.getJSONArray("leads")
                            obj.has("items") -> obj.getJSONArray("items")
                            else -> null
                        }
                    }
                    else -> null
                }

                if (leadsArray != null) {
                    val newLeads = mutableListOf<JSONObject>()
                    val isFirstRun = knownSet.isEmpty()

                    for (i in 0 until leadsArray.length()) {
                        val lead = leadsArray.getJSONObject(i)
                        val id = lead.optString("id")
                        if (id.isNotEmpty()) {
                            if (!knownSet.contains(id)) {
                                if (!isFirstRun) {
                                    newLeads.add(lead)
                                }
                                knownSet.add(id)
                            }
                        }
                    }

                    // Save updated knownSet to FlutterSharedPreferences
                    val newArray = JSONArray(knownSet)
                    prefs.edit().putString("flutter.known_lead_ids", newArray.toString()).apply()

                    // Trigger notifications for new leads
                    for (newLead in newLeads) {
                        showNativeNewLeadNotification(newLead)
                    }
                }
            }
        } finally {
            conn.disconnect()
        }
    }

    private fun showNativeNewLeadNotification(lead: JSONObject) {
        try {
            val leadId = lead.optString("id")
            val fullName = lead.optString("fullName", "New Lead")
            val phone = lead.optString("phone", lead.optString("phoneNumber", ""))
            val projectName = lead.optString("projectName", "New Customer Lead")

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Intent to open App
            val openIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("lead_id", leadId)
                putExtra("route", "/leads/new")
            }
            val openPendingIntent = PendingIntent.getActivity(
                this,
                (leadId.hashCode() and 0x7FFFFFFF),
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Direct Call Intent
            val callIntent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$phone")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val callPendingIntent = PendingIntent.getActivity(
                this,
                (leadId.hashCode() and 0x7FFFFFFF) + 1,
                callIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Direct WhatsApp Intent
            val cleanPhone = phone.replace(Regex("[^0-9]"), "")
            val targetPhone = if (cleanPhone.length == 10) "91$cleanPhone" else cleanPhone
            val waIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$targetPhone")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val waPendingIntent = PendingIntent.getActivity(
                this,
                (leadId.hashCode() and 0x7FFFFFFF) + 2,
                waIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, NEW_LEADS_CHANNEL_ID)
                .setContentTitle("🔥 New Lead Assigned: $fullName")
                .setContentText("📞 $phone • $projectName — Tap to view")
                .setSmallIcon(android.R.drawable.stat_notify_chat)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setContentIntent(openPendingIntent)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setVibrate(longArrayOf(0, 500, 200, 500, 200, 500))
                .addAction(android.R.drawable.ic_menu_call, "📞 Call Now", callPendingIntent)
                .addAction(android.R.drawable.ic_dialog_email, "💬 WhatsApp", waPendingIntent)
                .addAction(android.R.drawable.ic_menu_view, "📋 View Lead", openPendingIntent)
                .build()

            val notifId = (leadId.hashCode() and 0x7FFFFFFF)
            notificationManager.notify(notifId, notification)
            Log.i(TAG, "🔥 Native notification shown for new lead: $fullName ($phone)")

        } catch (e: Exception) {
            Log.e(TAG, "Error showing native new lead notification: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        leadSyncThread?.interrupt()
        leadSyncThread = null

        if (receiverRegistered && callStateReceiver != null) {
            try {
                unregisterReceiver(callStateReceiver)
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering receiver: ${e.message}")
            }
        }
    }

    override fun onBind(intent: Intent): IBinder? = null

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Call Monitoring",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                setShowBadge(false)
            }

            val newLeadsChannel = NotificationChannel(
                NEW_LEADS_CHANNEL_ID,
                "New Assigned Leads",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Instant notifications when a new customer lead is assigned"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
                enableLights(true)
                setShowBadge(true)
            }

            manager?.createNotificationChannel(serviceChannel)
            manager?.createNotificationChannel(newLeadsChannel)
        }
    }
}
