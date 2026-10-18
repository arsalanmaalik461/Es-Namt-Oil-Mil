package com.arsu.digikhatabyarsu

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val SMS_CHANNEL = "namt_oil_mil/sms"
        private const val SMS_PERMISSION_REQUEST = 1001
    }

    private var pendingSms: Map<String, String>? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canSendSms" -> {
                        result.success(
                            packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
                        )
                    }
                    "sendSms" -> {
                        val number = call.argument<String>("number")
                        val message = call.argument<String>("message")
                        if (number.isNullOrBlank() || message.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "Number/message missing", null)
                            return@setMethodCallHandler
                        }
                        if (hasSmsPermission()) {
                            sendSmsNow(number, message, result)
                        } else {
                            // Ask for permission; complete the call when answered.
                            pendingSms = mapOf("number" to number, "message" to message)
                            pendingResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.SEND_SMS),
                                SMS_PERMISSION_REQUEST
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasSmsPermission(): Boolean =
        ContextCompat.checkSelfPermission(
            this, Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED

    @Suppress("DEPRECATION")
    private fun sendSmsNow(number: String, message: String, result: MethodChannel.Result) {
        try {
            val sms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                SmsManager.getDefault()
            }
            val parts = sms.divideMessage(message)
            if (parts.size > 1) {
                sms.sendMultipartTextMessage(number, null, parts, null, null)
            } else {
                sms.sendTextMessage(number, null, message, null, null)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("SEND_FAILED", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQUEST) {
            val res = pendingResult
            val sms = pendingSms
            pendingResult = null
            pendingSms = null
            if (res == null || sms == null) return
            if (grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            ) {
                sendSmsNow(sms.getValue("number"), sms.getValue("message"), res)
            } else {
                res.error("PERMISSION_DENIED", "User denied SMS permission", null)
            }
        }
    }
}
