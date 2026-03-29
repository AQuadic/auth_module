import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:auth_module/auth_module.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryTokenStorage tokenStorage;
  late _FakeNetworkClient networkClient;
  late AuthModule module;
  late _FakeNotificationModule notificationModule;

  setUp(() {
    tokenStorage = _InMemoryTokenStorage();
    networkClient = _FakeNetworkClient();
    notificationModule = _FakeNotificationModule();
    module = AuthModule(
      networkClient: networkClient,
      tokenStorage: tokenStorage,
      config: const AuthModuleConfig(),
      notificationModule: notificationModule,
    );
  });

  test('loginWithEmail stores user and token', () async {
    networkClient.postResponse = {
      'token': 'abc123',
      'user': {'id': 1, 'name': 'Ahmed', 'email': 'a@a.com'},
      'message': 'ok',
    };

    final result = await module.loginWithEmail(
      email: 'a@a.com',
      password: 'secret',
    );

    expect(result.isSuccess, isTrue);
    expect(module.isLoggedIn, isTrue);
    expect(module.token, 'abc123');
    expect(module.user?.name, 'Ahmed');
    expect(await tokenStorage.getToken(), 'abc123');
    expect(notificationModule.token, 'abc123');
  });

  test('requestPhoneOtpLogin keeps temporary token and user', () async {
    networkClient.postResponse = {
      'token': 'temp-token',
      'user': {'id': 2, 'phone': '5555'},
      'otp_callback': {'reference': 'ref-1', 'status': 'pending'},
    };

    final result = await module.requestPhoneOtpLogin(
      phoneCountry: '+966',
      phone: '5555',
    );

    expect(result.isSuccess, isTrue);
    expect(module.tempToken, 'temp-token');
    expect(module.otpResponse?.reference, 'ref-1');
  });

  test(
    'init restores token but not logged-in state until user fetched',
    () async {
      await tokenStorage.saveToken('saved-token');

      await module.init();

      expect(module.token, 'saved-token');
      expect(module.isLoggedIn, isFalse);
    },
  );

  test('Get current user with valid token', () async {
    await tokenStorage.saveToken('valid-token');
    networkClient.getResponse = {
      'id': 3,
      'name': 'Sara',
      'email': 'sara@sara.com',
    };

    await module.init();
    final result = await module.fetchCurrentUser();

    expect(result.isSuccess, isTrue);
    expect(module.token, 'valid-token');
    expect(module.user?.name, 'Sara');
    expect(module.isLoggedIn, isTrue);
  });

  test('deleteAccount clears local auth state on success', () async {
    networkClient.postResponse = {
      'token': 'abc123',
      'user': {'id': 1, 'name': 'Ahmed', 'email': 'a@a.com'},
      'message': 'ok',
    };

    final loginResult = await module.loginWithEmail(
      email: 'a@a.com',
      password: 'secret',
    );
    expect(loginResult.isSuccess, isTrue);
    expect(module.isLoggedIn, isTrue);

    networkClient.deleteResponse = {'message': 'deleted'};

    final deleteResult = await module.deleteAccount();

    expect(deleteResult.isSuccess, isTrue);
    expect(module.token, isNull);
    expect(module.user, isNull);
    expect(module.isLoggedIn, isFalse);
    expect(await tokenStorage.getToken(), isNull);
  });
}

class _FakeNotificationModule {
  String? token;

  Future<void> setToken(String? value) async {
    token = value;
  }

  Future<void> addDevice({bool? enabled}) async {}

  Future<void> deleteFCMToken() async {}
}

class _FakeNetworkClient implements AuthNetworkClient {
  dynamic postResponse;
  dynamic getResponse;
  dynamic deleteResponse;

  @override
  Future delete(String endpoint, {Map<String, dynamic>? body, String? token}) {
    return Future.value(
      Response(
        requestOptions: RequestOptions(path: endpoint),
        data: deleteResponse ?? {'success': true},
        statusCode: 200,
      ),
    );
  }

  @override
  Future post(
    String endpoint, {
    Map<String, dynamic>? body,
    multiPartBody,
    String? token,
    cancelToken,
  }) {
    return Future.value(
      Response(
        requestOptions: RequestOptions(path: endpoint),
        data: postResponse ?? {'success': false, 'error': 'missing'},
        statusCode: 200,
      ),
    );
  }

  @override
  Future get(String endpoint, {Map<String, dynamic>? body, String? token}) {
    return Future.value(
      Response(
        requestOptions: RequestOptions(path: endpoint),
        data: getResponse ?? {'success': false, 'error': 'missing'},
        statusCode: 200,
      ),
    );
  }
}

class _InMemoryTokenStorage implements AuthTokenStorage {
  String? _value;

  @override
  Future<void> clearToken() async {
    _value = null;
  }

  @override
  Future<String?> getToken() async {
    return _value;
  }

  @override
  Future<void> saveToken(String? token) async {
    _value = token;
  }
}
