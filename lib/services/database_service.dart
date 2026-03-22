import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/participant.dart';
import '../models/nightly_session.dart';
import '../models/questionnaire_models.dart';
import '../models/condition.dart';
import 'randomization_service.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ==================== PARTICIPANT METHODS ====================

  /// Creates a new participant with randomized condition order
  Future<Participant> createParticipant(String userId) async {
    final conditionOrder = RandomizationService.generateConditionOrder();
    final now = DateTime.now();
    
    final participantData = {
      'id': _uuid.v4(),
      'user_id': userId,
      'enrollment_date': now.toIso8601String(),
      'condition_order': conditionOrder.map((c) => c.value).toList(),
      'current_night': 1,
      'status': StudyStatus.preExperiment.value,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final response = await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .insert(participantData)
        .select()
        .single();

    return Participant.fromJson(response);
  }

  /// Gets participant by user ID
  Future<Participant?> getParticipantByUserId(String userId) async {
    final response = await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Participant.fromJson(response);
  }

  /// Updates participant's current night
  Future<void> updateParticipantNight(String participantId, int nightNumber) async {
    await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .update({
          'current_night': nightNumber,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', participantId);
  }

  /// Marks participant's study as completed
  Future<void> completeStudy(String participantId) async {
    await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .update({
          'status': StudyStatus.completed.value,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', participantId);
  }

  /// Gets participant by ID
  Future<Participant?> getParticipant(String participantId) async {
    final response = await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .select()
        .eq('id', participantId)
        .maybeSingle();

    if (response == null) return null;
    return Participant.fromJson(response);
  }

  /// Updates participant's Asleep user ID
  Future<void> updateParticipantAsleepId(String participantId, String asleepUserId) async {
    await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .update({
          'asleep_user_id': asleepUserId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', participantId);
  }

  /// Clears participant's Asleep user ID (used when ID becomes invalid)
  Future<void> clearAsleepUserId(String participantId) async {
    await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .update({
          'asleep_user_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', participantId);
  }

  // ==================== PRE-EXPERIMENT METHODS ====================

  /// Check if participant has completed pre-experiment questionnaires
  Future<bool> hasCompletedPreExperiment(String participantId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.preExperimentResponsesTable)
          .select('id')
          .eq('participant_id', participantId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking pre-experiment completion: $e');
      return false;
    }
  }


  /// Saves pre-experiment questionnaire responses
  /// Uses upsert to overwrite if participant already has responses
  Future<PreExperimentResponses> savePreExperimentResponses({
    required String participantId,
    required String gender,
    required Map<String, dynamic> swashResponses,
    required Map<String, dynamic> psqiResponses,
    Map<String, dynamic>? personalizedConfig,
  }) async {
    final data = {
      'participant_id': participantId,
      'gender': gender,
      'swash_responses': swashResponses,
      'psqi_responses': psqiResponses,
      if (personalizedConfig != null) 'personalized_config': personalizedConfig,
      'completed_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(SupabaseConfig.preExperimentResponsesTable)
        .upsert(data, onConflict: 'participant_id')
        .select()
        .single();

    // Update participant status to in_progress
    await _supabase
        .from(SupabaseConfig.studyParticipantsTable)
        .update({
          'status': StudyStatus.inProgress.value,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', participantId);

    return PreExperimentResponses.fromJson(response);
  }

  // ==================== NIGHTLY SESSION METHODS ====================

  /// Creates a new nightly session or returns existing one for this participant/night
  /// For night_number = 0 (free sessions), always creates a new row
  Future<NightlySession> createNightlySession({
    required String participantId,
    required int nightNumber,
    required Condition condition,
  }) async {
    // For free sessions (night_number = 0), always create new row
    // For study sessions (night 1-3), check for existing to avoid duplicates
    if (nightNumber > 0) {
      // First, check if a session already exists for this participant and night
      final existing = await _supabase
          .from(SupabaseConfig.nightlySessionsTable)
          .select()
          .eq('participant_id', participantId)
          .eq('night_number', nightNumber)
          .maybeSingle();

      if (existing != null) {
        // Return existing session instead of creating duplicate
        return NightlySession.fromJson(existing);
      }
    }

    // Create new session
    final now = DateTime.now();
    final data = {
      'id': _uuid.v4(),
      'participant_id': participantId,
      'night_number': nightNumber,
      'condition': condition.value,
      'session_date': now.toIso8601String().split('T')[0],
      'created_at': now.toIso8601String(),
    };

    final response = await _supabase
        .from(SupabaseConfig.nightlySessionsTable)
        .insert(data)
        .select()
        .single();

    return NightlySession.fromJson(response);
  }

  /// Gets nightly sessions for a participant
  Future<List<NightlySession>> getNightlySessions(String participantId) async {
    final response = await _supabase
        .from(SupabaseConfig.nightlySessionsTable)
        .select()
        .eq('participant_id', participantId)
        .order('night_number');

    return (response as List).map((e) => NightlySession.fromJson(e)).toList();
  }

  /// Gets a single nightly session by session ID
  Future<NightlySession?> getSessionById(String sessionId) async {
    final response = await _supabase
        .from(SupabaseConfig.nightlySessionsTable)
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;
    return NightlySession.fromJson(response);
  }

  /// Saves pre-sleep SSS responses
  Future<void> savePreSleepResponses(
    String sessionId,
    Map<String, dynamic> responses,
  ) async {
    await _supabase
        .from(SupabaseConfig.nightlySessionsTable)
        .update({
          'pre_sleep_responses': responses,
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }

  /// Saves post-sleep LSEQ responses
  Future<void> savePostSleepResponses(
    String sessionId,
    Map<String, dynamic> responses,
  ) async {
    await _supabase
        .from(SupabaseConfig.nightlySessionsTable)
        .update({
          'post_sleep_responses': responses,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }



  // ==================== POST-EXPERIMENT METHODS ====================

  /// Saves post-experiment SASSI responses and feedback
  Future<PostExperimentResponses> savePostExperimentResponses({
    required String participantId,
    required Map<String, dynamic> sassiResponses,
    String? openFeedback,
  }) async {
    final data = {
      'id': _uuid.v4(),
      'participant_id': participantId,
      'sassi_responses': sassiResponses,
      'open_feedback': openFeedback,
      'completed_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(SupabaseConfig.postExperimentResponsesTable)
        .insert(data)
        .select()
        .single();

    return PostExperimentResponses.fromJson(response);
  }
}
