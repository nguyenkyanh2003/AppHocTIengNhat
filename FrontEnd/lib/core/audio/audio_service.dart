import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingUrl;
  bool _isPlaying = false;
  final List<VoidCallback> _onCompleteListeners = [];

  bool get isPlaying => _isPlaying;
  String? get currentPlayingUrl => _currentPlayingUrl;

  void addOnCompleteListener(VoidCallback listener) {
    _onCompleteListeners.add(listener);
  }

  void removeOnCompleteListener(VoidCallback listener) {
    _onCompleteListeners.remove(listener);
  }

  /// Play audio from URL
  Future<void> playAudio(String audioUrl) async {
    try {
      // If same audio is playing, stop it
      if (_currentPlayingUrl == audioUrl && _isPlaying) {
        await stopAudio();
        return;
      }

      // Stop any currently playing audio
      if (_isPlaying) {
        await stopAudio();
      }

      // Convert relative URL to absolute URL if needed
      final fileHost = ApiClient.baseUrl.replaceFirst('/api', '');
      final url = audioUrl.startsWith('http') ? audioUrl : '$fileHost$audioUrl';

      debugPrint('🔊 Playing audio: $url');

      _currentPlayingUrl = audioUrl;
      _isPlaying = true;

      await _audioPlayer.play(UrlSource(url));

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
        _currentPlayingUrl = null;
        for (final listener in List<VoidCallback>.from(_onCompleteListeners)) {
          listener();
        }
      });
    } catch (e) {
      debugPrint('❌ Error playing audio: $e');
      _isPlaying = false;
      _currentPlayingUrl = null;
      rethrow;
    }
  }

  /// Stop currently playing audio
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentPlayingUrl = null;
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Pause audio
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  /// Resume audio
  Future<void> resumeAudio() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  /// Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
