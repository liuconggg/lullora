import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/voice_option.dart';

class ElevenLabsService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';
  static const String _model = 'eleven_turbo_v2_5';
  
  final String _apiKey;

  ElevenLabsService() : _apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';

 
 

  /// Fetches available voices from ElevenLabs API
  /// If [filterForHypnotherapy] is true, prioritizes preferred hypnotherapy voices
  Future<List<VoiceOption>> getAvailableVoices({bool filterForHypnotherapy = false}) async {
    if (_apiKey.isEmpty) {
      throw Exception('ElevenLabs API key not configured');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/voices'),
        headers: {
          'xi-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var voices = (data['voices'] as List)
            .map((voice) => VoiceOption.fromJson(voice as Map<String, dynamic>))
            .toList();
        
        // Only include user's saved/custom voices (not library voices)
        // Categories: 'cloned', 'generated', 'professional' are user voices
        // 'premade' are library voices
        final userVoiceCategories = ['cloned', 'generated', 'professional'];
        voices = voices.where((v) {
          final category = v.category?.toLowerCase() ?? '';
          return userVoiceCategories.contains(category);
        }).toList();
        
        // Remove duplicates by name (keep first occurrence)
        final seenNames = <String>{};
        voices = voices.where((v) {
          if (seenNames.contains(v.name)) {
            return false;
          }
          seenNames.add(v.name);
          return true;
        }).toList();
        
        if (filterForHypnotherapy) {
          // First, get preferred voices in order
          final preferredVoices = <VoiceOption>[];
       
          // Then add other suitable voices
          final otherSuitable = voices
              .where((v) => v.isSuitableForHypnotherapy)
              .toList();
          
          voices = [...preferredVoices, ...otherSuitable];
          
          // If no suitable voices found, return all user voices as fallback
          if (voices.isEmpty) {
            voices = (data['voices'] as List)
                .map((voice) => VoiceOption.fromJson(voice as Map<String, dynamic>))
                .where((v) {
                  final category = v.category?.toLowerCase() ?? '';
                  return userVoiceCategories.contains(category);
                })
                .toList();
          }
        }
        
        return voices;
      } else {
        throw Exception('Failed to fetch voices: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching available voices: $e');
    }
  }

  /// Converts text to speech and returns audio bytes
  /// Uses streaming to handle large audio files
  Future<List<int>> textToSpeech({
    required String text,
    required String voiceId,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('ElevenLabs API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/text-to-speech/$voiceId'),
        headers: {
          'xi-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'model_id': _model,
          'voice_settings': {
            'stability': 1.0,            // Maximum stability for completely consistent voice
            'similarity_boost': 1.0,     // Maximum similarity to original voice
            'style': 0.0,                // Keep at 0 for consistent, non-varying delivery
            'use_speaker_boost': true,   // Enhances voice quality
          },
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to generate audio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating audio: $e');
    }
  }

  /// Converts text to speech and saves directly to file
  Future<void> textToSpeechToFile({
    required String text,
    required String voiceId,
    required String outputPath,
  }) async {
    final audioBytes = await textToSpeech(text: text, voiceId: voiceId);
    final file = File(outputPath);
    await file.writeAsBytes(audioBytes);
  }
}