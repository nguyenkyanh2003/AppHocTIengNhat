import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/features/auth/providers/auth_provider.dart';
import 'package:apphoctiengnnhat/features/auth/services/auth_service.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

final _expired = _json({'message': 'Phiên đăng nhập đã hết hạn.', 'code': 'SESSION_EXPIRED'}, 401);

/// Access token đúng dạng JWT. App chỉ đọc `sid` và `rotation` để so phiên, không kiểm chữ ký.
String _jwt(String sid, {String userId = 'user-A', int rotation = 0}) {
  String part(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'id': userId, 'sid': sid, 'rotation': rotation})}.chu-ky';
}

/// Backend giả: access token hợp lệ là [validAccess]; làm mới đổi `r1` lấy cặp mới.
class _Backend {
  _Backend({this.validAccess = 'access-moi', this.refreshResponse});

  final String validAccess;
  final FutureOr<http.Response> Function()? refreshResponse;
  final requests = <http.Request>[];
  int refreshes = 0;

  MockClient get client => MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/users/refresh-token')) {
          refreshes++;
          return await refreshResponse?.call() ??
              _json({'token': 'access-moi', 'refreshToken': 'refresh-moi'});
        }
        if (request.url.path.endsWith('/users/login')) {
          return _json({'message': 'Tên đăng nhập hoặc mật khẩu không đúng.', 'code': 'INVALID_CREDENTIALS'}, 401);
        }
        return request.headers['Authorization'] == 'Bearer $validAccess' ? _json({'data': 'ok'}) : _expired;
      });
}

