import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/glow_button.dart';
import '../services/audio_recorder_service.dart';
import '../services/sound_service.dart';
import '../services/websocket_voice_service.dart';

enum CallState {
  welcome,
  connecting,
  active,
  ending,
}

class CallingScreen extends StatefulWidget {
  final String? agentName;
  final String? agentDescription;
  final String? agentId;
  final bool returnToAgents;
  
  const CallingScreen({
    super.key,
    this.agentName,
    this.agentDescription,
    this.agentId,
    this.returnToAgents = false,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final AudioRecorderService _audioService = AudioRecorderService();
  final SoundService _soundService = SoundService();
  final WebSocketVoiceService _voiceService = WebSocketVoiceService();
  CallState _callState = CallState.welcome;
  double _audioAmplitude = 0.0;
  DateTime? _callStartTime;
  String _callDuration = '00:00';
  Timer? _durationTimer;
  StreamSubscription? _amplitudeSubscription;
  bool _isPressed = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    
    // Listen to WebSocket connection and amplitude streams
    _voiceService.connectionStream.listen((connected) {
      if (mounted && connected && _callState == CallState.connecting) {
        setState(() {
          _callState = CallState.active;
        });
      }
    });
    
    _voiceService.amplitudeStream.listen((amplitude) {
      if (mounted) {
        setState(() {
          _audioAmplitude = amplitude;
        });
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioService.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  void _showFloatingSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF4444), // bright red font
                fontWeight: FontWeight.w400, // thinner font
                fontSize: 13, // smaller font size
              ),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0x33FF4444), // less opacity red background (20%)
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          animation: CurvedAnimation(
            parent: kAlwaysDismissedAnimation,
            curve: Curves.easeOutBack, // fallback, do not affect position
          ),
          // For "animated from bottom to top", use `showSnackBar` as usual: on ScaffoldMessenger it animates from bottom up
        ),
      );
  }

  Future<void> _showOpenSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text(
            'Microphone Permission Required',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Please grant microphone access in Settings to start a call.',
            style: TextStyle(color: Color(0xFFCCCCCC)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startCall() async {
    // Check if agent ID is available
    if (widget.agentId == null || widget.agentId!.isEmpty) {
      _showFloatingSnack('Agent ID is required');
      return;
    }
    
    // Play call start sound
    await _soundService.playCallStart();
    
    // Proactively request permission and handle permanently denied case
    final currentStatus = await Permission.microphone.status;
    if (currentStatus.isPermanentlyDenied) {
      await _showOpenSettingsDialog();
      return;
    }

    // Ensure permission (this will trigger the system popup if needed)
    final allowed = await _audioService.ensureMicPermission();
    if (!allowed) {
      _showFloatingSnack('Please allow microphone access to start the call');
      return;
    }

    // Show connecting state
    setState(() {
      _callState = CallState.connecting;
    });

    try {
      // Connect to WebSocket for real-time voice communication
      await _voiceService.connect(widget.agentId!);
      
      // Start call timer
      _callStartTime = DateTime.now();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _callStartTime != null) {
          final duration = DateTime.now().difference(_callStartTime!);
          setState(() {
            _callDuration =
                '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
          });
        }
      });

      // Connection will be established asynchronously
      // State will change to active when connection stream emits true
    } catch (e) {
      // Failed to connect
      if (mounted) {
        setState(() {
          _callState = CallState.welcome;
        });
        _showFloatingSnack('Failed to connect: ${e.toString()}');
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _voiceService.setMuted(_isMuted);
  }

  Future<void> _endCall() async {
    // Play call end sound
    await _soundService.playCallEnd();
    
    // Disconnect WebSocket and stop all audio
    await _voiceService.disconnect();
    
    _durationTimer?.cancel();

    // Show ending state with duration
    setState(() {
      _callState = CallState.ending;
    });

    // Wait 2 seconds showing call duration
    await Future.delayed(const Duration(seconds: 2));

    // If returnToAgents is true, pop back to agents screen
    if (widget.returnToAgents && mounted) {
      Navigator.of(context).pop();
      return;
    }

    // Reset to welcome state (original behavior)
    setState(() {
      _callState = CallState.welcome;
      _audioAmplitude = 0.0;
      _callStartTime = null;
      _callDuration = '00:00';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildBodyForState(),
        ),
      ),
    );
  }

  Widget _buildBodyForState() {
    switch (_callState) {
      case CallState.welcome:
        return _buildWelcomeState();
      case CallState.connecting:
        return _buildConnectingState();
      case CallState.active:
        return _buildActiveCallState();
      case CallState.ending:
        return _buildEndingState();
    }
  }

  Widget _buildWelcomeState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          const SizedBox(height: 60),
          // Welcome message
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Talk with',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFCCCCCC),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          widget.agentName ?? 'Agent',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x331C84FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0x330A84FF),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Ready to connect',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64D2FF),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Spacer(),
         
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              widget.agentDescription ?? widget.agentName ?? 'AI Assistant',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
          const Spacer(),
          // Start Call Button
          GlowButton(
            onPressed: _startCall,
            icon: Icons.record_voice_over, // Use a voice related icon
            label: 'Talk Now',
            size: 80,
            color: Colors.white,
            glowColor: const Color(0xFF0A84FF),
            isGlowing: true,
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildConnectingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Animated connecting indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E1E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1 * value),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Connecting...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Setting up audio',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCallState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Status text - centered
          Center(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: const Text(
                'Listening...',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
          // Audio Visualizer
          CircularAudioVisualizer(
            amplitude: _audioAmplitude,
            size: 240,
            color: Colors.white,
          ),
          const SizedBox(height: 30),
          // Animated Name with typewriter
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                widget.agentName ?? 'AI Assistant',
                textStyle: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                cursor: '|',
                speed: const Duration(milliseconds: 100),
              ),
            ],
            totalRepeatCount: 1,
            isRepeatingAnimation: false,
            displayFullTextOnTap: false,
            stopPauseOnTap: false,
          ),
          const SizedBox(height: 12),
          // Call duration - centered
          Center(
            child: Text(
              _callDuration,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          // Bottom controls - mute and end call buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute/Unmute button
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  onPressed: _toggleMute,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  iconColor: Colors.white,
                  size: 60,
                  iconSize: 28,
                  showShadow: false,
                ),
                const SizedBox(width: 20),
                // End call button
                _buildControlButton(
                  icon: Icons.call_end,
                  onPressed: _endCall,
                  backgroundColor: const Color(0xFFFF3B30),
                  size: 70,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Call ended icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E1E),
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.call_end,
                size: 40,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Call Ended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: $_callDuration',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    Color iconColor = Colors.white,
    double size = 56,
    double iconSize = 24,
    bool showShadow = true,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: showShadow ? [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
