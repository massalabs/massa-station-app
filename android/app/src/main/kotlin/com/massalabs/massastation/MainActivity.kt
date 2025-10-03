package com.massalabs.massastation

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.massa.station/biometric_storage"
    private lateinit var biometricStorage: BiometricKeyStorage

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        biometricStorage = BiometricKeyStorage(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "storeBiometricKey" -> {
                    val key = call.argument<String>("key")
                    if (key != null) {
                        biometricStorage.storeKey(key, this) { success ->
                            runOnUiThread {
                                result.success(success)
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Key not provided", null)
                    }
                }

                "retrieveBiometricKey" -> {
                    biometricStorage.retrieveKey(this) { key ->
                        runOnUiThread {
                            result.success(key)
                        }
                    }
                }

                "deleteBiometricKey" -> {
                    val success = biometricStorage.deleteKey()
                    result.success(success)
                }

                "hasBiometricKey" -> {
                    val hasKey = biometricStorage.hasKey()
                    result.success(hasKey)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
