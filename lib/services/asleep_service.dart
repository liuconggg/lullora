import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sleep_report.dart';
import '../models/average_report.dart';
import '../models/participant.dart';
import 'database_service.dart';

/// Enhanced AsleepService with participant-based user ID management
/// Supports iOS only
/// Singleton service to ensure consistent event handling
/// API key is fetched securely from Supabase at runtime
class AsleepService {
  static const MethodChannel _channel = MethodChannel('ai.asleep.sdk/methods');
  static const EventChannel _trackingEventChannel =
      EventChannel('ai.asleep.sdk/tracking_events');

  Stream<Map<String, dynamic>>? _trackingEventsStream;
  StreamSubscription? _trackingEventsSubscription;

  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService();
  
  static bool _isInitialized = false;
  static String? _currentSessionId;
  static String? _currentAsleepUserId;
  static String? _cachedApiKey;

  // Singleton instance
  static final AsleepService _instance = AsleepService._internal();
  
  // Factory constructor returns singleton instance
  factory AsleepService() {
    return _instance;
  }
  
  // Private constructor
  AsleepService._internal();

  // Event callbacks
  Function(String userId)? onUserCreated;
  Function()? onTrackingStarted;
  Function(int sequence)? onSequenceUploaded;
  Function(String sessionId)? onTrackingCompleted;
  Function(String error)? onError;
  Function()? onMicPermissionDenied;

