package com.aliakseipcholkin.smart_planner

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Required for app_links when launchMode is singleTop (widget / deep links).
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALENDAR_SETTINGS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openCalendarSettings" -> result.success(openCalendarSettings())
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALENDAR_INSTANCES_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "retrieveEventsInRange" -> {
                    if (!hasCalendarReadPermission()) {
                        result.error(
                            "PERMISSION_DENIED",
                            "READ_CALENDAR not granted",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    @Suppress("UNCHECKED_CAST")
                    val calendarIds =
                        call.argument<List<String>>("calendarIds") ?: emptyList()
                    val startMs = call.argument<Long>("startMs")
                    val endMs = call.argument<Long>("endMs")
                    if (startMs == null || endMs == null) {
                        result.error("INVALID_ARGS", "startMs/endMs required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val json = CalendarInstancesReader.retrieveEventsJson(
                            contentResolver = contentResolver,
                            calendarIds = calendarIds,
                            startMs = startMs,
                            endMs = endMs,
                        )
                        result.success(json)
                    } catch (e: Exception) {
                        result.error("QUERY_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasCalendarReadPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_CALENDAR,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun openCalendarSettings(): Boolean {
        val candidates = mutableListOf<Intent>()

        for (packageName in CALENDAR_APP_PACKAGES) {
            candidates.add(
                Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    setPackage(packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
        }

        candidates.add(
            Intent(Settings.ACTION_SYNC_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )

        candidates.add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", applicationContext.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )

        for (intent in candidates) {
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        }
        return false
    }

    companion object {
        private const val CALENDAR_SETTINGS_CHANNEL =
            "com.aliakseipcholkin.smart_planner/calendar_settings"

        private const val CALENDAR_INSTANCES_CHANNEL =
            "com.aliakseipcholkin.smart_planner/calendar_instances"

        private val CALENDAR_APP_PACKAGES = listOf(
            "com.google.android.calendar",
            "com.samsung.android.calendar",
            "com.android.calendar",
        )
    }
}
