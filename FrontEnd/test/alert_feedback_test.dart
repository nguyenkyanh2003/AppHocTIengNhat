import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/settings/models/user_settings.dart';
import 'package:apphoctiengnnhat/features/settings/services/alert_feedback.dart';

void main() {
  late List<String> done;
  late AlertFeedback feedback;

  setUp(() {
    done = [];
    feedback = AlertFeedback(
      playSound: () async => done.add('âm báo'),
      vibrate: () async => done.add('rung'),
    );
  });

  test('bật đủ: phát âm báo và rung', () async {
    await feedback.alert(const UserSettings());
    expect(done, ['âm báo', 'rung']);
  });

  test('mỗi công tắc chỉ tắt đúng phần của nó', () async {
    await feedback.alert(const UserSettings(soundEnabled: false));
    await feedback.alert(const UserSettings(vibrateEnabled: false));
    expect(done, ['rung', 'âm báo']);
  });

  test('tắt "Nhận thông báo" thì im lặng hẳn, dù âm thanh và rung còn bật', () async {
    await feedback.alert(const UserSettings(notificationsEnabled: false));
    expect(done, isEmpty);
  });

  test('máy không phát được tiếng (không có loa, trình duyệt chặn) thì vẫn rung, không ném lỗi', () async {
    final silent = AlertFeedback(
      playSound: () async => throw Exception('NotAllowedError'),
      vibrate: () async => done.add('rung'),
    );

    await silent.alert(const UserSettings());
    expect(done, ['rung']);
  });
}
