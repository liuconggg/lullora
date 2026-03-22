import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Load from environment variables
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Table names
  static const String studyParticipantsTable = 'study_participants';
  static const String nightlySessionsTable = 'nightly_sessions';
  static const String preExperimentResponsesTable = 'pre_experiment_responses';
  static const String postExperimentResponsesTable = 'post_experiment_responses';
  
  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}