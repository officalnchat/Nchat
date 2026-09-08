package com.example.nchat

import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "nchat/contacts"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "getContacts") {

                val contacts = mutableListOf<String>()

                val cursor = contentResolver.query(
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                    arrayOf(
                        ContactsContract.CommonDataKinds.Phone.NUMBER
                    ),
                    null,
                    null,
                    null
                )

                cursor?.use {
                    val numberIndex =
                        it.getColumnIndex(
                            ContactsContract.CommonDataKinds.Phone.NUMBER
                        )

                    while (it.moveToNext()) {
                        if (numberIndex >= 0) {
                            val number =
                                it.getString(numberIndex)

                            if (!number.isNullOrBlank()) {
                                contacts.add(number)
                            }
                        }
                    }
                }

                result.success(contacts)
            } else {
                result.notImplemented()
            }
        }
    }
}