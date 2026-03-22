import Flutter
import UIKit
import AsleepSDK

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var asleepBridge: AsleepBridge?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup Asleep SDK platform channels
    setupAsleepChannels()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupAsleepChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    asleepBridge = AsleepBridge()
    
    // Method channel for SDK operations
    let methodChannel = FlutterMethodChannel(
      name: "ai.asleep.sdk/methods",
      binaryMessenger: controller.binaryMessenger
    )
    
    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self, let bridge = self.asleepBridge else {
        result(FlutterError(code: "UNAVAILABLE", message: "Bridge not available", details: nil))
        return
      }
      
      switch call.method {
      case "initializeSDK":
        if let args = call.arguments as? [String: Any],
           let apiKey = args["apiKey"] as? String {
          let userId = args["userId"] as? String
          let baseUrl = args["baseUrl"] as? String
          let callbackUrl = args["callbackUrl"] as? String
          bridge.initializeSDK(apiKey: apiKey, userId: userId, baseUrl: baseUrl, callbackUrl: callbackUrl, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "startTracking":
        bridge.startTracking(result: result)
        
      case "stopTracking":
        bridge.stopTracking(result: result)
        
      case "getReport":
        if let args = call.arguments as? [String: Any],
           let sessionId = args["sessionId"] as? String {
          bridge.getReport(sessionId: sessionId, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "getReportList":
        if let args = call.arguments as? [String: Any],
           let fromDate = args["fromDate"] as? String,
           let toDate = args["toDate"] as? String {
          bridge.getReportList(fromDate: fromDate, toDate: toDate, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "getAverageReport":
        if let args = call.arguments as? [String: Any],
           let fromDate = args["fromDate"] as? String,
           let toDate = args["toDate"] as? String {
          bridge.getAverageReport(fromDate: fromDate, toDate: toDate, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Event channel for tracking status updates
    let eventChannel = FlutterEventChannel(
      name: "ai.asleep.sdk/tracking_events",
      binaryMessenger: controller.binaryMessenger
    )
    
    eventChannel.setStreamHandler(asleepBridge)
  }
}

// MARK: - AsleepBridge

class AsleepBridge: NSObject {
    private var trackingManager: Asleep.SleepTrackingManager?
    private var reports: Asleep.Reports?
    private var config: Asleep.Config?
    private var eventSink: FlutterEventSink?
    
    // Retry state for handling invalid user IDs
    private var pendingApiKey: String?
    private var pendingBaseUrl: String?
    private var pendingCallbackUrl: String?
    private var pendingResult: FlutterResult?
    private var isRetrying: Bool = false
    
    // MARK: - SDK Initialization
    
    func initializeSDK(apiKey: String, userId: String?, baseUrl: String?, callbackUrl: String?, result: @escaping FlutterResult) {
        let baseURL = baseUrl != nil ? URL(string: baseUrl!) : nil
        let callbackURL = callbackUrl != nil ? URL(string: callbackUrl!) : nil
        
        // Store params for potential retry
        pendingApiKey = apiKey
        pendingBaseUrl = baseUrl
        pendingCallbackUrl = callbackUrl
        pendingResult = result
        isRetrying = false
        
        Asleep.initAsleepConfig(
            apiKey: apiKey,
            userId: userId,
            baseUrl: baseURL,
            callbackUrl: callbackURL,
            delegate: self
        )
        
        // Note: result will be called in userDidJoin or after retry
    }
    
    /// Retry initialization without userId (to create new user)
    private func retryWithoutUserId() {
        guard let apiKey = pendingApiKey else {
            pendingResult?(FlutterError(code: "RETRY_FAILED", message: "No API key for retry", details: nil))
            return
        }
        
        isRetrying = true
        let baseURL = pendingBaseUrl != nil ? URL(string: pendingBaseUrl!) : nil
        let callbackURL = pendingCallbackUrl != nil ? URL(string: pendingCallbackUrl!) : nil
        
        print("Retrying Asleep SDK initialization without userId...")
        
        Asleep.initAsleepConfig(
            apiKey: apiKey,
            userId: nil,  // No userId = create new user
            baseUrl: baseURL,
            callbackUrl: callbackURL,
            delegate: self
        )
    }
    
    // MARK: - Sleep Tracking
    
    func startTracking(result: @escaping FlutterResult) {
        guard let trackingManager = trackingManager else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized", details: nil))
            return
        }
        
        trackingManager.startTracking()
        result(true)
    }
    
    func stopTracking(result: @escaping FlutterResult) {
        guard let trackingManager = trackingManager else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "SDK not initialized", details: nil))
            return
        }
        
        trackingManager.stopTracking()
        result(true)
    }
    
    // MARK: - Reports
    
    func getReport(sessionId: String, result: @escaping FlutterResult) {
        guard let reports = reports else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Reports not initialized", details: nil))
            return
        }
        
        Task {
            do {
                let report = try await reports.report(sessionId: sessionId)
                let reportDict = self.convertReportToDict(report)
                result(reportDict)
            } catch {
                result(FlutterError(code: "REPORT_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    func getReportList(fromDate: String, toDate: String, result: @escaping FlutterResult) {
        guard let reports = reports else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Reports not initialized", details: nil))
            return
        }
        
        Task {
            do {
                let reportList = try await reports.reports(fromDate: fromDate, toDate: toDate)
                let reportListArray = reportList.map { self.convertSessionToDict($0) }
                result(reportListArray)
            } catch {
                result(FlutterError(code: "REPORT_LIST_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    func getAverageReport(fromDate: String, toDate: String, result: @escaping FlutterResult) {
        guard let reports = reports else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Reports not initialized", details: nil))
            return
        }
        
        Task {
            do {
                let averageReport = try await reports.getAverageReport(fromDate: fromDate, toDate: toDate)
                let averageReportDict = self.convertAverageReportToDict(averageReport)
                result(averageReportDict)
            } catch {
                result(FlutterError(code: "AVERAGE_REPORT_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    // MARK: - Event Sink
    
    func setEventSink(_ eventSink: FlutterEventSink?) {
        self.eventSink = eventSink
    }
    
    private func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(event)
        }
    }
    
    // MARK: - Data Conversion
    
    private func convertReportToDict(_ report: Asleep.Model.Report) -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        func safeValue(_ value: Any?) -> Any? {
            guard let value = value else { return nil }
            if let date = value as? Date {
                return dateFormatter.string(from: date)
            }
            return value
        }
        
        var dict: [String: Any] = [:]
        
        // Session data
        dict["session"] = [
            "id": report.session.id,
            "state": report.session.state.rawValue,
            "createdTimezone": report.session.createdTimezone.description,
            "startTime": safeValue(report.session.startTime),
            "endTime": safeValue(report.session.endTime) as Any,
            "unexpectedEndTime": safeValue(report.session.unexpectedEndTime) as Any,
            "sleepStages": report.session.sleepStages as Any,
            "snoringStages": report.session.snoringStages as Any
        ]
        
        // Stats data
        if let stat = report.stat {
            dict["stat"] = [
                "sleepEfficiency": safeValue(stat.sleepEfficiency) as Any,
                "sleepLatency": safeValue(stat.sleepLatency) as Any,
                "wakeupLatency": safeValue(stat.wakeupLatency) as Any,
                "sleepTime": safeValue(stat.sleepTime) as Any,
                "wakeTime": safeValue(stat.wakeTime) as Any,
                "lightLatency": safeValue(stat.lightLatency) as Any,
                "deepLatency": safeValue(stat.deepLatency) as Any,
                "remLatency": safeValue(stat.remLatency) as Any,
                "timeInWake": safeValue(stat.timeInWake) as Any,
                "timeInSleep": safeValue(stat.timeInSleep) as Any,
                "timeInBed": safeValue(stat.timeInBed) as Any,
                "timeInSleepPeriod": safeValue(stat.timeInSleepPeriod) as Any,
                "timeInRem": safeValue(stat.timeInRem) as Any,
                "timeInLight": safeValue(stat.timeInLight) as Any,
                "timeInDeep": safeValue(stat.timeInDeep) as Any,
                "wakeRatio": safeValue(stat.wakeRatio) as Any,
                "sleepRatio": safeValue(stat.sleepRatio) as Any,
                "remRatio": safeValue(stat.remRatio) as Any,
                "lightRatio": safeValue(stat.lightRatio) as Any,
                "deepRatio": safeValue(stat.deepRatio) as Any,
                "timeInSnoring": safeValue(stat.timeInSnoring) as Any,
                "timeInNoSnoring": safeValue(stat.timeInNoSnoring) as Any,
                "snoringRatio": safeValue(stat.snoringRatio) as Any,
                "noSnoringRatio": safeValue(stat.noSnoringRatio) as Any,
                "snoringCount": safeValue(stat.snoringCount) as Any
            ]
        }
        
        dict["missingDataRatio"] = safeValue(report.missingDataRatio)
        dict["peculiarities"] = report.peculiarities.map { String(describing: $0) }
        
        return dict
    }
    
    private func convertSessionToDict(_ session: Asleep.Model.SleepSession) -> [String: Any] {
        return [
            "sessionId": session.sessionId,
            "state": String(describing: session.state),
            "sessionStartTime": ISO8601DateFormatter().string(from: session.sessionStartTime),
            "sessionEndTime": session.sessionEndTime.map { ISO8601DateFormatter().string(from: $0) } as Any
        ]
    }
    
    private func convertAverageReportToDict(_ averageReport: Asleep.Model.AverageReport) -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        func safeValue(_ value: Any?) -> Any? {
            guard let value = value else { return nil }
            if let date = value as? Date {
                return dateFormatter.string(from: date)
            }
            return value
        }
        
        var dict: [String: Any] = [:]
        
        // Period
        dict["period"] = [
            "timezone": averageReport.period.timezone.description,
            "startDate": dateFormatter.string(from: averageReport.period.startDate),
            "endDate": dateFormatter.string(from: averageReport.period.endDate)
        ]
        
        // Peculiarities
        dict["peculiarities"] = averageReport.peculiarities.map { String(describing: $0) }
        
        // Average Stats
        if let stats = averageReport.averageStats {
            dict["averageStats"] = [
                "startTime": stats.startTime,
                "endTime": stats.endTime,
                "sleepTime": stats.sleepTime,
                "wakeTime": stats.wakeTime,
                "sleepLatency": stats.sleepLatency,
                "wakeupLatency": stats.wakeupLatency,
                "timeInBed": stats.timeInBed,
                "timeInSleepPeriod": stats.timeInSleepPeriod,
                "timeInSleep": stats.timeInSleep,
                "timeInWake": stats.timeInWake,
                "timeInLight": safeValue(stats.timeInLight) as Any,
                "timeInDeep": safeValue(stats.timeInDeep) as Any,
                "timeInRem": safeValue(stats.timeInRem) as Any,
                "timeInSnoring": safeValue(stats.timeInSnoring) as Any,
                "timeInNoSnoring": safeValue(stats.timeInNoSnoring) as Any,
                "sleepEfficiency": stats.sleepEfficiency,
                "wakeRatio": stats.wakeRatio,
                "sleepRatio": stats.sleepRatio,
                "lightRatio": safeValue(stats.lightRatio) as Any,
                "deepRatio": safeValue(stats.deepRatio) as Any,
                "remRatio": safeValue(stats.remRatio) as Any,
                "snoringRatio": safeValue(stats.snoringRatio) as Any,
                "noSnoringRatio": safeValue(stats.noSnoringRatio) as Any,
                "wasoCount": stats.wasoCount,
                "longestWaso": stats.longestWaso,
                "sleepCycleCount": stats.sleepCycleCount,
                "snoringCount": safeValue(stats.snoringCount) as Any
            ]
        }
        
        // Session lists
        dict["sleptSessions"] = averageReport.sleptSessions.map { session in
            return ["id": session.id]
        }
        
        dict["neverSleptSessions"] = averageReport.neverSleptSessions.map { session in
            return ["id": session.id]
        }
        
        return dict
    }
}

// MARK: - AsleepConfigDelegate

extension AsleepBridge: AsleepConfigDelegate {
    func userDidJoin(userId: String, config: Asleep.Config) {
        self.config = config
        
        // Initialize tracking manager
        trackingManager = Asleep.createSleepTrackingManager(config: config, delegate: self)
        
        // Initialize reports
        reports = Asleep.createReports(config: config)
        
        // Return success to Flutter
        pendingResult?(true)
        pendingResult = nil
        
        // Send event to Flutter
        sendEvent(["type": "userCreated", "userId": userId])
    }
    
    func didFailUserJoin(error: Asleep.AsleepError) {
        // Check if this is a 404 "user does not exist" error
        var is404Error = false
        if case let .httpStatus(code, _, _) = error, code == 404 {
            is404Error = true
        }
        
        // If it's a 404 and we haven't retried yet, retry without userId
        if is404Error && !isRetrying {
            print("User not found (404), retrying with new user creation...")
            retryWithoutUserId()
            return
        }
        
        // Otherwise, return failure to Flutter
        pendingResult?(FlutterError(code: "USER_JOIN_FAILED", message: "Failed to join user: \(error)", details: nil))
        pendingResult = nil
        
        sendEvent(["type": "error", "error": "Failed to join user: \(error)"])
    }
    
    func userDidDelete(userId: String) {
        print("User deleted: \(userId)")
    }
}

// MARK: - AsleepSleepTrackingManagerDelegate

extension AsleepBridge: AsleepSleepTrackingManagerDelegate {
    func didCreate() {
        sendEvent(["type": "trackingStarted"])
    }
    
    func didUpload(sequence: Int) {
        sendEvent(["type": "sequenceUploaded", "sequence": sequence])
    }
    
    func didClose(sessionId: String) {
        sendEvent(["type": "trackingCompleted", "sessionId": sessionId])
    }
    
    func didFail(error: Asleep.AsleepError) {
        var errorMessage = "Tracking error"
        
        switch error {
        case let .httpStatus(code, _, message):
            errorMessage = "\(code): \(message ?? "")"
        default:
            errorMessage = "\(error)"
        }
        
        sendEvent(["type": "error", "error": errorMessage])
    }
    
    func analysing(session: Asleep.Model.Session) {
        print("Analyzing session: \(session)")
    }
    
    func didInterrupt() {
        print("Tracking interrupted")
    }
    
    func didResume() {
        print("Tracking resumed")
    }
    
    func micPermissionWasDenied() {
        sendEvent(["type": "micPermissionDenied"])
    }
}

// MARK: - FlutterStreamHandler

extension AsleepBridge: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        setEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        setEventSink(nil)
        return nil
    }
}
