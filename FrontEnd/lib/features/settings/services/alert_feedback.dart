import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/user_settings.dart';

/// Âm báo và rung đi kèm mỗi lần app báo một tin mới (huy hiệu, nhắc học,
/// thông báo mới), theo ba công tắc trong Cài đặt thông báo.
///
/// Không phát được tiếng (máy không có loa, trình duyệt chặn tự phát) thì bỏ
/// qua: tin vẫn hiện trên màn, âm báo chỉ là phần thêm, không đáng làm hỏng nó.
class AlertFeedback {
  AlertFeedback({Future<void> Function()? playSound, Future<void> Function()? vibrate})
      : _playSound = playSound ?? _playChime,
        _vibrate = vibrate ?? HapticFeedback.vibrate;

  final Future<void> Function() _playSound;
  final Future<void> Function() _vibrate;

  Future<void> alert(UserSettings settings) async {
    if (!settings.notificationsEnabled) return;
    if (settings.soundEnabled) {
      try {
        await _playSound();
      } catch (error) {
        debugPrint('Không phát được âm báo: $error');
      }
    }
    if (settings.vibrateEnabled) await _vibrate();
  }

  static Future<AudioPlayer>? _player;

  /// Một tiếng chuông ngắn (`assets/sounds/notification.wav`).
  static Future<void> _playChime() async {
    final player = await (_player ??= _createPlayer());
    await player.stop();
    await player.play(AssetSource('sounds/notification.wav'));
  }

  /// Tôn trọng chế độ im lặng của máy, và chỉ hạ nhỏ (không dừng) nhạc đang
  /// phát của ứng dụng khác.
  static Future<AudioPlayer> _createPlayer() async {
    final player = AudioPlayer();
    await player.setAudioContext(AudioContextConfig(respectSilence: true, focus: AudioContextConfigFocus.duckOthers).build());
    return player;
  }
}
