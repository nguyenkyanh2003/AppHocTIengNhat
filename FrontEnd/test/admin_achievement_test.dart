import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_achievement.dart';
import 'package:apphoctiengnnhat/features/admin/providers/admin_provider.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_achievement_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/admin_achievement_card.dart';

AdminAchievement _badge({
  String id = 'a1',
  String name = 'First Words',
  String nameVi = 'Những Từ Đầu Tiên',
  int unlocked = 4,
  bool active = true,
}) =>
    AdminAchievement.fromJson({
      '_id': id,
      'name': name,
      'name_vi': nameVi,
      'description': 'Learn 10 words',
      'description_vi': 'Học 10 từ vựng',
      'icon': '📚',
      'category': 'vocabulary',
      'requirement_type': 'count',
      'requirement_value': 10,
      'xp_reward': 50,
      'rarity': 'legendary',
      'is_active': active,
      'unlocked': unlocked,
    });

class _FakeAdminService extends AdminService {
  _FakeAdminService(this.list);

  final List<AdminAchievement> list;
  final created = <Map<String, dynamic>>[];
  final updated = <String, Map<String, dynamic>>{};
  final deleted = <String>[];
  Exception? failure;

  @override
  Future<List<AdminAchievement>> getAchievements() async => list;

  @override
  Future<void> createAchievement(AchievementDraft draft) async {
    if (failure != null) throw failure!;
    created.add(draft.toJson());
  }

  @override
  Future<void> updateAchievement(String id, AchievementDraft draft) async {
    if (failure != null) throw failure!;
    updated[id] = draft.toJson();
  }

  @override
  Future<void> deleteAchievement(String id) async {
    if (failure != null) throw failure!;
    deleted.add(id);
  }
}

