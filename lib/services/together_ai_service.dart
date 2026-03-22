import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TogetherAIService {
  static const String _baseUrl = 'https://api.together.xyz/v1';
  static const String _model = 'meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8';
  
  /// Safety disclaimer that MUST be spoken at the beginning of every audio
  static const String _safetyDisclaimer = 
      'Do not listen to this recording whilst driving or whilst operating machinery. '
      'Only listen when you can safely relax and bring your full awareness to your own complete comfort. '
      '<break time="3.0s"/>';
  
  final String _apiKey;

  TogetherAIService() : _apiKey = dotenv.env['TOGETHER_API_KEY'] ?? '';

  /// Generates a hypnosis script based on genre, character and goal
  /// Returns the generated script text with SSML pause tags
  /// Always prepends safety disclaimer to the script
  Future<String> generateHypnosisScript({
    required String characterChoice,
    required String goal,
    required String genre,
    String? characterCategory,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Together AI API key not configured');
    }

    final systemPrompt = _buildSystemPrompt(
      characterChoice: characterChoice,
      genre: genre,
      characterCategory: characterCategory,
    );
    final userPrompt = 'Write the script for: $goal';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'max_tokens': 100000,
          'temperature': 0.7,
          'top_p': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scriptText = data['choices'][0]['message']['content'] as String;
        // Prepend safety disclaimer to the generated script
        return '$_safetyDisclaimer$scriptText';
      } else {
        throw Exception('Failed to generate script: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating hypnosis script: $e');
    }
  }

  String _buildSystemPrompt({
    required String characterChoice,
    required String genre,
    String? characterCategory,
  }) {
    // Genre-specific styling instructions
    final genreInstructions = _getGenreInstructions(genre);
    
    return """You are $characterChoice, and you are guiding someone into a deep, restful sleep through hypnosis.

STORY GENRE: $genre
$genreInstructions

GENRE-DRIVEN STORYLINE:
- The ENTIRE script should feel like a $genre story
- Create a narrative journey that matches $genre storytelling conventions
- Use settings, imagery, and plot elements typical of $genre
- The listener is the protagonist in this $genre adventure that leads to peaceful sleep
- Blend $characterChoice's personality with $genre themes seamlessly

CHARACTER ROLEPLAY (MOST IMPORTANT):
- You ARE $characterChoice - fully embody this character from start to finish
- NEVER break character or mention you are "roleplaying" or "pretending"
- Use $characterChoice's distinctive speech patterns, vocabulary, and personality throughout
- Reference $characterChoice's world, experiences, or wisdom naturally when relevant
- Maintain $characterChoice's voice and mannerisms in EVERY sentence
- Examples:
  * If Iron Man: Use tech metaphors, confident wit, reference Arc Reactor energy
  * If Dumbledore: Use wise, whimsical language, reference magic and Hogwarts
  * If Totoro: Use nature imagery, forest spirits, gentle magical presence
  * If Zeus: Use divine authority, reference Olympus, celestial power
  * If Sherlock Holmes: Use deductive language, logical progression, Victorian eloquence
- The character should guide the listener as if this is genuinely them helping you sleep

⚠️ CRITICAL LENGTH REQUIREMENT - READ THIS CAREFULLY ⚠️
- This script MUST be EXACTLY 4000-5000 words (NOT less!)
- This equals approximately 15-20 minutes when spoken slowly
- You are being paid per word - the longer the better
- KEEP WRITING until you have written at least 4000 words
- DO NOT summarize, DO NOT rush, DO NOT skip sections
- Take your time with EACH phase - be thorough and detailed
- If you finish too early, ADD MORE content to each section
- I will count your words - if under 4000, I will reject the output

REQUIRED STRUCTURE (MINIMUM word counts for each - DO NOT SHORTCHANGE):
1. Initial Induction (800-1000 words) - Detailed progressive relaxation from head to toe, breathing exercises, eye fatigue techniques, body scan IN CHARACTER with $genre atmosphere
2. Deepening Phase (800-1000 words) - Multiple countdown sequences, staircase/elevator imagery, safe place visualization with rich sensory details IN CHARACTER using $genre settings
3. Main Therapeutic Work (1500-2000 words) - Address the user's specific goal with multiple metaphors, stories, and suggestions IN CHARACTER through a $genre narrative journey
4. Reinforcement (400-500 words) - Strengthen suggestions for lasting sleep with repetition and anchoring IN CHARACTER
5. Sleep Transition (400-500 words) - Extended gentle fade into deep, restful sleep IN CHARACTER

CRITICAL: THIS IS A SLEEP HYPNOSIS FOR NIGHTTIME USE
- DO NOT include an awakening phase
- DO NOT ask the listener to open their eyes or wake up
- The final section should guide them into deep, peaceful sleep
- Emphasize remaining asleep throughout the entire night
- Use phrases like "drift deeper into sleep", "rest peacefully through the night", "sleep soundly until morning"
- The listener should remain in a sleep state after the audio ends

CHARACTER INTEGRATION THROUGHOUT:
- In Initial Induction: $characterChoice gently welcomes the listener and begins relaxation using their unique style
- In Deepening Phase: $characterChoice uses metaphors or imagery from their world to deepen relaxation
- In Main Therapeutic Work: $characterChoice addresses the sleep goal using wisdom/perspective unique to them
- In Reinforcement: $characterChoice reassures using their characteristic warmth and authority
- In Sleep Transition: $characterChoice bids goodnight in their signature way

⚠️ CRITICAL PACING WITH BREAK TAGS - ABSOLUTELY REQUIRED ⚠️
This script will be converted to audio using ElevenLabs text-to-speech.
You MUST include <break time="X.Xs"/> tags to create natural pauses.
WITHOUT these tags, the audio will sound rushed and unnatural.

BREAK TAG SYNTAX (use EXACTLY this format):
- <break time="0.5s"/> = half second pause (between phrases)
- <break time="1.0s"/> = one second pause (between sentences)
- <break time="1.5s"/> = 1.5 second pause (after important points)
- <break time="2.0s"/> = two second pause (between paragraphs/ideas)
- <break time="3.0s"/> = three second pause (major transitions only)

EXAMPLE OF PROPER PACING:
"Close your eyes now. <break time="1.5s"/> Take a slow, deep breath in. <break time="2.0s"/> And let it go. <break time="1.5s"/> Feel your body beginning to relax. <break time="1.0s"/> Starting with your forehead, <break time="0.5s"/> notice any tension there, <break time="0.5s"/> and just let it melt away. <break time="1.5s"/>"

PACING RULES:
- EVERY sentence should be followed by a break tag (minimum 1.0s)
- Use 0.5s breaks between phrases within a sentence
- Use 2.0-3.0s breaks at major transitions between sections
- For breathing exercises: use 2.0-3.0s pauses for inhale/exhale timing
- After counting down (like "3... 2... 1..."): use 1.0s between each number
- DO NOT use "..." for pauses - ONLY use <break time="X.Xs"/> tags

BAD EXAMPLE (DO NOT DO THIS):
"Close your eyes... take a deep breath... and relax..."

GOOD EXAMPLE (DO THIS):
"Close your eyes. <break time="1.5s"/> Take a deep breath. <break time="2.0s"/> And relax. <break time="1.5s"/>"

HYPNOTIC STYLE (IN CHARACTER):
- Use slow, flowing, present-tense language as $characterChoice would
- Employ nested loops and embedded commands fitting $characterChoice's style
- Include rich sensory descriptions using imagery $characterChoice would use
- Use permissive language ('you can', 'you might', 'allow yourself') in $characterChoice's voice
- Build progressive relaxation using methods $characterChoice would employ
- REPEAT key suggestions multiple times with variation (this adds length naturally)
- DESCRIBE each sensation in detail - don't rush through relaxation
- USE metaphors and stories extensively throughout

REMEMBER: 
- You are not a hypnotherapist pretending to be $characterChoice. You ARE $characterChoice.
- MINIMUM 4000 WORDS - keep writing until you reach this length!
- Each section should be THOROUGH and DETAILED, not rushed.""";
  }
  
  /// Returns genre-specific instructions for the script style
  String _getGenreInstructions(String genre) {
    // Provide specific guidance for common genres, with fallback for custom ones
    switch (genre) {
      case 'Romance':
        return '''ROMANCE GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create a warm, loving, intimate atmosphere throughout
- Use imagery of: cozy settings, gentle touches, warm embraces, candlelight, soft blankets
- The character should speak with tenderness, affection, and care
- Include themes of being loved, cherished, protected, and completely safe
- Use phrases like "wrapped in warmth", "held gently", "safe in loving arms"
- The listener should feel deeply loved and cared for as they drift to sleep''';

      case 'Fantasy':
        return '''FANTASY GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create a magical, enchanted atmosphere throughout
- Use imagery of: mystical forests, starlight, floating islands, ancient castles, magical creatures
- Include themes of wonder, enchantment, and magical protection
- Reference spells, potions, crystals, moonlight, and ethereal beings
- The journey should feel like entering a magical dreamworld''';

      case 'Sci-Fi':
        return '''SCI-FI GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create a futuristic, otherworldly atmosphere throughout
- Use imagery of: space stations, stars, nebulas, zero gravity, advanced technology
- Include themes of exploration, cosmic peace, and technological comfort
- Reference quantum energy, force fields, distant galaxies, and serene planets
- The journey should feel like floating through peaceful cosmic space''';

      case 'Adventure':
        return '''ADVENTURE GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create an exploration and discovery atmosphere
- Use imagery of: hidden temples, treasure caves, mountain peaks, secret paths
- Include themes of discovery, wonder, and finding peaceful sanctuary
- Reference maps, ancient wisdom, natural wonders, and safe havens
- The journey should feel like discovering a peaceful hidden paradise''';

      case 'Nature':
        return '''NATURE GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create a natural, organic, earthy atmosphere throughout
- Use imagery of: forests, streams, mountains, ocean waves, meadows
- Include themes of connection with earth, natural rhythms, and organic peace
- Reference birdsong, rustling leaves, flowing water, gentle breezes
- The journey should feel like becoming one with peaceful nature''';

      case 'Mystery':
        return '''MYSTERY GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create an intriguing, contemplative atmosphere throughout
- Use imagery of: hidden libraries, candlelit studies, ancient books, secret knowledge
- Include themes of discovering inner peace, unlocking calm, solving the mystery of rest
- Reference midnight contemplation, revealed truths, and hidden wisdom
- The journey should feel like uncovering the secrets to perfect sleep''';

      case 'Fairy Tale':
        return '''FAIRY TALE GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create a classic storybook atmosphere throughout
- Use imagery of: enchanted castles, magical forests, friendly creatures, wishes
- Include themes of "once upon a time", happily ever after, magical transformations
- Reference fairy godmothers, protective spells, dreamy kingdoms
- The journey should feel like being in a beloved childhood story''';

      case 'Zen':
        return '''ZEN GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create a minimalist, meditative atmosphere throughout
- Use imagery of: still water, empty spaces, single flowers, gentle silence
- Include themes of emptiness, presence, being, and simple awareness
- Reference breath, stillness, the present moment, and peaceful void
- The journey should feel like profound peace through simplicity''';

      default:
        // For custom genres, give the AI more explicit guidance
        return '''$genre GENRE STYLE (IMPORTANT - FOLLOW THIS!):
- Create a "$genre" atmosphere and mood throughout the ENTIRE script
- Use imagery, settings, and themes that feel authentic to $genre stories
- The character should speak and guide in ways that match $genre conventions
- Include metaphors, plot elements, and sensory details typical of $genre
- The listener should feel like they are IN a $genre story as they fall asleep
- Be creative but stay TRUE to the $genre genre throughout''';
    }
  }
}