  /// Fetch API key from Supabase app_config table
  /// This keeps the key server-side and fetches it only when needed
  Future<String?> _getApiKey() async {
    // Return cached key if available
    if (_cachedApiKey != null) {
      return _cachedApiKey;
    }
    
    try {
      final response = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'ASLEEP_API_KEY')
          .single();
      
      _cachedApiKey = response['value'] as String?;
      return _cachedApiKey;
    } catch (e) {
      print('Failed to fetch Asleep API key from database: $e');
      return null;
    }
  }

  /// Check if Asleep SDK is available (iOS and Android)
  static bool get isAvailable => Platform.isIOS || Platform.isAndroid;

  /// Check if SDK is initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize Asleep SDK with participant-based user ID management
  Future<bool> initialize({required String participantId}) async {
    if (!isAvailable) {
      print('Asleep SDK is only available on iOS');
      return false;
    }

    if (_isInitialized) {
      print('Asleep SDK already initialized');
      return true;
    }

    final key = await _getApiKey();
    if (key == null || key.isEmpty) {
      print('Asleep API key not found in database');
      return false;
    }
    
    print('Asleep API key loaded: ${key.substring(0, 4)}...');

    try {
      // Get participant to check for existing Asleep user ID
      final participant = await _databaseService.getParticipant(participantId);
      if (participant == null) {
        print('Participant not found: $participantId');
        return false;
      }

      String? asleepUserId = participant.asleepUserId;
      
      if (asleepUserId != null) {
        print('Using existing Asleep user ID: $asleepUserId');
      } else {
        print('No existing Asleep ID, will let SDK generate one');
      }

      final Map<String, dynamic> params = {
        'apiKey': key,
        if (asleepUserId != null) 'userId': asleepUserId,
        // If userId is null, Asleep SDK will generate a new one
      };

      // Set up event listener BEFORE calling SDK so we don't miss the userCreated event
      _startListeningToTrackingEvents(participantId);

      final result = await _channel.invokeMethod('initializeSDK', params);

      if (result == true) {
        _isInitialized = true;
        print('Asleep SDK initialized successfully');
      }

      return result as bool;
    } on PlatformException catch (e) {
      print('Failed to initialize SDK: ${e.message}');
      
      // If user join failed, clear the invalid user ID from database
      // so next attempt will create a fresh user ID
      if (e.code == 'USER_JOIN_FAILED') {
        print('Clearing invalid Asleep user ID from database...');
        try {
          await _databaseService.clearAsleepUserId(participantId);
          print('Invalid user ID cleared. Next attempt will create new user.');
        } catch (clearError) {
          print('Failed to clear invalid user ID: $clearError');
        }
      }
      
      onError?.call(e.message ?? 'Unknown error');
      return false;
    }
  }

  /// Force reinitialize the SDK with fresh data from database
  /// Call this when asleep_user_id might have been updated externally
  Future<bool> reinitialize({required String participantId}) async {
    print('Reinitializing Asleep SDK...');
    
    // Dispose current session if any
    dispose();
    
    // Reset state
    _isInitialized = false;
    _currentAsleepUserId = null;
    _currentSessionId = null;
    
    // Reinitialize with fresh data
    return initialize(participantId: participantId);
  }

  /// Start sleep tracking
  Future<bool> startTracking() async {
    if (!isAvailable) {
      print('Asleep SDK is only available on iOS');
      return false;
    }

    if (!_isInitialized) {
      print('Asleep SDK not initialized. Call initialize() first');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('startTracking');
      print('Sleep tracking started');
      return result as bool;
    } on PlatformException catch (e) {
      print('Failed to start tracking: ${e.message}');
      onError?.call(e.message ?? 'Unknown error');
      return false;
    }
  }

  /// Stop sleep tracking
  Future<bool> stopTracking() async {
    if (!isAvailable) {
      print('Asleep SDK is only available on iOS');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('stopTracking');
      print('Sleep tracking stopped');
      return result as bool;
    } on PlatformException catch (e) {
      print('Failed to stop tracking: ${e.message}');
      onError?.call(e.message ?? 'Unknown error');
      return false;
    }
  }

  /// Get sleep report by session ID
  Future<SleepReport?> getReport(String sessionId) async {
    if (!isAvailable) {
      print('Asleep SDK is only available on iOS');
      return null;
    }

    try {
      final result =
          await _channel.invokeMethod('getReport', {'sessionId': sessionId});

      if (result != null) {
        // Deep cast from platform channel response
        final Map<String, dynamic> reportData = _deepCastMap(result);
        return SleepReport.fromJson(reportData);
      }
      return null;
    } on PlatformException catch (e) {
      print('Failed to get report: ${e.message}');
      onError?.call(e.message ?? 'Unknown error');
      return null;
    }
  }
  
  /// Deep cast Map<Object?, Object?> to Map<String, dynamic>
  Map<String, dynamic> _deepCastMap(dynamic value) {
    if (value is Map) {
      return value.map((key, value) {
        return MapEntry(
          key.toString(),
          _deepCastValue(value),
        );
      });
    }
    return {};
  }
  
  /// Deep cast any value, handling nested structures
  dynamic _deepCastValue(dynamic value) {
    if (value is Map) {
      return _deepCastMap(value);
    } else if (value is List) {
      return value.map((item) => _deepCastValue(item)).toList();
    }
    return value;
  }

  /// Get list of sleep reports for date range
  Future<List<SleepSession>> getReportList({
    required String fromDate,
    required String toDate,
  }) async {
    if (!isAvailable) {
      print('Asleep SDK is only available on iOS');
      return [];
    }

    try {
      final result = await _channel.invokeMethod('getReportList', {
        'fromDate': fromDate,
        'toDate': toDate,
      });

      if (result != null) {
        final List<dynamic> reportListData = result as List<dynamic>;
        return reportListData
            .map((item) =>
                SleepSession.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } on PlatformException catch (e) {
      print('Failed to get report list: ${e.message}');
      onError?.call(e.message ?? 'Unknown error');
      return [];
    }
  }

  /// Get average report for date range
  Future<AverageReport?> getAverageReport({
    required String fromDate,
    required String toDate,
  }) async {
    if (!isAvailable) {
      print('Asleep SDK is only available on iOS');
      return null;
    }

    try {
      final result = await _channel.invokeMethod('getAverageReport', {
        'fromDate': fromDate,
        'toDate': toDate,
      });

      if (result != null) {
        final Map<String, dynamic> averageReportData = _deepCastMap(result);
        return AverageReport.fromJson(averageReportData);
      }
      return null;
    } on PlatformException catch (e) {
      print('Failed to get average report: ${e.message}');
      onError?.call(e.message ?? 'Unknown error');
      return null;
    }
  }


  /// Stop tracking and mark session as completed
  Future<bool> stopTrackingAndSaveMetrics(String nightlySessionId) async {
    if (!isAvailable) {
      print('Asleep SDK is only available on iOS');
      return true;
    }

    // Stop tracking
    final stopped = await stopTracking();
    if (!stopped) {
      print('Failed to stop sleep tracking');
      return false;
    }

    // We no longer fetch and save the full JSON report locally.
    // The Asleep Cloud is the source of truth.
    // We only need to mark the session as completed.
    // The asleep_session_id is saved automatically by the SleepSessionStateService
    // via the onTrackingCompleted event.

    try {
      await _supabase.from('nightly_sessions').update({
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', nightlySessionId);

      print('Session completion time recorded for: $nightlySessionId');
      _currentSessionId = null;
      return true;
    } catch (e) {
      print('Failed to record session completion: $e');
      return false;
    }
  }

  /// Start listening to tracking events from native side
  void _startListeningToTrackingEvents(String participantId) {
    _trackingEventsStream = _trackingEventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event));

    _trackingEventsSubscription = _trackingEventsStream!.listen((event) async {
      final String eventType = event['type'] ?? '';

      switch (eventType) {
        case 'userCreated':
          final String userId = event['userId'] ?? '';
          _currentAsleepUserId = userId;
          print('Asleep user created: $userId');
          
          // Save Asleep user ID to participant record
          await _saveAsleepUserId(participantId, userId);
          
          onUserCreated?.call(userId);
          break;
        case 'trackingStarted':
          print('Asleep tracking started event received');
          onTrackingStarted?.call();
          break;
        case 'sequenceUploaded':
          final int sequence = event['sequence'] ?? 0;
          print('Asleep sequence uploaded: $sequence');
          onSequenceUploaded?.call(sequence);
          break;
        case 'trackingCompleted':
          final String sessionId = event['sessionId'] ?? '';
          _currentSessionId = sessionId;
          print('Asleep tracking completed: $sessionId');
          onTrackingCompleted?.call(sessionId);
          break;
        case 'error':
          final String error = event['error'] ?? 'Unknown error';
          print('Asleep error: $error');
          onError?.call(error);
          break;
        case 'micPermissionDenied':
          print('Asleep microphone permission denied');
          onMicPermissionDenied?.call();
          break;
      }
    });
  }

  /// Save Asleep user ID to participant record
  Future<void> _saveAsleepUserId(String participantId, String asleepUserId) async {
    try {
      await _databaseService.updateParticipantAsleepId(participantId, asleepUserId);
      print('Saved Asleep user ID to participant: $asleepUserId');
    } catch (e) {
      print('Failed to save Asleep user ID: $e');
    }
  }

  /// Get current session ID
  String? get currentSessionId => _currentSessionId;

  /// Check if currently tracking
  bool get isTracking => _currentSessionId != null;

  /// Clean up subscriptions
  void dispose() {
    _trackingEventsSubscription?.cancel();
  }
}
