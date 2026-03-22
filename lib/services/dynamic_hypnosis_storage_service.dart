import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dynamic_hypnosis_config.dart';
import '../models/dynamic_hypnosis_session.dart';

class DynamicHypnosisStorageService {
  final _supabase = Supabase.instance.client;
  static const String _bucketName = 'dynamic-hypnosis-audio';
  
  /// Gets the app's document directory for storing files before upload
  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final hypnosisDir = Directory('${appDir.path}/dynamic_hypnosis');
    
    if (!await hypnosisDir.exists()) {
      await hypnosisDir.create(recursive: true);
    }
    
    return hypnosisDir;
  }

  /// Generates file path for script based on config
  Future<String> getScriptPath(DynamicHypnosisConfig config) async {
    final dir = await _getStorageDirectory();
    return '${dir.path}/${config.cacheKey}.txt';
  }

  /// Generates file path for audio based on config
  Future<String> getAudioPath(DynamicHypnosisConfig config) async {
    final dir = await _getStorageDirectory();
    final path = '${dir.path}/${config.cacheKey}.mp3';
    print('🎵 Audio path: $path');
    return path;
  }

  /// Checks if script exists for given config
  Future<bool> scriptExists(DynamicHypnosisConfig config) async {
    final path = await getScriptPath(config);
    return File(path).exists();
  }

  /// Checks if audio exists for given config
  Future<bool> audioExists(DynamicHypnosisConfig config) async {
    final path = await getAudioPath(config);
    return File(path).exists();
  }

  /// Saves script to file
  Future<void> saveScript(DynamicHypnosisConfig config, String scriptText) async {
    final path = await getScriptPath(config);
    final file = File(path);
    await file.writeAsString(scriptText);
  }

  /// Loads script from file
  Future<String> loadScript(DynamicHypnosisConfig config) async {
    final path = await getScriptPath(config);
    final file = File(path);
    return await file.readAsString();
  }

  /// Saves audio bytes to file
  Future<void> saveAudio(DynamicHypnosisConfig config, List<int> audioBytes) async {
    final path = await getAudioPath(config);
    final file = File(path);
    await file.writeAsBytes(audioBytes);
  }

  /// Deletes cached files for a config
  Future<void> clearCache(DynamicHypnosisConfig config) async {
    final scriptPath = await getScriptPath(config);
    final audioPath = await getAudioPath(config);
    
    final scriptFile = File(scriptPath);
    final audioFile = File(audioPath);
    
    if (await scriptFile.exists()) {
      await scriptFile.delete();
    }
    
    if (await audioFile.exists()) {
      await audioFile.delete();
    }
  }

  /// Clears all cached hypnosis files
  Future<void> clearAllCache() async {
    final dir = await _getStorageDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Gets total cache size in bytes
  Future<int> getCacheSize() async {
    final dir = await _getStorageDirectory();
    if (!await dir.exists()) {
      return 0;
    }
    
    int totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }
  
  // ========== SUPABASE METHODS ==========
  
  /// Save dynamic hypnosis session to Supabase database and storage
  /// Returns the created session record with ID
  Future<DynamicHypnosisSession?> saveToSupabase({
    required DynamicHypnosisConfig config,
    required String participantId,
    String? sessionId,
    required String scriptText,
    required String localAudioPath,
  }) async {
    try {
      // 1. Upload audio to Supabase Storage
      final audioStoragePath = await _uploadAudioToStorage(
        participantId: participantId,
        sessionId: sessionId,
        localFilePath: localAudioPath,
        cacheKey: config.cacheKey,
      );

      if (audioStoragePath == null) {
        print('Failed to upload audio to storage');
        return null;
      }

      // 2. Create database record
      final session = DynamicHypnosisSession.fromConfig(
        config: config,
        participantId: participantId,
        sessionId: sessionId,
        scriptText: scriptText,
        audioStoragePath: audioStoragePath,
      );

      final response = await _supabase
          .from('dynamic_hypnosis_sessions')
          .insert(session.toInsertJson())
          .select()
          .single();

      return DynamicHypnosisSession.fromJson(response);
    } catch (e) {
      print('Error saving to Supabase: $e');
      return null;
    }
  }

  /// Save dynamic hypnosis session directly from audio bytes (no local file)
  /// This is faster as it skips writing to local storage first
  Future<DynamicHypnosisSession?> saveToSupabaseDirectly({
    required DynamicHypnosisConfig config,
    required String participantId,
    String? sessionId,
    required String scriptText,
    required List<int> audioBytes,
  }) async {
    try {
      // 1. Upload audio bytes directly to Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$participantId/${timestamp}_${config.cacheKey}.mp3';

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            Uint8List.fromList(audioBytes),
            fileOptions: const FileOptions(
              contentType: 'audio/mpeg',
            ),
          );

      print('Audio uploaded to storage: $storagePath');

      // 2. Create database record
      final session = DynamicHypnosisSession.fromConfig(
        config: config,
        participantId: participantId,
        sessionId: sessionId,
        scriptText: scriptText,
        audioStoragePath: storagePath,
      );

      final response = await _supabase
          .from('dynamic_hypnosis_sessions')
          .insert(session.toInsertJson())
          .select()
          .single();

      return DynamicHypnosisSession.fromJson(response);
    } catch (e) {
      print('Error saving to Supabase directly: $e');
      return null;
    }
  }

  /// Save only the script to Supabase (without audio) - for development/testing
  /// Audio can be generated and added later
  Future<DynamicHypnosisSession?> saveScriptOnly({
    required DynamicHypnosisConfig config,
    required String participantId,
    String? sessionId,
    required String scriptText,
  }) async {
    try {
      // Create database record without audio
      final session = DynamicHypnosisSession.fromConfig(
        config: config,
        participantId: participantId,
        sessionId: sessionId,
        scriptText: scriptText,
        audioStoragePath: null, // No audio yet
      );

      final response = await _supabase
          .from('dynamic_hypnosis_sessions')
          .insert(session.toInsertJson())
          .select()
          .single();

      print('Script saved to Supabase (no audio)');
      return DynamicHypnosisSession.fromJson(response);
    } catch (e) {
      print('Error saving script only: $e');
      return null;
    }
  }

  /// Upload audio file to Supabase Storage
  /// Returns storage path on success, null on failure
  Future<String?> _uploadAudioToStorage({
    required String participantId,
    String? sessionId,
    required String localFilePath,
    required String cacheKey,
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        print('Local audio file not found: $localFilePath');
        return null;
      }

      // Generate storage path: {participant_id}/{timestamp}_{cacheKey}.mp3
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$participantId/${timestamp}_$cacheKey.mp3';

      // Upload file
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(
              contentType: 'audio/mpeg',
            ),
          );

      print('Audio uploaded to storage: $storagePath');
      return storagePath;
    } catch (e) {
      print('Error uploading audio: $e');
      return null;
    }
  }

  /// Download audio from Supabase Storage to local cache
  /// Returns local file path on success, null on failure
  Future<String?> downloadAudioFromStorage({
    required String storagePath,
    required DynamicHypnosisConfig config,
  }) async {
    try {
      // Download audio bytes
      final bytes = await _supabase.storage
          .from(_bucketName)
          .download(storagePath);

      // Save to local cache
      final localPath = await getAudioPath(config);
      final file = File(localPath);
      await file.writeAsBytes(bytes);

      print('Audio downloaded from storage: $storagePath -> $localPath');
      return localPath;
    } catch (e) {
      print('Error downloading audio: $e');
      return null;
    }
  }

  /// Load dynamic hypnosis session from Supabase by session ID
  Future<DynamicHypnosisSession?> loadFromSupabaseBySession(String sessionId) async {
    try {
      final response = await _supabase
          .from('dynamic_hypnosis_sessions')
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return DynamicHypnosisSession.fromJson(response);
    } catch (e) {
      print('Error loading from Supabase: $e');
      return null;
    }
  }

  /// Load dynamic hypnosis session from Supabase by participant and config match
  Future<DynamicHypnosisSession?> loadFromSupabaseByConfig({
    required String participantId,
    required DynamicHypnosisConfig config,
  }) async {
    try {
      // Find session with matching character and goal
      final response = await _supabase
          .from('dynamic_hypnosis_sessions')
          .select()
          .eq('participant_id', participantId)
          .eq('character_choice', config.characterChoice)
          .eq('goal', config.goal)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return DynamicHypnosisSession.fromJson(response);
    } catch (e) {
      print('Error loading from Supabase: $e');
      return null;
    }
  }

  /// Get all dynamic hypnosis sessions for a participant
  Future<List<DynamicHypnosisSession>> getAllForParticipant(String participantId) async {
    try {
      final response = await _supabase
          .from('dynamic_hypnosis_sessions')
          .select()
          .eq('participant_id', participantId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DynamicHypnosisSession.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching sessions: $e');
      return [];
    }
  }

  /// Count FREE post-study dynamic hypnosis sessions for a participant
  /// Only counts sessions where session_id is null (not linked to study nights)
  Future<int> getSessionCount(String participantId) async {
    try {
      final response = await _supabase
          .from('dynamic_hypnosis_sessions')
          .select('id')
          .eq('participant_id', participantId)
          .isFilter('session_id', null);

      return (response as List).length;
    } catch (e) {
      print('Error counting sessions: $e');
      return 0;
    }
  }

  /// Link a nightly session to a dynamic hypnosis session
  /// This updates the session_id field in the dynamic_hypnosis_sessions table
  Future<void> linkNightlySession({
    required String participantId,
    required String nightlySessionId,
  }) async {
    try {
      // Find the participant's dynamic hypnosis session and update session_id
      await _supabase
          .from('dynamic_hypnosis_sessions')
          .update({'session_id': nightlySessionId})
          .eq('participant_id', participantId)
          .isFilter('session_id', null); // Only update if session_id is not already set
      
      print('Linked nightly session $nightlySessionId to dynamic hypnosis session');
    } catch (e) {
      print('Error linking session: $e');
    }
  }
}
