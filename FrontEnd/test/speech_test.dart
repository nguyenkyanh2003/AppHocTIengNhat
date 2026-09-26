import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/audio/speech_service.dart';
import 'package:apphoctiengnnhat/core/audio/speech_voice.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/study/study_vocabulary_step.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';

const _tts = MethodChannel('flutter_tts');

/// Giả kênh flutter_tts: ghi lại lệnh gọi, trả lời "có giọng tiếng Nhật" theo cờ.
List<MethodCall> _fakeTts({required bool hasJapanese}) {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, (call) async {
    calls.add(call);
    return call.method == 'isLanguageAvailable' ? hasJapanese : 1;
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_tts, null));
  return calls;
}

Widget _card() => MaterialApp(
      home: Scaffold(
        body: StudyVocabularyStep(
          words: [
            Vocabulary.fromJson({'_id': 'w1', 'word': '野菜', 'hiragana': 'やさい', 'meaning': 'rau củ'}),
          ],
          isLearned: (_) => false,
          isSaving: (_) => false,
          onMarkLearned: (_) async {},
          onUnmarkLearned: (_) async {},
        ),
      ),
    );

void main() {
  group('chọn giọng tiếng Nhật', () {
    test('ưu tiên giọng cài trên máy hơn giọng trực tuyến', () {
      final voices = [
        (lang: 'en-US', isLocal: true),
        (lang: 'ja-JP', isLocal: false),
        (lang: 'ja-JP', isLocal: true),
      ];
      expect(pickJapaneseVoice(voices), 2);
    });

    test('không có giọng máy thì lấy giọng trực tuyến; nhận cả ja_JP và ja', () {
      expect(pickJapaneseVoice([(lang: 'vi-VN', isLocal: true), (lang: 'ja_JP', isLocal: false)]), 1);
      expect(pickJapaneseVoice([(lang: 'ja', isLocal: false)]), 0);
    });

    test('không có giọng tiếng Nhật thì trả null — kể cả khi danh sách giọng chưa tải', () {
      expect(pickJapaneseVoice([(lang: 'vi-VN', isLocal: true), (lang: 'jv-ID', isLocal: true)]), isNull);
      expect(pickJapaneseVoice([]), isNull);
    });
  });

  test('chú thích trong cách đọc bị bỏ trước khi đọc', () {
    expect(SpeechService.cleanForSpeech('すいます(たばこを~)'), 'すいます');
    expect(SpeechService.cleanForSpeech('じょうず[な]'), 'じょうず');
  });

  testWidgets('bấm nghe phát âm thì đọc cách đọc của từ bằng giọng ja-JP', (tester) async {
    final calls = _fakeTts(hasJapanese: true);
    await tester.pumpWidget(_card());

    await tester.tap(find.byTooltip('Nghe phát âm'));
    await tester.pumpAndSettle();

    expect(calls.where((c) => c.method == 'setLanguage').single.arguments, 'ja-JP');
    expect(calls.where((c) => c.method == 'speak').single.arguments, 'やさい');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('thiết bị không có giọng tiếng Nhật thì báo rõ, không im lặng', (tester) async {
    final calls = _fakeTts(hasJapanese: false);
    await tester.pumpWidget(_card());

    await tester.tap(find.byTooltip('Nghe phát âm'));
    await tester.pumpAndSettle();

    expect(calls.where((c) => c.method == 'speak'), isEmpty);
    expect(find.textContaining('chưa có giọng đọc tiếng Nhật'), findsOneWidget);
  });
}
