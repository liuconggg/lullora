package com.example.lullora_sleep_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import ai.asleep.asleepsdk.Asleep
import ai.asleep.asleepsdk.data.AsleepConfig
import ai.asleep.asleepsdk.data.Report
import ai.asleep.asleepsdk.data.SleepSession
import ai.asleep.asleepsdk.data.AverageReport
import ai.asleep.asleepsdk.tracking.Reports
import android.util.Log
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private val TAG = "[AsleepSDK]"
    private val METHOD_CHANNEL = "ai.asleep.sdk/methods"
    private val EVENT_CHANNEL = "ai.asleep.sdk/tracking_events"
    private val PERMISSION_REQUEST_CODE = 1001
    
    private var asleepConfig: AsleepConfig? = null
    private var reports: Reports? = null
    private var eventSink: EventChannel.EventSink? = null
    private var createdUserId: String? = null
    private var createdSessionId: String? = null
    private var pendingInitResult: MethodChannel.Result? = null
    private var pendingApiKey: String? = null
    private var pendingUserId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "asleep_tracking_channel",
                "Sleep Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for sleep tracking service"
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    private fun requestPermissions(result: MethodChannel.Result, apiKey: String, userId: String?) {
        val permissionsNeeded = mutableListOf<String>()
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) 
            != PackageManager.PERMISSION_GRANTED) {
            permissionsNeeded.add(Manifest.permission.RECORD_AUDIO)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                != PackageManager.PERMISSION_GRANTED) {
                permissionsNeeded.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        
        if (permissionsNeeded.isNotEmpty()) {
            Log.d(TAG, "Requesting permissions: $permissionsNeeded")
            pendingInitResult = result
            pendingApiKey = apiKey
            pendingUserId = userId
            ActivityCompat.requestPermissions(
                this,
                permissionsNeeded.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        } else {
            Log.d(TAG, "Permissions already granted")
            doInitializeSDK(apiKey, userId, result)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            if (allGranted) {
                Log.d(TAG, "All permissions granted")
                pendingInitResult?.let { result ->
                    pendingApiKey?.let { apiKey ->
                        doInitializeSDK(apiKey, pendingUserId, result)
                    }
                }
            } else {
                Log.e(TAG, "Permissions denied")
                pendingInitResult?.error("PERMISSION_DENIED", "Microphone permission is required", null)
                sendEvent(mapOf("type" to "micPermissionDenied"))
            }
            
            pendingInitResult = null
            pendingApiKey = null
            pendingUserId = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initializeSDK" -> {
                        val apiKey = call.argument<String>("apiKey")
                        val userId = call.argument<String>("userId")
                        if (apiKey != null) {
                            initializeSDK(apiKey, userId, result)
                        } else {
                            result.error("INVALID_ARGS", "API key is required", null)
                        }
                    }
                    "startTracking" -> startTracking(result)
                    "stopTracking" -> stopTracking(result)
                    "getReport" -> {
                        val sessionId = call.argument<String>("sessionId")
                        if (sessionId != null) {
                            getReport(sessionId, result)
                        } else {
                            result.error("INVALID_ARGS", "Session ID is required", null)
                        }
                    }
                    "getReportList" -> {
                        val fromDate = call.argument<String>("fromDate")
                        val toDate = call.argument<String>("toDate")
                        if (fromDate != null && toDate != null) {
                            getReportList(fromDate, toDate, result)
                        } else {
                            result.error("INVALID_ARGS", "fromDate and toDate are required", null)
                        }
                    }
                    "getAverageReport" -> {
                        val fromDate = call.argument<String>("fromDate")
                        val toDate = call.argument<String>("toDate")
                        if (fromDate != null && toDate != null) {
                            getAverageReport(fromDate, toDate, result)
                        } else {
                            result.error("INVALID_ARGS", "fromDate and toDate are required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Setup Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun initializeSDK(apiKey: String, userId: String?, result: MethodChannel.Result) {
        Log.d(TAG, "Requesting permissions before SDK init...")
        requestPermissions(result, apiKey, userId)
    }

    private fun doInitializeSDK(apiKey: String, userId: String?, result: MethodChannel.Result) {
        Log.d(TAG, "Initializing Asleep SDK with apiKey: ${apiKey.take(4)}...")
        
        Asleep.initAsleepConfig(
            context = this,
            apiKey = apiKey,
            userId = userId,
            service = "Lullora Sleep App",
            asleepConfigListener = object : Asleep.AsleepConfigListener {
                override fun onSuccess(userId: String?, asleepConfig: AsleepConfig?) {
                    Log.d(TAG, "initAsleepConfig onSuccess userId: $userId")
                    createdUserId = userId
                    this@MainActivity.asleepConfig = asleepConfig
                    
                    // Create reports instance
                    reports = Asleep.createReports(asleepConfig)
                    
                    // Send userCreated event
                    sendEvent(mapOf("type" to "userCreated", "userId" to (userId ?: "")))
                    
                    result.success(true)
                }

                override fun onFail(errorCode: Int, detail: String) {
                    Log.e(TAG, "initAsleepConfig onFail: $errorCode - $detail")
                    sendEvent(mapOf("type" to "error", "error" to "Init failed: $detail"))
                    result.error("INIT_FAILED", detail, errorCode)
                }
            }
        )
    }

    private fun startTracking(result: MethodChannel.Result) {
        val config = asleepConfig
        if (config == null) {
            result.error("NOT_INITIALIZED", "SDK not initialized", null)
            return
        }

        Log.d(TAG, "Starting sleep tracking...")
        
        Asleep.beginSleepTracking(
            asleepConfig = config,
            notificationTitle = "Sleep Tracking Active",
            notificationText = "Recording your sleep session",
            notificationIcon = android.R.drawable.ic_menu_recent_history,
            asleepTrackingListener = object : Asleep.AsleepTrackingListener {
                override fun onStart(sessionId: String) {
                    Log.d(TAG, "Tracking started: $sessionId")
                    createdSessionId = sessionId
                    sendEvent(mapOf("type" to "trackingStarted"))
                }

                override fun onPerform(sequence: Int) {
                    Log.d(TAG, "Sequence uploaded: $sequence")
                    sendEvent(mapOf("type" to "sequenceUploaded", "sequence" to sequence))
                }

                override fun onFinish(sessionId: String?) {
                    Log.d(TAG, "Tracking finished: $sessionId")
                    sendEvent(mapOf("type" to "trackingCompleted", "sessionId" to (sessionId ?: "")))
                }

                override fun onFail(errorCode: Int, detail: String) {
                    Log.e(TAG, "Tracking failed: $errorCode - $detail")
                    sendEvent(mapOf("type" to "error", "error" to detail))
                }
            }
        )
        
        result.success(true)
    }

    private fun stopTracking(result: MethodChannel.Result) {
        Log.d(TAG, "Stopping sleep tracking...")
        Asleep.endSleepTracking()
        result.success(true)
    }

    private fun getReport(sessionId: String, result: MethodChannel.Result) {
        val reportsInstance = reports
        if (reportsInstance == null) {
            result.error("NOT_INITIALIZED", "Reports not initialized", null)
            return
        }

        reportsInstance.getReport(
            sessionId = sessionId,
            reportListener = object : Reports.ReportListener {
                override fun onSuccess(report: Report?) {
                    if (report != null) {
                        result.success(convertReportToMap(report))
                    } else {
                        result.success(null)
                    }
                }

                override fun onFail(errorCode: Int, detail: String) {
                    result.error("REPORT_ERROR", detail, errorCode)
                }
            }
        )
    }

    private fun getReportList(fromDate: String, toDate: String, result: MethodChannel.Result) {
        val reportsInstance = reports
        if (reportsInstance == null) {
            result.error("NOT_INITIALIZED", "Reports not initialized", null)
            return
        }

        reportsInstance.getReports(
            fromDate = fromDate,
            toDate = toDate,
            reportsListener = object : Reports.ReportsListener {
                override fun onSuccess(reports: List<SleepSession>?) {
                    val reportList = reports?.map { convertSessionToMap(it) } ?: emptyList()
                    result.success(reportList)
                }

                override fun onFail(errorCode: Int, detail: String) {
                    result.error("REPORT_LIST_ERROR", detail, errorCode)
                }
            }
        )
    }

    private fun getAverageReport(fromDate: String, toDate: String, result: MethodChannel.Result) {
        val reportsInstance = reports
        if (reportsInstance == null) {
            result.error("NOT_INITIALIZED", "Reports not initialized", null)
            return
        }

        reportsInstance.getAverageReport(
            fromDate = fromDate,
            toDate = toDate,
            averageReportListener = object : Reports.AverageReportListener {
                override fun onSuccess(averageReport: AverageReport?) {
                    if (averageReport != null) {
                        result.success(convertAverageReportToMap(averageReport))
                    } else {
                        result.success(null)
                    }
                }

                override fun onFail(errorCode: Int, detail: String) {
                    result.error("AVERAGE_REPORT_ERROR", detail, errorCode)
                }
            }
        )
    }

    private fun sendEvent(event: Map<String, Any>) {
        runOnUiThread {
            eventSink?.success(event)
        }
    }

    private fun convertReportToMap(report: Report): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        
        // Session data
        report.session?.let { session ->
            map["session"] = mapOf(
                "id" to session.id,
                "state" to session.state,
                "startTime" to session.startTime,
                "endTime" to session.endTime,
                "sleepStages" to session.sleepStages,
                "createdTimezone" to session.createdTimezone,
                "unexpectedEndTime" to session.unexpectedEndTime
            )
        }
        
        // Stat data
        report.stat?.let { stat ->
            map["stat"] = mapOf(
                "sleepEfficiency" to stat.sleepEfficiency,
                "sleepLatency" to stat.sleepLatency,
                "wakeupLatency" to stat.wakeupLatency,
                "sleepTime" to stat.sleepTime,
                "wakeTime" to stat.wakeTime,
                "timeInWake" to stat.timeInWake,
                "timeInSleep" to stat.timeInSleep,
                "timeInBed" to stat.timeInBed,
                "timeInSleepPeriod" to stat.timeInSleepPeriod,
                "timeInRem" to stat.timeInRem,
                "timeInLight" to stat.timeInLight,
                "timeInDeep" to stat.timeInDeep,
                "wakeRatio" to stat.wakeRatio,
                "sleepRatio" to stat.sleepRatio,
                "remRatio" to stat.remRatio,
                "lightRatio" to stat.lightRatio,
                "deepRatio" to stat.deepRatio,
                "timeInSnoring" to stat.timeInSnoring,
                "timeInNoSnoring" to stat.timeInNoSnoring,
                "snoringRatio" to stat.snoringRatio,
                "noSnoringRatio" to stat.noSnoringRatio,
                "snoringCount" to stat.snoringCount
            )
        }
        
        map["missingDataRatio"] = report.missingDataRatio
        map["peculiarities"] = report.peculiarities
        
        return map
    }

    private fun convertSessionToMap(session: SleepSession): Map<String, Any?> {
        return mapOf(
            "sessionId" to session.sessionId,
            "state" to session.state,
            "sessionStartTime" to session.sessionStartTime,
            "sessionEndTime" to session.sessionEndTime,
            "timeInBed" to session.timeInBed,
            "createdTimezone" to session.createdTimezone,
            "unexpectedEndTime" to session.unexpectedEndTime
        )
    }

    private fun convertAverageReportToMap(averageReport: AverageReport): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        
        // Period
        map["period"] = mapOf(
            "timezone" to averageReport.period.timezone,
            "startDate" to averageReport.period.startDate,
            "endDate" to averageReport.period.endDate
        )
        
        // Peculiarities
        map["peculiarities"] = averageReport.peculiarities
        
        // Average Stats
        averageReport.averageStats?.let { stats ->
            map["averageStats"] = mapOf(
                "startTime" to stats.startTime,
                "endTime" to stats.endTime,
                "sleepTime" to stats.sleepTime,
                "wakeTime" to stats.wakeTime,
                "sleepLatency" to stats.sleepLatency,
                "wakeupLatency" to stats.wakeupLatency,
                "timeInBed" to stats.timeInBed,
                "timeInSleepPeriod" to stats.timeInSleepPeriod,
                "timeInSleep" to stats.timeInSleep,
                "timeInWake" to stats.timeInWake,
                "timeInLight" to stats.timeInLight,
                "timeInDeep" to stats.timeInDeep,
                "timeInRem" to stats.timeInRem,
                "sleepEfficiency" to stats.sleepEfficiency,
                "wakeRatio" to stats.wakeRatio,
                "sleepRatio" to stats.sleepRatio,
                "lightRatio" to stats.lightRatio,
                "deepRatio" to stats.deepRatio,
                "remRatio" to stats.remRatio,
                "wasoCount" to stats.wasoCount,
                "longestWaso" to stats.longestWaso,
                "sleepCycleCount" to stats.sleepCycleCount,
                "timeInSnoring" to stats.timeInSnoring,
                "timeInNoSnoring" to stats.timeInNoSnoring,
                "snoringRatio" to stats.snoringRatio,
                "noSnoringRatio" to stats.noSnoringRatio,
                "snoringCount" to stats.snoringCount
            )
        }
        
        // Session lists - these fields may vary by SDK version
        map["sleptSessions"] = emptyList<Map<String, Any>>()
        map["neverSleptSessions"] = emptyList<Map<String, Any>>()
        
        return map
    }
}
