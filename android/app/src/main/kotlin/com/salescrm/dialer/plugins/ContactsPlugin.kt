package com.salescrm.dialer.plugins

import android.app.Activity
import android.content.ContentProviderOperation
import android.content.Context
import android.net.Uri
import android.provider.ContactsContract
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ContactsPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val channelId = "com.salescrm.dialer/contacts"

    companion object {
        private const val TAG = "ContactsPlugin"
        private var instance: ContactsPlugin? = null

        fun register(flutterEngine: FlutterEngine, activity: Activity) {
            instance = ContactsPlugin(activity)
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, instance!!.channelId)
            channel.setMethodCallHandler(instance)
        }

        fun lookupContactName(context: Context, phoneNumber: String): String? {
            if (phoneNumber.isBlank()) return null
            return try {
                val uri = Uri.withAppendedPath(
                    ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                    Uri.encode(phoneNumber)
                )
                val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
                val cursor = context.contentResolver.query(uri, projection, null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val nameIndex = it.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                        if (nameIndex != -1) {
                            val name = it.getString(nameIndex)
                            if (!name.isNullOrBlank()) {
                                Log.i(TAG, "Found contact for $phoneNumber: $name")
                                return name
                            }
                        }
                    }
                }
                null
            } catch (e: Exception) {
                Log.e(TAG, "Error looking up contact name: ${e.message}")
                null
            }
        }

        fun saveOrUpdateDeviceContact(context: Context, name: String, phoneNumber: String): Boolean {
            if (name.isBlank() || phoneNumber.isBlank()) return false
            return try {
                val uri = Uri.withAppendedPath(
                    ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                    Uri.encode(phoneNumber)
                )
                val projection = arrayOf(
                    ContactsContract.PhoneLookup._ID,
                    ContactsContract.PhoneLookup.DISPLAY_NAME
                )
                var contactId: Long? = null
                val cursor = context.contentResolver.query(uri, projection, null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val idIdx = it.getColumnIndex(ContactsContract.PhoneLookup._ID)
                        if (idIdx != -1) {
                            contactId = it.getLong(idIdx)
                        }
                    }
                }

                val ops = ArrayList<ContentProviderOperation>()

                if (contactId != null && contactId!! > 0) {
                    // Update existing contact display name
                    val where = "${ContactsContract.Data.CONTACT_ID} = ? AND ${ContactsContract.Data.MIMETYPE} = ?"
                    val params = arrayOf(contactId.toString(), ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                    ops.add(
                        ContentProviderOperation.newUpdate(ContactsContract.Data.CONTENT_URI)
                            .withSelection(where, params)
                            .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
                            .build()
                    )
                } else {
                    // Insert brand new contact
                    val rawIndex = ops.size
                    ops.add(
                        ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                            .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                            .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                            .build()
                    )
                    ops.add(
                        ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                            .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, rawIndex)
                            .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                            .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
                            .build()
                    )
                    ops.add(
                        ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                            .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, rawIndex)
                            .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                            .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phoneNumber)
                            .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                            .build()
                    )
                }

                context.contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
                Log.i(TAG, "Saved contact to device address book: $name ($phoneNumber)")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Error saving contact to address book: ${e.message}")
                false
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "lookupContact" -> {
                val phone = call.argument<String>("phoneNumber") ?: ""
                val name = lookupContactName(activity, phone)
                result.success(name)
            }
            "searchContacts" -> {
                val query = call.argument<String>("query") ?: ""
                val contacts = searchDeviceContacts(activity, query)
                result.success(contacts)
            }
            "saveContact" -> {
                val name = call.argument<String>("name") ?: ""
                val phone = call.argument<String>("phoneNumber") ?: ""
                val saved = saveOrUpdateDeviceContact(activity, name, phone)
                result.success(saved)
            }
            else -> result.notImplemented()
        }
    }

    private fun searchDeviceContacts(context: Context, query: String): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        try {
            val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
            val projection = arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
            )
            val selection = if (query.isNotBlank()) {
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ? OR ${ContactsContract.CommonDataKinds.Phone.NUMBER} LIKE ?"
            } else null
            val selectionArgs = if (query.isNotBlank()) {
                val q = "%$query%"
                arrayOf(q, q)
            } else null

            val cursor = context.contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} ASC"
            )

            cursor?.use {
                val nameIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val numIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                while (it.moveToNext()) {
                    val name = if (nameIdx != -1) it.getString(nameIdx) else ""
                    val num = if (numIdx != -1) it.getString(numIdx) else ""
                    if (!name.isNullOrBlank() && !num.isNullOrBlank()) {
                        list.add(mapOf("name" to name, "phone" to num))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error searching device contacts: ${e.message}")
        }
        return list
    }
}
