import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class WebSocketVoiceService {
  static const String baseUrl = ApiService.baseUrl;
  
  WebSocketChannel? _channel;
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  
  bool _isRecording = false;
  bool _isConnected = false;
  bool _isMuted = false;
  String? _agentId;
  
  // Audio processing
  bool _isPlaying = false;
  StreamSubscription? _recordingSubscription;
  StreamController<Uint8List>? _recordingStreamController;
  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>.broadcast();
  bool _playerInitialized = false;
  
  // Streams for callbacks
  final _connectionController = StreamController<bool>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();
  
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  
  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;
  bool get isMuted => _isMuted;

  void setMuted(bool muted) {
    _isMuted = muted;
  }

  Future<void> connect(String agentId) async {
    if (_isConnected) {
      await disconnect();
    }
    
    _agentId = agentId;
    
    try {
      // Initialize Flutter Sound
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();
      
      await _recorder!.openRecorder();
      await _player!.openPlayer();
      
      // Start player in streaming mode for PCM16
      await _player!.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        bufferSize: 4096,
        interleaved: true,
      );
      
      _playerInitialized = true;
      
      // Build WebSocket URL with auth token if available
      final wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      
      // Get auth token
      final session = SupabaseService().client.auth.currentSession;
      String? token = session?.accessToken;
      
      // Build URI with agent_id and optional token
      final uriBuilder = Uri.parse('$wsUrl/api/call/web-media-stream');
      final uri = uriBuilder.replace(queryParameters: {
        'agent_id': agentId,
        if (token != null) 'token': token,
      });
      
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleClose,
        cancelOnError: false,
      );
      
      _isConnected = true;
      _connectionController.add(true);
      
      // Start recording and sending audio
      await _startRecording();
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      throw Exception('Failed to connect: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _recorder == null) return;
    
    try {
      // Request permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('Microphone permission denied');
        return;
      }
      
      // Create a stream controller to receive audio data
      _recordingStreamController = StreamController<Uint8List>.broadcast();
      
      // Start recording with streaming - pass the sink
      await _recorder!.startRecorder(
        toStream: _recordingStreamController!.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
      );
      
      _isRecording = true;
      
      // Listen to the audio stream and send to WebSocket
      _recordingSubscription = _recordingStreamController!.stream.listen((buffer) {
        if (_channel != null && _channel!.closeCode == null && buffer.isNotEmpty && !_isMuted) {
          // Send PCM16 audio data directly to WebSocket (only if not muted)
          _channel!.sink.add(buffer);
          
          // Calculate amplitude for visualization
          final pcmData = buffer as Uint8List;
          double amplitude = 0.0;
          if (pcmData.length >= 2) {
            // Calculate RMS amplitude from PCM16 samples
            int sum = 0;
            for (int i = 0; i < pcmData.length - 1; i += 2) {
              int sample = (pcmData[i] | (pcmData[i + 1] << 8));
              if (sample > 32767) sample -= 65536; // Convert to signed
              sum += (sample * sample);
            }
            amplitude = sum / (pcmData.length / 2);
            amplitude = (amplitude / (32768 * 32768)).clamp(0.0, 1.0);
            
            // If user is speaking (detected by amplitude), stop current playback (interruption)
            if (amplitude > 0.01 && _isPlaying) {
              _stopCurrentPlayback();
            }
          }
          
          _amplitudeController.add(amplitude);
        }
      }, onError: (error) {
        print('Recording stream error: $error');
      });
    } catch (e) {
      print('Recording error: $e');
    }
  }

  void _handleMessage(dynamic message) {
    if (message is String) {
      // Handle JSON or string messages
      if (message.startsWith('{') || message.startsWith('[')) {
        try {
          final data = json.decode(message);
          // Backend may send either event_type or event
          final eventType = data['event_type'] ?? data['event'];
          if (eventType == 'start_media_streaming') {
            // Connection established
            print('Media streaming started');
            return;
          } else if (eventType == 'clear' || eventType == 'stop' || eventType == 'stop_speaking') {
            // Explicit interruption command from backend
            _interruptPlayback();
            return;
          }
        } catch (e) {
          // Not JSON, continue
        }
      } else if (message == 'stop' || message == 'clear') {
        // Handle stop message (interruption)
        _interruptPlayback();
        return;
      }
    } else if (message is List<int> || message is List) {
      // Handle binary audio data (PCM16)
      final bytes = message is List<int> 
          ? Uint8List.fromList(message) 
          : Uint8List.fromList((message as List).cast<int>());
      _playAudioChunk(bytes);
    } else if (message is Uint8List) {
      _playAudioChunk(message);
    } else {
      // Try to convert other formats
      try {
        if (message is ByteBuffer) {
          _playAudioChunk(Uint8List.view(message));
        } else if (message is TypedData) {
          _playAudioChunk(message.buffer.asUint8List());
        }
      } catch (e) {
        print('Error handling message: $e');
      }
    }
  }

  void _playAudioChunk(Uint8List audioData) {
    try {
      if (audioData.isEmpty || !_playerInitialized || _player == null || _player!.foodSink == null) return;
      
      // Feed PCM16 data directly to the player stream using FoodData
      _player!.foodSink!.add(FoodData(audioData));
      _isPlaying = true;
    } catch (e) {
      print('Error playing audio chunk: $e');
    }
  }

  // Fully interrupt playback and clear any residual buffered audio by restarting the stream player
  Future<void> _interruptPlayback() async {
    try {
      if (_player != null && _playerInitialized) {
        await _player!.stopPlayer();
        _isPlaying = false;
        // Restart streaming player immediately to accept new chunks
        await _player!.startPlayerFromStream(
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 16000,
          bufferSize: 4096,
          interleaved: true,
        );
      }
    } catch (e) {
      print('Error interrupting playback: $e');
    }
  }

  void _stopCurrentPlayback() {
    try {
      // Just clear the playback flag - don't stop the player as it's streaming
      _isPlaying = false;
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _handleClose() {
    print('WebSocket closed');
    _isConnected = false;
    _connectionController.add(false);
  }

  Future<void> disconnect() async {
    _stopCurrentPlayback();
    
    if (_isRecording && _recorder != null) {
      await _recordingSubscription?.cancel();
      await _recorder!.stopRecorder();
      await _recordingStreamController?.close();
      _recordingStreamController = null;
      _isRecording = false;
    }
    
    if (_playerInitialized && _player != null) {
      await _player!.stopPlayer();
      _playerInitialized = false;
    }
    
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  Future<void> stop() async {
    await disconnect();
  }

  void dispose() {
    disconnect();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _audioStreamController.close();
    _connectionController.close();
    _amplitudeController.close();
  }
}
