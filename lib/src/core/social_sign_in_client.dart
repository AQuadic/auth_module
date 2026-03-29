import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_module_config.dart';

class SocialSignInCredentials {
  const SocialSignInCredentials({
    required this.provider,
    required this.accessToken,
    this.idToken,
  });

  final String provider;
  final String accessToken;
  final String? idToken;
}

class SocialSignInResult {
  const SocialSignInResult.success(this.credentials)
    : message = null,
      isSuccess = true;

  const SocialSignInResult.failure(this.message)
    : credentials = null,
      isSuccess = false;

  final bool isSuccess;
  final SocialSignInCredentials? credentials;
  final String? message;
}

abstract class SocialSignInClient {
  Future<SocialSignInResult> signIn({
    required String provider,
    required AuthModuleConfig config,
  });
}

class PluginSocialSignInClient implements SocialSignInClient {
  PluginSocialSignInClient({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;

  @override
  Future<SocialSignInResult> signIn({
    required String provider,
    required AuthModuleConfig config,
  }) async {
    final normalized = provider.trim().toLowerCase();

    if (normalized == 'google') {
      return _signInWithGoogle(config);
    }
    if (normalized == 'apple') {
      return _signInWithApple(config);
    }

    return SocialSignInResult.failure('Unsupported social provider: $provider');
  }

  Future<SocialSignInResult> _signInWithGoogle(AuthModuleConfig config) async {
    try {
      if (_isNotBlank(config.googleClientId)) {
        await _googleSignIn.initialize(clientId: config.googleClientId);
      } else {
        await _googleSignIn.initialize();
      }

      final user = await _googleSignIn.authenticate();
      var headers = await user.authorizationClient.authorizationHeaders(
        config.googleAuthScopes,
      );

      if (headers?.isEmpty ?? false) {
        await user.authorizationClient.authorizeScopes(config.googleAuthScopes);
        headers = await user.authorizationClient.authorizationHeaders(
          config.googleAuthScopes,
        );
      }

      final authHeader = headers?['Authorization'];
      final token = authHeader?.split(' ').last;

      if (!_isNotBlank(token)) {
        return const SocialSignInResult.failure(
          'Google access token is missing.',
        );
      }

      return SocialSignInResult.success(
        SocialSignInCredentials(provider: 'google', accessToken: token!),
      );
    } on GoogleSignInException catch (e) {
      return SocialSignInResult.failure(
        'GoogleSignInException: ${e.code} - ${e.description ?? e.toString()}',
      );
    } catch (e) {
      return SocialSignInResult.failure('Google sign-in failed: $e');
    }
  }

  Future<SocialSignInResult> _signInWithApple(AuthModuleConfig config) async {
    if (!_isNotBlank(config.appleClientId) ||
        !_isNotBlank(config.appleRedirectUri)) {
      return const SocialSignInResult.failure(
        'Apple sign-in requires appleClientId and appleRedirectUri in AuthModuleConfig.',
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: config.appleClientId!,
          redirectUri: Uri.parse(config.appleRedirectUri!),
        ),
      );

      final identityToken = credential.identityToken;
      final accessToken = identityToken ?? credential.authorizationCode;
      if (!_isNotBlank(accessToken)) {
        return const SocialSignInResult.failure(
          'Apple token is missing from credential response.',
        );
      }

      return SocialSignInResult.success(
        SocialSignInCredentials(
          provider: 'apple',
          accessToken: accessToken,
          idToken: identityToken,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      return SocialSignInResult.failure(
        'AppleSignInException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      return SocialSignInResult.failure('Apple sign-in failed: $e');
    }
  }

  bool _isNotBlank(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
