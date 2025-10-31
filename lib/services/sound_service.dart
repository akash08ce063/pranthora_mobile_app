import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  Future<void> playCallStart() async {
    // Play haptic feedback and visual feedback
    await HapticFeedback.lightImpact();
  }

  Future<void> playCallEnd() async {
    // Play stronger haptic feedback for call end
    await HapticFeedback.mediumImpact();
  }
}