Future<_FakeAdminService> _pumpScreen(
  WidgetTester tester, {
  List<AdminAchievement>? list,
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _FakeAdminService(list ?? [_badge()]);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AdminProvider(adminService: service),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminAchievementManagementScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _openCardAction(WidgetTester tester, String action) async {
  await tester.tap(find.byType(AdminAchievementCard).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Lưu'));
  await tester.pumpAndSettle();
}

void main() {
  group('nội dung gửi lên server', () {
    AchievementDraft draft({
      String name = '',
      String description = '',
      String category = 'kanji',
    }) =>
        AchievementDraft(
          nameVi: ' Học Kanji ',
          name: name,
          descriptionVi: ' Học 10 chữ ',
          description: description,
          icon: '🈯',
          category: category,
          requirementValue: 10,
          xpReward: 50,
          rarity: 'rare',
          isActive: false,
        );

    test('tiếng Anh bỏ trống thì lấy theo tiếng Việt', () {
      final json = draft().toJson();

      expect(json['name'], 'Học Kanji');
      expect(json['name_vi'], 'Học Kanji');
      expect(json['description'], 'Học 10 chữ');
      expect(json['is_active'], isFalse);
    });

    test('tiêu chí đi theo nhóm, không tạo được huy hiệu lệch nhóm', () {
      expect(draft(category: 'kanji').toJson()['requirement_type'], 'count');
      expect(draft(category: 'streak').toJson()['requirement_type'], 'streak');
      expect(draft(category: 'xp').toJson()['requirement_type'], 'xp');
    });
  });

  group('màn quản trị', () {
    testWidgets('hiện số người đã mở thật, không phải 0', (tester) async {
      await _pumpScreen(tester, list: [
        _badge(),
        _badge(id: 'a2', name: 'B', nameVi: 'Bậc hai', unlocked: 3),
      ]);

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Lượt mở khoá'), findsOneWidget);
      expect(find.text('4 người đã mở'), findsOneWidget);
    });

    testWidgets('tên hiển thị là tiếng Việt và độ hiếm cũng vậy',
        (tester) async {
      await _pumpScreen(tester);

      expect(find.text('Những Từ Đầu Tiên'), findsOneWidget);
      expect(find.text('First Words'), findsNothing);
      expect(find.text('LEGENDARY'), findsNothing);
      expect(find.text('Huyền thoại'), findsWidgets);
    });

    testWidgets('huy hiệu đang ẩn được đánh dấu', (tester) async {
      await _pumpScreen(tester, list: [_badge(active: false)]);

      expect(find.text('Đang ẩn'), findsWidgets);
    });

    testWidgets('sửa không làm mất tên và mô tả tiếng Việt', (tester) async {
      final service = await _pumpScreen(tester);

      await _openCardAction(tester, 'Chỉnh sửa');
      await tester.enterText(_field('XP thưởng'), '70');
      await _save(tester);

      final json = service.updated['a1']!;
      expect(json['name'], 'First Words');
      expect(json['name_vi'], 'Những Từ Đầu Tiên');
      expect(json['description'], 'Learn 10 words');
      expect(json['description_vi'], 'Học 10 từ vựng');
      expect(json['xp_reward'], 70);
      expect(json['rarity'], 'legendary');
      expect(find.text('Đã cập nhật!'), findsOneWidget);
    });

    testWidgets('tắt hiển thị để ẩn mà không xoá', (tester) async {
      final service = await _pumpScreen(tester);

      await _openCardAction(tester, 'Chỉnh sửa');
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(service.updated['a1']!['is_active'], isFalse);
    });

    testWidgets('nhân bản tạo huy hiệu mới, không sửa bản gốc', (tester) async {
      final service = await _pumpScreen(tester);

      await _openCardAction(tester, 'Nhân bản');
      await _save(tester);

      expect(service.updated, isEmpty);
      expect(service.created.single['name_vi'], 'Những Từ Đầu Tiên (bản sao)');
      expect(service.created.single['name'], 'First Words (copy)');
      expect(service.created.single['requirement_value'], 10);
    });

    testWidgets('thêm mới chọn được tiêu chí', (tester) async {
      final service = await _pumpScreen(tester);

      await tester.tap(find.text('Thêm thành tích'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Tên hiển thị (tiếng Việt)'), 'Kiên trì');
      await tester.enterText(_field('Mô tả (tiếng Việt)'), 'Học 5 ngày');
      await tester.enterText(_field('Số cần đạt'), '5');
      await tester.tap(find.text('Số từ vựng đã học'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Số ngày học liên tiếp').last);
      await tester.pumpAndSettle();
      await _save(tester);

      final json = service.created.single;
      expect(json['name'], 'Kiên trì');
      expect(json['category'], 'streak');
      expect(json['requirement_type'], 'streak');
      expect(json['requirement_value'], 5);
    });

    testWidgets('dữ liệu sai thì không gửi và nói rõ cần sửa gì',
        (tester) async {
      final service = await _pumpScreen(tester);

      await tester.tap(find.text('Thêm thành tích'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Số cần đạt'), '0');
      await _save(tester);

      expect(service.created, isEmpty);
      expect(find.text('Vui lòng nhập'), findsWidgets);
      expect(find.text('Nhập số nguyên từ 1 đến 1000000'), findsOneWidget);
    });

    testWidgets('server từ chối thì giữ hộp thoại và hiện đúng lỗi',
        (tester) async {
      final service = await _pumpScreen(tester);
      service.failure = ApiException('Dữ liệu đã tồn tại.');

      await _openCardAction(tester, 'Nhân bản');
      await _save(tester);

      expect(find.text('Dữ liệu đã tồn tại.'), findsOneWidget);
      expect(_field('Tên hiển thị (tiếng Việt)'), findsOneWidget);
    });

    for (final (width, scale) in const [(320.0, 1.0), (360.0, 2.0)]) {
      testWidgets('form không tràn ở rộng $width, chữ ×$scale', (tester) async {
        await _pumpScreen(tester);
        tester.view.physicalSize = Size(width, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Thêm thành tích'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_field('Số cần đạt'), findsOneWidget);
      });
    }

    testWidgets('xoá nói rõ số người bị ảnh hưởng', (tester) async {
      final service = await _pumpScreen(tester);

      await tester.tap(find.byType(AdminAchievementCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xóa'));
      await tester.pumpAndSettle();

      expect(find.textContaining('4 người đã mở sẽ mất'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xóa'));
      await tester.pumpAndSettle();

      expect(service.deleted, ['a1']);
      expect(find.text('Đã xóa thành tích!'), findsOneWidget);
    });
  });
}
