import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../config/theme.dart';

/// UI shown while sleep tracking is active
class SleepingUI extends StatefulWidget {
  final DateTime startTime;
  final VoidCallback onAwaken;
  final bool isAudioPlaying;
  final bool isHypnosisSession; // Whether this is an audio hypnosis session
  final bool isAudioCompleted; // Whether audio has finished playing
  final VoidCallback? onPauseAudio;
  final VoidCallback? onResumeAudio;
  final VoidCallback? onRestartAudio;

  const SleepingUI({
    super.key,
    required this.startTime,
    required this.onAwaken,
    this.isAudioPlaying = false,
    this.isHypnosisSession = false,
    this.isAudioCompleted = false,
    this.onPauseAudio,
    this.onResumeAudio,
    this.onRestartAudio,
  });

  @override
  State<SleepingUI> createState() => _SleepingUIState();
}

class _SleepingUIState extends State<SleepingUI>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    
    // Update elapsed time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
    });

    // Breathing animation (4 seconds in, 4 seconds out)
    _breathingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Main status text
              Text(
                widget.isHypnosisSession ? 'Hypnosis Session' : 'Sleeping...',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 2,
                ),
              ),
              
              // Volume reminder for hypnosis sessions only
              if (widget.isHypnosisSession) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: AppTheme.primaryPurple.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Turn up volume to hear the audio',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Sleep instructions for all sessions
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'You may go to sleep for the night. Please ensure you place your phone ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Screen On, Face Down.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "When you wake up in the morning, please remember to press the 'I'm Awake' button to stop sleep tracking.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Breathing animation circle
              Center(
                child: AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathingAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryPurple.withOpacity(0.3),
                              AppTheme.primaryPurple.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.nightlight_round,
                            size: 50,
                            color: AppTheme.primaryPurple.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Time elapsed
              Text(
                _formatDuration(_elapsed),
                style: GoogleFonts.robotoMono(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 4,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Sleep tracking active',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Audio controls with labels (if audio callbacks are provided)
              if (widget.onPauseAudio != null && widget.onResumeAudio != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Replay button with label
                    if (widget.onRestartAudio != null)
                      Column(
                        children: [
                          GestureDetector(
                            onTap: widget.onRestartAudio,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.replay,
                                color: Colors.white.withOpacity(0.7),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Replay',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    
                    if (widget.onRestartAudio != null)
                      const SizedBox(width: 24),
                    
                    // Play/Pause button with label
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (widget.isAudioPlaying) {
                              widget.onPauseAudio?.call();
                            } else {
                              widget.onResumeAudio?.call();
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryPurple.withOpacity(0.2),
                              border: Border.all(
                                color: AppTheme.primaryPurple.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              widget.isAudioPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppTheme.primaryPurple,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isAudioPlaying ? 'Pause' : 'Resume',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              
              const SizedBox(height: 32),
              
              // Awaken button - always visible and enabled
              // Prompt message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Tap 'I'm Awake' when you wake up",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.onAwaken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppTheme.primaryPurple.withOpacity(0.5),
                    ),
                    child: Text(
                      "I'm Awake",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
