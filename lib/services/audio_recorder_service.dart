import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  Timer? _amplitudeTimer;
  bool _isRecording = false;

  Stream<double> get amplitudeStream => _amplitudeController.stream;
  bool get isRecording => _isRecording;

  Future<bool> ensureMicPermission() async {
    if (kIsWeb) {
      // On web, calling hasPermission triggers browser prompt if not granted
      try {
        return await _audioRecorder.hasPermission();
      } catch (_) {
        return false;
      }
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<bool> startRecording() async {
    try {
      if (_isRecording) {
        return true;
      }

      final hasPermission = await ensureMicPermission();
      if (!hasPermission) {
        return false;
      }

      final canRecord = await _audioRecorder.hasPermission();
      if (!canRecord) {
        return false;
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: '', // Empty string means stream only, no file saved
      );

      _isRecording = true;

      // Start monitoring amplitude
      _amplitudeTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) async {
          final amplitude = await _audioRecorder.getAmplitude();
          if (amplitude.current != double.negativeInfinity) {
            // Normalize amplitude to 0-1 range
            // dB range is typically -40 to 0, so we map it
            final normalizedAmplitude = ((amplitude.current + 40) / 40)
                .clamp(0.0, 1.0);
            _amplitudeController.add(normalizedAmplitude);
          } else {
            _amplitudeController.add(0.0);
          }
        },
      );

      return true;
    } catch (e) {
      // Log error - in production, use a proper logging system
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  Future<void> stopRecording() async {
    try {
      if (!_isRecording) {
        return;
      }

      _amplitudeTimer?.cancel();
      _amplitudeTimer = null;

      await _audioRecorder.stop();
      _isRecording = false;

      _amplitudeController.add(0.0);
    } catch (e) {
      // Log error - in production, use a proper logging system
      debugPrint('Error stopping recording: $e');
    }
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _audioRecorder.dispose();
    _amplitudeController.close();
  }
}

