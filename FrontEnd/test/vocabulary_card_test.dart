import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/vocabulary/models/vocabulary.dart';
import 'package:apphoctiengnnhat/features/vocabulary/widgets/vocabulary_card.dart';

void main() {
  testWidgets('từ chưa có file âm thanh vẫn có nút Phát âm (đọc bằng giọng máy)', (tester) async {
    // Dữ liệu thật chưa từ nào có `audio_url`: ẩn nút theo file thì cả danh sách
    // không nghe được từ nào, dù `pronounce` vẫn đọc được bằng giọng máy.
    var played = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: VocabularyCard(
          vocabulary: Vocabulary(id: 'v1', word: '学校', hiragana: 'がっこう', meaning: 'trường học'),
          onPlayAudio: () => played++,
        ),
      ),
    ));

    await tester.tap(find.byTooltip('Phát âm'));

    expect(played, 1);
  });
}
