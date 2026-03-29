import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:auth_module/auth_module.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryTokenStorage tokenStorage;
  late _FakeNetworkClient networkClient;
  late AuthModule module;
  late _FakeNotificationModule notificationModule;
  late _FakeSocialSignInClient socialSignInClient;

  setUp(() {
    tokenStorage = _InMemoryTokenStorage();
    networkClient = _FakeNetworkClient();
    notificationModule = _FakeNotificationModule();
    socialSignInClient = _FakeSocialSignInClient();
    module = AuthModule(
      networkClient: networkClient,
      tokenStorage: tokenStorage,
      config: const AuthModuleConfig(),
      notificationModule: notificationModule,
      socialSignInClient: socialSignInClient,
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

  test(
    'loginWithSocial stores user and token using selected provider',
    () async {
      networkClient.postResponse = {
        'token': 'social-token',
        'user': {'id': 9, 'name': 'Google User', 'email': 'g@g.com'},
        'message': 'ok',
      };

      socialSignInClient.result = const SocialSignInResult.success(
        SocialSignInCredentials(
          provider: 'google',
          accessToken: 'google-access',
          idToken: 'google-id',
        ),
      );

      final result = await module.loginWithSocial(
        provider: SocialProvider.google,
      );

      expect(result.isSuccess, isTrue);
      expect(module.token, 'social-token');
      expect(module.user?.name, 'Google User');
      expect(await tokenStorage.getToken(), 'social-token');
      expect(socialSignInClient.lastProvider, 'google');
      expect(networkClient.lastPostBody?['provider'], 'google');
      expect(networkClient.lastPostBody?['access_token'], 'google-access');
      expect(networkClient.lastPostBody?['id_token'], 'google-id');
    },
  );

  test(
    'loginWithSocial uses admin social endpoint when isAdmin is true',
    () async {
      module = AuthModule(
        networkClient: networkClient,
        tokenStorage: tokenStorage,
        config: const AuthModuleConfig(isAdmin: true),
        notificationModule: notificationModule,
        socialSignInClient: socialSignInClient,
      );

      networkClient.postResponse = {
        'token': 'custom-social-token',
        'user': {'id': 10, 'name': 'Custom User', 'email': 'c@c.com'},
        'message': 'ok',
      };

      socialSignInClient.result = const SocialSignInResult.success(
        SocialSignInCredentials(
          provider: 'apple',
          accessToken: 'apple-access',
        ),
      );

      final result = await module.loginWithSocial(
        provider: SocialProvider.apple,
      );

      expect(result.isSuccess, isTrue);
      expect(socialSignInClient.lastProvider, 'apple');
      expect(networkClient.lastPostEndpoint, 'admin/social');
      expect(networkClient.lastPostBody?['provider'], 'apple');
      expect(networkClient.lastPostBody?['access_token'], 'apple-access');
    },
  );

  test('loginWithSocial returns provider sign-in failure', () async {
    socialSignInClient.result = const SocialSignInResult.failure(
      'user cancelled',
    );

    final result = await module.loginWithSocial(provider: SocialProvider.apple);

    expect(result.isSuccess, isFalse);
    expect(result.error, 'user cancelled');
    expect(networkClient.lastPostEndpoint, isNull);
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

  test('logout clears local auth state and calls logout endpoint by default', () async {
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

    networkClient.postResponse = {'message': 'logged out'};

    final logoutResult = await module.logout();

    expect(logoutResult.isSuccess, isTrue);
    expect(networkClient.lastPostEndpoint, 'user/logout');
    expect(module.token, isNull);
    expect(module.tempToken, isNull);
    expect(module.user, isNull);
    expect(module.otpResponse, isNull);
    expect(module.isLoggedIn, isFalse);
    expect(await tokenStorage.getToken(), isNull);
    expect(notificationModule.token, isNull);
    expect(notificationModule.deleteTokenCalled, isTrue);
  });

}

class _FakeNotificationModule {
  String? token;
  bool deleteTokenCalled = false;

  Future<void> setToken(String? value) async {
    token = value;
  }

  Future<void> addDevice({bool? enabled}) async {}

  Future<void> deleteFCMToken() async {
    deleteTokenCalled = true;
  }
}

class _FakeNetworkClient implements AuthNetworkClient {
  dynamic postResponse;
  dynamic getResponse;
  dynamic deleteResponse;
  String? lastPostEndpoint;
  Map<String, dynamic>? lastPostBody;

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
    lastPostEndpoint = endpoint;
    lastPostBody = body;
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

class _FakeSocialSignInClient implements SocialSignInClient {
  SocialSignInResult result = const SocialSignInResult.success(
    SocialSignInCredentials(
      provider: 'google',
      accessToken: 'fake-access-token',
    ),
  );
  String? lastProvider;

  @override
  Future<SocialSignInResult> signIn({
    required String provider,
    required AuthModuleConfig config,
  }) async {
    lastProvider = provider;
    return result;
  }
}
