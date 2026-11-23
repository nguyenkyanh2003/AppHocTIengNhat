import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/jlpt/widgets/jlpt_audio_bar.dart';

Future<List<String>> _pump(WidgetTester tester, {bool isPlaying = false, bool isLoading = false}) async {
  final calls = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: JlptAudioBar(
        audioPath: 'http://localhost:3000/uploads/nghe-1.mp3',
        audioName: 'nghe-1.mp3',
        isPlaying: isPlaying,
        isLoading: isLoading,
        duration: const Duration(seconds: 30),
        position: const Duration(seconds: 12),
        playAudio: (path, name) async => calls.add('play $name'),
        onSeek: (position) => calls.add('seek ${position.inSeconds}'),
      ),
    ),
  ));
  return calls;
}

void main() {
  testWidgets('nút phát là một nút có tên cho trình đọc màn hình', (tester) async {
    final semantics = tester.ensureSemantics();
    final calls = await _pump(tester);

    expect(
      tester.getSemantics(find.text('Phát audio')),
      containsSemantics(label: 'Phát audio', isButton: true, isEnabled: true, hasTapAction: true),
    );
    await tester.tap(find.text('Phát audio'));
    expect(calls, ['play nghe-1.mp3']);
    semantics.dispose();
  });

  testWidgets('đang phát thì nút thành Tạm dừng; đang tải thì nút tắt', (tester) async {
    await _pump(tester, isPlaying: true);
    expect(find.text('Tạm dừng'), findsOneWidget);

    final calls = await _pump(tester, isLoading: true);
    await tester.tap(find.text('Đang tải...'));
    expect(calls, isEmpty);
  });

  testWidgets('kéo thanh tiến độ thì tua tới đúng giây', (tester) async {
    final calls = await _pump(tester);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(20);

    expect(calls, ['seek 20']);
  });
}