void main() {
  final api = ApiClient();
  var expiredCalls = 0;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await api.setSession('access-cu', 'refresh-cu');
    expiredCalls = 0;
    api.onSessionExpired = () => expiredCalls++;
  });

  tearDown(() async {
    api.onSessionExpired = null;
    await api.removeToken();
  });

  test('access token hết hạn: tự làm mới một lần, gửi lại request, lưu cặp token mới', () async {
    final backend = _Backend();

    final result = await http.runWithClient(() => api.get('/progress'), () => backend.client);

    expect(result['data'], 'ok');
    expect(backend.refreshes, 1);
    expect(jsonDecode(backend.requests.firstWhere((r) => r.url.path.endsWith('/refresh-token')).body),
        {'refreshToken': 'refresh-cu'});
    expect((api.getToken(), api.getRefreshToken()), ('access-moi', 'refresh-moi'));
    expect(await const FlutterSecureStorage().read(key: 'refresh_token'), 'refresh-moi');
    expect(expiredCalls, 0);
  });

  test('nhiều request cùng hết hạn chỉ làm mới một lần', () async {
    final backend = _Backend();

    final results = await http.runWithClient(
      () => Future.wait([api.get('/a'), api.get('/b'), api.post('/c', {})]),
      () => backend.client,
    );

    expect(results.map((r) => r['data']), ['ok', 'ok', 'ok']);
    expect(backend.refreshes, 1);
  });

  test('refresh token bị từ chối: báo phiên kết thúc đúng một lần', () async {
    final backend = _Backend(refreshResponse: () => _expired);

    await http.runWithClient(() async {
      await expectLater(api.get('/progress'), throwsA(isA<UnauthorizedException>()));
    }, () => backend.client);

    expect(backend.refreshes, 1);
    expect(expiredCalls, 1);
  });

  test('mất mạng lúc làm mới: báo lỗi mạng, không đăng xuất, giữ nguyên token', () async {
    final backend = _Backend(refreshResponse: () => throw http.ClientException('mất mạng'));

    await http.runWithClient(() async {
      await expectLater(api.get('/progress'), throwsA(isA<NetworkException>()));
    }, () => backend.client);

    expect(expiredCalls, 0);
    expect((api.getToken(), api.getRefreshToken()), ('access-cu', 'refresh-cu'));
  });

  test('sai mật khẩu hay 401 không mang mã phiên thì không làm mới', () async {
    final backend = _Backend();

    await http.runWithClient(() async {
      await expectLater(api.post('/users/login', {'username': 'a', 'password': 'b'}), throwsA(isA<UnauthorizedException>()));
    }, () => backend.client);

    expect(backend.refreshes, 0);
    expect(expiredCalls, 0);
  });

  test('đăng nhập lưu cả refresh token; đăng xuất gửi nó để server đóng phiên rồi xoá sạch', () async {
    await api.removeToken();
    final requests = <http.Request>[];

    await http.runWithClient(() async {
      final auth = AuthService();
      await auth.login('victim', 'correct-horse');
      expect((api.getToken(), api.getRefreshToken()), ('access-dang-nhap', 'refresh-dang-nhap'));
      await auth.logout();
    }, () => MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/users/login')) {
        return _json({'message': 'ok', 'token': 'access-dang-nhap', 'refreshToken': 'refresh-dang-nhap', 'user': {}});
      }
      return _json({'message': 'Đăng xuất thành công'});
    }));

    final logout = requests.last;
    expect(logout.url.path, '/api/users/logout');
    expect(jsonDecode(logout.body), {'refreshToken': 'refresh-dang-nhap'});
    expect(logout.headers['Authorization'], 'Bearer access-dang-nhap');
    expect((api.getToken(), api.getRefreshToken()), (null, null));
    expect(await const FlutterSecureStorage().read(key: 'refresh_token'), isNull);
  });

  test('tải tệp: access token hết hạn thì làm mới rồi gửi lại', () async {
    final backend = _Backend();

    final result = await http.runWithClient(
      () => api.putMultipart('/users/profile/u1/avatar', {}, 'avatar', [1, 2, 3], 'a.png'),
      () => backend.client,
    );

    expect(result['data'], 'ok');
    expect(backend.refreshes, 1);
  });

  group('đổi phiên giữa chừng', () {
    /// Gửi một request của phiên A, chờ nó đi, rồi đổi phiên bằng [switchSession]
    /// trước khi phản hồi [late] về tới.
    Future<Object?> staleOutcome(
      Future<void> Function() switchSession,
      http.Response late, {
      List<String?>? seen,
      bool cache = false,
    }) async {
      final gate = Completer<http.Response>();
      Object? outcome;
      await http.runWithClient(() async {
        final pending = api.get('/ghi-du-lieu-cua-A', cache: cache).then<Object?>((value) => value, onError: (Object e) => e);
        await Future<void>.delayed(Duration.zero);
        await switchSession();
        gate.complete(late);
        outcome = await pending;
      }, () => MockClient((request) async {
        seen?.add(request.headers['Authorization']);
        if (seen == null || seen.length == 1) return gate.future;
        return _json({'data': 'du-lieu-cua-B'});
      }));
      return outcome;
    }

    test('request cũ của A nhận 401 sau khi chuyển sang B: bị bỏ, không gửi lại bằng token của B', () async {
      final seen = <String?>[];

      final outcome = await staleOutcome(() => api.setSession('access-B', 'refresh-B'), _expired, seen: seen);

      expect(seen, ['Bearer access-cu'], reason: 'không được gửi lại bằng token của B');
      expect(outcome, isA<SessionChangedException>());
      expect(expiredCalls, 0, reason: 'lỗi của phiên cũ không được đăng xuất B');
      expect((api.getToken(), api.getRefreshToken()), ('access-B', 'refresh-B'));
    });

    test('phản hồi thành công của A về sau khi chuyển sang B cũng bị bỏ', () async {
      final outcome = await staleOutcome(() => api.setSession('access-B', 'refresh-B'), _json({'data': 'du-lieu-cua-A'}));

      expect(outcome, isA<SessionChangedException>());
    });

    test('phản hồi về sau khi đăng xuất cũng bị bỏ', () async {
      final outcome = await staleOutcome(api.removeToken, _json({'data': 'du-lieu-cua-A'}));

      expect(outcome, isA<SessionChangedException>());
    });

    test('dữ liệu của phiên cũ không vào bộ nhớ ngoại tuyến của phiên mới', () async {
      await api.setOfflineModeEnabled(true);

      final outcome = await staleOutcome(() => api.setSession('access-B', 'refresh-B'), _json({'data': 'du-lieu-cua-A'}), cache: true);
      expect(outcome, isA<SessionChangedException>());

      await http.runWithClient(() async {
        await expectLater(api.get('/ghi-du-lieu-cua-A', cache: true), throwsA(isA<NetworkException>()));
      }, () => MockClient((_) async => throw http.ClientException('mất mạng')));
    });

    /// Request của A hết hạn và đang làm mới thì đổi phiên; phản hồi làm mới về sau đó.
    Future<void> lateRefresh(Future<void> Function() switchSession) async {
      final gate = Completer<http.Response>();
      await http.runWithClient(() async {
        final pending = api.get('/x').then<Object?>((value) => value, onError: (Object e) => e);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await switchSession();
        gate.complete(_json({'token': 'access-A-moi', 'refreshToken': 'refresh-A-moi'}));
        expect(await pending, isA<SessionChangedException>());
      }, () => MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) return gate.future;
        return _expired;
      }));
    }

    test('phản hồi làm mới của A về muộn không ghi đè token của B', () async {
      await lateRefresh(() => api.setSession('access-B', 'refresh-B'));

      expect((api.getToken(), api.getRefreshToken()), ('access-B', 'refresh-B'));
      expect(await const FlutterSecureStorage().read(key: 'refresh_token'), 'refresh-B');
      expect(expiredCalls, 0);
    });

    test('đăng xuất trong lúc làm mới: token không sống lại', () async {
      await lateRefresh(api.removeToken);

      expect((api.getToken(), api.getRefreshToken()), (null, null));
      expect(await const FlutterSecureStorage().read(key: 'auth_token'), isNull);
      expect(await const FlutterSecureStorage().read(key: 'refresh_token'), isNull);
      expect(expiredCalls, 0);
    });

    test('B không chờ chung lần làm mới của A, và A bị từ chối không đăng xuất B', () async {
      final gateOfA = Completer<http.Response>();
      final refreshTokens = <String>[];

      await http.runWithClient(() async {
        final ofA = api.get('/cua-A').then<Object?>((value) => value, onError: (Object e) => e);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        await api.setSession('access-B', 'refresh-B');
        final ofB = await api.get('/cua-B');
        expect(ofB['data'], 'ok');

        gateOfA.complete(_expired);
        expect(await ofA, isA<SessionChangedException>());
      }, () => MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) {
          final token = jsonDecode(request.body)['refreshToken'] as String;
          refreshTokens.add(token);
          if (token == 'refresh-cu') return gateOfA.future;
          return _json({'token': 'access-B-moi', 'refreshToken': 'refresh-B-moi'});
        }
        return request.headers['Authorization'] == 'Bearer access-B-moi' ? _json({'data': 'ok'}) : _expired;
      }));

      expect(refreshTokens, ['refresh-cu', 'refresh-B'], reason: 'B tự làm mới bằng token của chính mình');
      expect(expiredCalls, 0);
      expect((api.getToken(), api.getRefreshToken()), ('access-B-moi', 'refresh-B-moi'));
    });
  });

  group('chỉ kết thúc phiên khi server xác nhận', () {
    for (final status in [500, 503, 429, 400]) {
      test('làm mới trả $status: báo lỗi tạm thời, giữ phiên, lần sau thử lại được', () async {
        var failing = true;
        final backend = _Backend(
          refreshResponse: () => failing ? _json({'message': 'Máy chủ bận'}, status) : _json({'token': 'access-moi', 'refreshToken': 'refresh-moi'}),
        );

        await http.runWithClient(() async {
          await expectLater(api.get('/progress'), throwsA(isA<ServerException>()));
          expect(expiredCalls, 0);
          expect((api.getToken(), api.getRefreshToken()), ('access-cu', 'refresh-cu'));

          failing = false;
          expect((await api.get('/progress'))['data'], 'ok');
        }, () => backend.client);

        expect(backend.refreshes, 2);
      });
    }

    test('401 không mang mã phiên cũng chưa phải server xác nhận: giữ phiên', () async {
      final backend = _Backend(refreshResponse: () => _json({'message': 'proxy từ chối'}, 401));

      await http.runWithClient(() async {
        await expectLater(api.get('/progress'), throwsA(isA<ServerException>()));
      }, () => backend.client);

      expect(expiredCalls, 0);
    });

    test('làm mới trả 200 nhưng nội dung hỏng: báo lỗi tạm thời, giữ phiên', () async {
      for (final body in [
        http.Response('khong-phai-json', 200),
        _json({'khong': 'co token'}),
        _json({'token': 'access-moi'}),
      ]) {
        final backend = _Backend(refreshResponse: () => body);
        await http.runWithClient(() async {
          await expectLater(api.get('/progress'), throwsA(isA<ServerException>()));
        }, () => backend.client);

        expect(expiredCalls, 0);
        expect((api.getToken(), api.getRefreshToken()), ('access-cu', 'refresh-cu'));
      }
    });

    test('nhiều request cùng bị từ chối chỉ báo phiên kết thúc một lần', () async {
      final backend = _Backend(refreshResponse: () => _expired);

      await http.runWithClient(() async {
        await Future.wait([
          for (final path in ['/a', '/b', '/c'])
            api.get(path).then<Object?>((value) => value, onError: (Object e) => e),
        ]);
      }, () => backend.client);

      expect(backend.refreshes, 1);
      expect(expiredCalls, 1);
    });
  });

  // Trên web, secure storage và shared preferences đều nằm trong localStorage,
  // dùng chung giữa các tab; token trong bộ nhớ thì mỗi tab một bản. "Tab kia"
  // ở đây được giả bằng cách ghi thẳng vào kho, đúng như tab kia thật sự làm.
  group('hai tab web dùng chung kho lưu', () {
    const storage = FlutterSecureStorage();
    final accessA = _jwt('phien-A', userId: 'user-A');
    final accessB = _jwt('phien-B', userId: 'user-B');

    Future<void> otherTabStores(String access, String refresh) async {
      await storage.write(key: 'auth_token', value: access);
      await storage.write(key: 'refresh_token', value: refresh);
    }

    Future<void> otherTabLogsOut() async {
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'refresh_token');
    }

    Future<(String?, String?)> stored() async =>
        (await storage.read(key: 'auth_token'), await storage.read(key: 'refresh_token'));

    setUp(() async {
      await api.setSession(accessA, 'refresh-A');
    });

    test('cùng phiên, tab kia vừa làm mới: dùng cặp token đó, không xoay lại token cũ', () async {
      // Gửi lại refresh token cũ quá hạn ân hạn sẽ bị coi là token bị đánh cắp.
      final renewed = _jwt('phien-A', userId: 'user-A', rotation: 2);
      await otherTabStores(renewed, 'refresh-A-moi');
      final backend = _Backend(validAccess: renewed);

      final result = await http.runWithClient(() => api.get('/progress'), () => backend.client);

      expect(result['data'], 'ok');
      expect(backend.refreshes, 0);
      expect((api.getToken(), api.getRefreshToken()), (renewed, 'refresh-A-moi'));
      expect(expiredCalls, 0);
    });

    test('tab kia đã đổi sang B: yêu cầu ghi của A bị huỷ, không gửi bằng quyền của B', () async {
      await otherTabStores(accessB, 'refresh-B');
      final seen = <String?>[];

      await http.runWithClient(() async {
        await expectLater(api.post('/goal', {'type': 'kanji', 'target': 10}), throwsA(isA<SessionChangedException>()));
      }, () => MockClient((request) async {
        seen.add('${request.url.path} ${request.headers['Authorization']}');
        return request.headers['Authorization'] == 'Bearer $accessB' ? _json({'data': 'tao-vao-tai-khoan-B'}, 201) : _expired;
      }));

      expect(seen, ['/api/goal Bearer $accessA'], reason: 'không gửi lại, không làm mới bằng token của A');
      expect(expiredCalls, 1, reason: 'tab này phải về màn đăng nhập');
      expect(await stored(), (accessB, 'refresh-B'));
    });

    test('cùng tài khoản nhưng đăng nhập lại (phiên khác) cũng không nhận token', () async {
      await otherTabStores(_jwt('phien-A-2', userId: 'user-A'), 'refresh-A-2');

      await http.runWithClient(() async {
        await expectLater(api.get('/progress'), throwsA(isA<SessionChangedException>()));
      }, () => _Backend().client);

      expect(expiredCalls, 1);
    });

    test('token trong kho không đọc được mã phiên thì không nhận', () async {
      await otherTabStores('khong-phai-jwt', 'refresh-la');

      await http.runWithClient(() async {
        await expectLater(api.get('/progress'), throwsA(isA<SessionChangedException>()));
      }, () => _Backend().client);

      expect(api.getRefreshToken(), isNot('refresh-la'));
    });

    /// Phản hồi làm mới của tab này về sau khi tab kia đã đổi kho bằng [otherTab].
    Future<Object?> refreshLandsAfter(Future<void> Function() otherTab, String renewedAccess, {String? validAccess}) async {
      final gate = Completer<http.Response>();
      Object? outcome;
      await http.runWithClient(() async {
        final pending = api.get('/x').then<Object?>((value) => value, onError: (Object e) => e);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await otherTab();
        gate.complete(_json({'token': renewedAccess, 'refreshToken': 'refresh-A-moi'}));
        outcome = await pending;
      }, () => MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) return gate.future;
        return request.headers['Authorization'] == 'Bearer ${validAccess ?? renewedAccess}' ? _json({'data': 'ok'}) : _expired;
      }));
      return outcome;
    }

    test('phản hồi làm mới về sau khi tab kia đăng nhập B: không ghi đè token của B', () async {
      final outcome = await refreshLandsAfter(() => otherTabStores(accessB, 'refresh-B'), _jwt('phien-A', rotation: 2));

      expect(outcome, isA<SessionChangedException>());
      expect(await stored(), (accessB, 'refresh-B'));
      expect(expiredCalls, 1);
    });

    test('phản hồi làm mới về sau khi tab kia đăng xuất: token không sống lại trong kho', () async {
      final outcome = await refreshLandsAfter(otherTabLogsOut, _jwt('phien-A', rotation: 2));

      expect(outcome, isA<SessionChangedException>());
      expect(await stored(), (null, null));
      expect(expiredCalls, 1);
    });

    test('hai tab cùng làm mới, phản hồi về đúng thứ tự: cặp mới hơn ghi đè cặp cũ', () async {
      final renewed = _jwt('phien-A', rotation: 2);

      final outcome = await refreshLandsAfter(() => otherTabStores(_jwt('phien-A', rotation: 1), 'refresh-tab-kia'), renewed);

      expect((outcome as Map)['data'], 'ok');
      expect(await stored(), (renewed, 'refresh-A-moi'));
      expect(expiredCalls, 0);
    });

    test('hai tab cùng làm mới, phản hồi về ngược thứ tự: cặp cũ không ghi đè cặp mới hơn', () async {
      // Hai tab cùng gửi R1, server lần lượt cấp R2 rồi R3. R2 đã bị R3 thay nên
      // ghi nó vào kho thì lần làm mới sau bị coi là dùng lại token và mất cả phiên.
      final newest = _jwt('phien-A', rotation: 2);

      final outcome = await refreshLandsAfter(
        () => otherTabStores(newest, 'refresh-R3'),
        _jwt('phien-A', rotation: 1),
        validAccess: newest,
      );

      expect((outcome as Map)['data'], 'ok', reason: 'gửi lại yêu cầu bằng access token của cặp mới hơn');
      expect(await stored(), (newest, 'refresh-R3'));
      expect((api.getToken(), api.getRefreshToken()), (newest, 'refresh-R3'));
      expect(expiredCalls, 0);

      final sent = <Object?>[];
      final after = _jwt('phien-A', rotation: 3);
      await http.runWithClient(() => api.get('/y'), () => MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) {
          sent.add(jsonDecode(request.body)['refreshToken']);
          return _json({'token': after, 'refreshToken': 'refresh-R4'});
        }
        return request.headers['Authorization'] == 'Bearer $after' ? _json({'data': 'ok'}) : _expired;
      }));
      expect(sent, ['refresh-R3'], reason: 'lần làm mới sau không được dùng R2');
    });

    test('kho giữ cặp cũ hơn cặp của tab này: làm mới bằng cặp của tab và sửa lại kho', () async {
      // Hai tab ghi kho sát nhau có thể để lại cặp cũ; nhận nó là dùng token đã bị thay.
      await api.setSession(_jwt('phien-A', rotation: 3), 'refresh-R3');
      await otherTabStores(_jwt('phien-A', rotation: 2), 'refresh-R2');
      final after = _jwt('phien-A', rotation: 4);
      final sent = <Object?>[];

      final result = await http.runWithClient(() => api.get('/y'), () => MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) {
          sent.add(jsonDecode(request.body)['refreshToken']);
          return _json({'token': after, 'refreshToken': 'refresh-R4'});
        }
        return request.headers['Authorization'] == 'Bearer $after' ? _json({'data': 'ok'}) : _expired;
      }));

      expect(result['data'], 'ok');
      expect(sent, ['refresh-R3']);
      expect(await stored(), (after, 'refresh-R4'));
    });

    group('dọn phiên của tab cũ', () {
      Future<Map<String, Object?>> sharedPrefs() async {
        final prefs = await SharedPreferences.getInstance();
        return {for (final key in prefs.getKeys()) key: prefs.get(key)};
      }

      test('không xoá token và dữ liệu của phiên B ở tab kia', () async {
        SharedPreferences.setMockInitialValues({'current_user_id': 'user-B', 'user_data_user-B': '{}'});
        await otherTabStores(accessB, 'refresh-B');

        await api.removeToken();
        await api.clearAllData();

        expect((api.getToken(), api.getRefreshToken()), (null, null));
        expect(await stored(), (accessB, 'refresh-B'));
        expect(await sharedPrefs(), {'current_user_id': 'user-B', 'user_data_user-B': '{}'});
      });

      test('tab đã đăng xuất gọi dọn lần nữa cũng không xoá phiên tab kia vừa mở', () async {
        await api.removeToken();
        await otherTabStores(accessB, 'refresh-B');

        await api.removeToken();

        expect(await stored(), (accessB, 'refresh-B'));
      });

      test('đăng xuất của chính phiên này vẫn xoá sạch, kể cả khi tab kia vừa làm mới cùng phiên', () async {
        SharedPreferences.setMockInitialValues({'current_user_id': 'user-A', 'user_data_user-A': '{}'});
        await otherTabStores(_jwt('phien-A', rotation: 2), 'refresh-A-moi');

        await api.removeToken();
        await api.clearAllData();

        expect(await stored(), (null, null));
        expect(await sharedPrefs(), isEmpty);
      });

      test('AuthProvider: tab cũ về trạng thái chưa đăng nhập, phiên B ở tab kia còn nguyên', () async {
        SharedPreferences.setMockInitialValues({});
        await api.removeToken();
        final provider = AuthProvider(authService: AuthService(client: api), apiClient: api);
        addTearDown(provider.dispose);

        await http.runWithClient(() async {
          expect(await provider.login('a', 'mat-khau-a'), isTrue);
          expect(provider.isAuthenticated, isTrue);

          SharedPreferences.setMockInitialValues({'current_user_id': 'user-B', 'user_data_user-B': '{}'});
          await otherTabStores(accessB, 'refresh-B');

          await expectLater(api.post('/goal', {'type': 'kanji', 'target': 10}), throwsA(isA<SessionChangedException>()));
          await pumpEventQueue();
        }, () => MockClient((request) async {
          if (request.url.path.endsWith('/users/login')) {
            return _json({'message': 'ok', 'token': accessA, 'refreshToken': 'refresh-A', 'user': {'_id': 'user-A', 'TenDangNhap': 'a'}});
          }
          if (request.url.path.endsWith('/users/profile/user-A')) {
            return _json({'profile': {'_id': 'user-A', 'TenDangNhap': 'a'}});
          }
          return _expired;
        }));

        expect(provider.isAuthenticated, isFalse);
        expect(provider.user, isNull);
        expect(await stored(), (accessB, 'refresh-B'));
        expect((await sharedPrefs())['current_user_id'], 'user-B');
      });
    });
  });
}
