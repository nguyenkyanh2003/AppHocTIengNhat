import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/features/auth/models/profile_changes.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/auth/services/auth_service.dart';
import 'package:apphoctiengnnhat/features/profile/screens/profile_screen.dart';
import 'package:apphoctiengnnhat/features/streaks/models/user_streak.dart';
import 'package:apphoctiengnnhat/features/streaks/providers/streak_provider.dart';
import 'package:apphoctiengnnhat/features/streaks/services/streak_service.dart';
import 'package:apphoctiengnnhat/shared/models/user.dart';

/// Hồ sơ mang các trường thống kê đời cũ luôn bằng 0 (bản lưu trước khi server
/// bỏ chúng): màn hồ sơ không được đọc chúng.
final _user = User.fromJson(const {
  '_id': 'u1',
  'TenDangNhap': 'lan',
  'HoTen': 'Lê Lan',
  'Email': 'lan@example.invalid',
  'TrinhDo': 'N4',
  'DiemTichLuy': 0,
  'StreakHienTai': 0,
  'TongThoiGianHoc': 0,
});

class _FakeAuthService extends AuthService {
  final saved = <ProfileChanges>[];

  @override
  Future<User> login(String username, String password) async => _user;

  @override
  Future<User> updateProfile(String userId, ProfileChanges changes) async {
    saved.add(changes);
    return _user;
  }

  @override
  Future<User> getCurrentUser(String userId) async => _user;
}

class _FakeStreakService extends StreakService {
  _FakeStreakService({this.fails = false});

  final bool fails;
  int calls = 0;

  @override
  Future<UserStreak> getMyStreak() async {
    calls += 1;
    if (fails) throw Exception('mất mạng');
    return UserStreak.fromJson(const {'current_streak': 3, 'total_xp': 120});
  }
}

Future<void> _pump(WidgetTester tester, StreakService streakService, {_FakeAuthService? authService}) async {
  final auth = AuthProvider(authService: authService ?? _FakeAuthService());
  await auth.login('lan', 'mat-khau');
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider(create: (_) => StreakProvider(service: streakService)),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: const ProfileScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('XP và chuỗi ngày lấy từ streak thật, không từ trường cũ của hồ sơ', (tester) async {
    final streak = _FakeStreakService();
    await _pump(tester, streak);

    expect(streak.calls, 1, reason: 'mở hồ sơ thì tải streak');
    expect(find.text('120 XP'), findsOneWidget);
    expect(find.text('3 ngày'), findsOneWidget);
    expect(find.text('0 XP'), findsNothing);
    expect(find.text('0 phút'), findsNothing, reason: 'thời gian học cũ không ai ghi nên không hiện');
  });

  testWidgets('chưa tải được streak thì hiện gạch, không hiện 0', (tester) async {
    await _pump(tester, _FakeStreakService(fails: true));

    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('0 XP'), findsNothing);
    expect(find.text('0 ngày'), findsNothing);
  });

  testWidgets('nút đổi ảnh đại diện có nhãn cho trình đọc màn hình và tooltip', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _FakeStreakService());

    expect(find.byTooltip('Đổi ảnh đại diện'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('Đổi ảnh đại diện')),
      containsSemantics(tooltip: 'Đổi ảnh đại diện', isButton: true, isEnabled: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('chỉ sửa họ tên thì không tự gán giới tính người dùng chưa chọn', (tester) async {
    final authService = _FakeAuthService();
    await _pump(tester, _FakeStreakService(), authService: authService);

    await tester.tap(find.byTooltip('Chỉnh sửa thông tin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Họ tên'), 'Lê Thu Lan');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    final changes = authService.saved.single;
    expect(changes.fullName, 'Lê Thu Lan');
    expect(changes.gender, isNull, reason: 'người dùng chưa chọn giới tính');
  });
}
