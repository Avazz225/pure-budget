package com.jne_solutions.jne_household_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {

    private val CHANNEL = "com.jne_solutions/uri"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val data: Uri? = intent.data
        data?.let { uri ->
            if (uri.host == "addExpense") {
                val categoryId = uri.getQueryParameter("categoryId")
                categoryId?.let {
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, CHANNEL).invokeMethod("addExpense", it)
                    }
                }
            }
        }
    }
}
