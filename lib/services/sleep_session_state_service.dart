import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nightly_session.dart';
import '../models/participant.dart';
import '../config/supabase_config.dart';
import 'asleep_service.dart';
import 'database_service.dart';

/// Service to manage sleep session tracking state
/// Singleton service to ensure consistent state tracking
class SleepSessionStateService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AsleepService _asleepService = AsleepService();
  final DatabaseService _databaseService = DatabaseService();
  
  // Track current database session ID for event callbacks
  String? _currentDbSessionId;
  
  // Singleton instance
  static final SleepSessionStateService _instance = 
      SleepSessionStateService._internal();
  
  // Factory constructor returns singleton instance
  factory SleepSessionStateService() {
    return _instance;
  }
  
  // Private constructor
  SleepSessionStateService._internal() {
    _setupAsleepCallbacks();
  }
  
  /// Setup callbacks for Asleep SDK events
  void _setupAsleepCallbacks() {
    _asleepService.onTrackingCompleted = (asleepSessionId) {
      print('Asleep SDK trackingCompleted event: $asleepSessionId');
      if (_currentDbSessionId != null) {
        _saveAsleepSessionId(_currentDbSessionId!, asleepSessionId);
      } else {
        print('WARNING: No database session ID available to save Asleep session ID');
      }
    };
  }
  
  /// Save Asleep session ID to database
  Future<void> _saveAsleepSessionId(String dbSessionId, String asleepSessionId) async {
    try {
      print('Saving Asleep session ID: $asleepSessionId for DB session: $dbSessionId');
      
      // Get session to find participant ID
      final session = await _databaseService.getSessionById(dbSessionId);
      
      // Save to nightly_sessions table
      await _supabase
          .from(SupabaseConfig.nightlySessionsTable)
          .update({'asleep_session_id': asleepSessionId})
          .eq('id', dbSessionId);
      print('✓ Asleep session ID saved to nightly_sessions');
      
      // Also update dynamic_hypnosis_sessions with the Asleep session ID
      // This links the personalized hypnosis audio to the sleep tracking data
      if (session != null) {
        await _supabase
            .from('dynamic_hypnosis_sessions')
            .update({'session_id': asleepSessionId})
            .eq('participant_id', session.participantId)
            .isFilter('session_id', null); // Only update if not already set
        print('✓ Asleep session ID saved to dynamic_hypnosis_sessions');
      }
    } catch (e) {
      print('ERROR saving Asleep session ID: $e');
    }
  }

  /// Start sleep tracking for a session
  Future<bool> startTracking(String sessionId) async {
    try {
      // Get session to find participant ID
      final session = await _databaseService.getSessionById(sessionId);
      if (session == null) {
        print('Session not found: $sessionId');
        return false;
      }

      // Initialize Asleep SDK with participant ID
      final initialized = await _asleepService.initialize(
        participantId: session.participantId,
      );
      
      if (!initialized) {
        print('Failed to initialize Asleep SDK');
        return false;
      }

      // Start Asleep SDK tracking
      final trackingStarted = await _asleepService.startTracking();
      if (!trackingStarted) {
        print('Failed to start Asleep SDK tracking');
        return false;
      }

      // Update session state in database
      await _supabase
          .from(SupabaseConfig.nightlySessionsTable)
          .update({
            'tracking_state': 'tracking',
            'tracking_started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      // Store current session ID for event callbacks
      _currentDbSessionId = sessionId;

      print('Sleep tracking started for session: $sessionId');
      return true;
    } catch (e) {
      print('Error starting sleep tracking: $e');
      return false;
    }
  }

  /// Stop sleep tracking for a session
  Future<bool> stopTracking(String sessionId) async {
    try {
      // Stop Asleep SDK tracking
      final trackingStopped = await _asleepService.stopTracking();
      if (!trackingStopped) {
        print('Failed to stop Asleep SDK tracking');
        // Continue anyway to update database
      }

      // Update session state in database
      await _supabase
          .from(SupabaseConfig.nightlySessionsTable)
          .update({
            'tracking_state': 'stopped',
            'tracking_stopped_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      print('Sleep tracking stopped for session: $sessionId');
      
      // Event callback will handle saving Asleep session ID
      // Sleep metrics will be fetched on-demand in Analytics

      return true;
    } catch (e) {
      print('Error stopping sleep tracking: $e');
      return false;
    }
  }



  /// Mark session as completed
  Future<void> markCompleted(String sessionId) async {
    try {
      await _supabase
          .from(SupabaseConfig.nightlySessionsTable)
          .update({
            'tracking_state': 'completed',
          })
          .eq('id', sessionId);

      print('Session marked as completed: $sessionId');
    } catch (e) {
      print('Error marking session as completed: $e');
    }
  }

  /// Get session by ID
  Future<NightlySession?> getSession(String sessionId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.nightlySessionsTable)
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (response == null) return null;
      return NightlySession.fromJson(response);
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  /// Get active tracking session for a participant
  Future<NightlySession?> getActiveTrackingSession(String participantId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.nightlySessionsTable)
          .select()
          .eq('participant_id', participantId)
          .eq('tracking_state', 'tracking')
          .maybeSingle();

      if (response == null) return null;
      return NightlySession.fromJson(response);
    } catch (e) {
      print('Error getting active tracking session: $e');
      return null;
    }
  }

  /// Check if participant has an active tracking session
  Future<bool> hasActiveSession(String participantId) async {
    final session = await getActiveTrackingSession(participantId);
    return session != null;
  }

  /// Get tracking duration for a session
  Duration? getTrackingDuration(NightlySession session) {
    if (session.trackingStartedAt == null) return null;
    
    final endTime = session.trackingStoppedAt ?? DateTime.now();
    return endTime.difference(session.trackingStartedAt!);
  }
}
