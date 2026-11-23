import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/study_groups/models/study_group.dart';
import 'package:apphoctiengnnhat/features/study_groups/widgets/group_edit_dialog.dart';

void main() {
  testWidgets('ô đổi ảnh nhóm là một nút có nhãn, không chỉ là hình bấm được', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showGroupEditDialog(context, const StudyGroup(id: 'g1', name: 'Nhóm N5', creatorId: 'u1')),
          child: const Text('Sửa'),
        ),
      ),
    ));
    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Đổi ảnh nhóm'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('Đổi ảnh nhóm')),
      containsSemantics(tooltip: 'Đổi ảnh nhóm', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });
}
