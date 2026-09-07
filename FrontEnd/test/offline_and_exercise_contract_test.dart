import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/exercise/screens/exercise_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('offline preference and empty cache contract are persistent', () async {
    final client = ApiClient();

    expect(await client.isOfflineModeEnabled(), isFalse);
    await client.setOfflineModeEnabled(true);
    expect(await client.isOfflineModeEnabled(), isTrue);

    final info = await client.offlineCacheInfo();
    expect(info['items'], 0);
    expect(info['lastSync'], isNull);

    await client.clearOfflineCache();
    expect((await client.offlineCacheInfo())['items'], 0);
  });

  test('exercise list can be scoped to one lesson', () {
    const screen = ExerciseListScreen(
      lessonId: 'lesson-123',
      lessonTitle: 'Bài 1',
    );

    expect(screen.lessonId, 'lesson-123');
    expect(screen.lessonTitle, 'Bài 1');
  });
}
