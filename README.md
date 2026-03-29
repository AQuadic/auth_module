# Auth Module

Logic-only authentication module for Flutter projects.

Supports:
- Email + password login
- Phone + country + password login
- Phone + country login without password (OTP flow with CloudWA/check-state pattern)
- Social login token exchange (Google/Apple)
- Sign up
- Profile update
- Delete account
- Token persistence
- Current user getter, token getter, and `isLoggedIn`
- Direct integration with your notification module for `addDevice`

## Install

```yaml
dependencies:
	auth_module:
		git:
      		url: https://github.com/scilton/auth_module.git
```

Then run:

```bash
flutter pub get
```

## Quick setup

```dart
import 'package:auth_module/auth_module.dart';

final auth = AuthModule.init(
	dioHelper: DioHelper.instance,
	notificationModule: NotificationModule.instance,
	config: const AuthModuleConfig(
		isAdmin: false,
	),
);

await auth.init();
```

## Endpoint mode

- `isAdmin: false` (default) uses:
	- `user/user`, `user/login`, `user/social`, `user/signup`, `user/logout`, `user/resend`, `user/verify`, `user/update`, `user/verifyInfo`, `user/otp/check`, `user/destroy`
- `isAdmin: true` uses:
	- `admin/getCurrentAdmin`, `admin/login`, `admin/social`, `admin/signup`, `admin/logout`, `admin/resend`, `admin/verify`, `admin/forgot`, `admin/change_password`, `admin/update`, `admin/verifyInfo`, `admin/otp/check`, `admin/destroy`

## API usage

### 1) Login with email/password

```dart
final result = await auth.loginWithEmail(
	email: email,
	password: password,
);

if (result.isSuccess) {
	final UserModel? user = auth.user;
}
```

### 2) Login with phone/country/password

```dart
final result = await auth.loginWithPhoneAndPassword(
	phoneCountry: 'SA',
	phone: '5xxxxxxxx',
	password: password,
);
```

### 3) Login with phone/country (without password) + OTP

Request OTP (CloudWA verify type by default):

```dart
await auth.requestPhoneOtpLogin(
	phoneCountry: 'SA',
	phone: '5xxxxxxxx',
	// verifyType defaults to 'whatsapp'
);
```

Verify code:

```dart
await auth.verifyOtp(
	code: code,
	phone: '5xxxxxxxx',
	phoneCountry: 'SA',
	// type defaults to 'new'
);
```

Check account state (Souq style polling/callback reference):

```dart
await auth.checkPhoneOtpState(
	phone: '5xxxxxxxx',
	phoneCountry: 'SA',
	// reference optional, uses auth.otpResponse?.reference if available
);
```

Resend OTP:

```dart
await auth.resendOtp(
	phone: '5xxxxxxxx',
	phoneCountry: 'SA',
	isNew: true,
);
```

### 4) Social login

`auth_module` now handles provider sign-in first, then sends tokens to your backend.

```dart
final result = await auth.loginWithSocial(
	provider: SocialProvider.google,
);
```

Use Apple:

```dart
final result = await auth.loginWithSocial(
	provider: SocialProvider.apple,
);
```

You still configure provider SDK options in `AuthModuleConfig` (for example `googleClientId`, `googleAuthScopes`, `appleClientId`, `appleRedirectUri`).

### Sign up

You can upload an optional profile image as multipart file.

```dart
import 'package:dio/dio.dart';

await auth.signUp(
	name: name,
	email: email,
	password: password,
	passwordConfirmation: passwordConfirmation,
	phoneCountry: 'SA',
	phone: '5xxxxxxxx',
	image: await MultipartFile.fromFile('/path/to/image.jpg'),
);
```

### Current user / token / logged-in state

```dart
final UserModel? user = auth.user;
final String? token = auth.token;
final bool isLoggedIn = auth.isLoggedIn;
final bool? isNotificationEnabled = auth.isNotificationEnabled;
```

Load user details using stored token:

```dart
await auth.fetchCurrentUser();
```

`fetchCurrentUser()` supports both backend response shapes:
- Wrapped user payload: `{ "user": { ... } }`
- Direct user payload: `{ ...user fields... }`

In both cases, the parsed value is assigned to `auth.user` and returned in `AuthResult<UserModel>.data`.

### Edit user profile

```dart
import 'package:cross_file/cross_file.dart';

final result = await auth.updateUser(
	name: 'Ahmed',
	email: 'ahmed@example.com',
	countryCode: 'SA',
	phone: '5xxxxxxxx',
	birthday: DateTime(1998, 7, 20),
	gender: 'male',
	image: XFile('/path/to/image.jpg'),
);

if (result.isSuccess) {
	final UserModel? updatedUser = result.data;
}
```

### Logout

```dart
await auth.logout();
```

### Delete account

```dart
final result = await auth.deleteAccount();

if (result.isSuccess) {
	// Local auth state is cleared automatically.
}
```

## Config options

`AuthModuleConfig` lets you customize:
- mode (`isAdmin`)
- social provider (`socialLoginProvider`: `google` or `apple`)
- Google setup (`googleClientId`, `googleAuthScopes`)
- Apple setup (`appleClientId`, `appleRedirectUri`)
- response keys (`token`, `user`, `message`, `otp_callback`, `reference`)
- default verify types (`whatsapp`, `mail_otp`, `new`)
- persisted token key

### AuthModuleConfig example

```dart
const config = AuthModuleConfig(isAdmin: false);
```

Configured provider example:

```dart
const config = AuthModuleConfig(
	isAdmin: false,
	socialLoginProvider: 'google',
	googleClientId: 'your-google-oauth-client-id.apps.googleusercontent.com',
);
```

## Android social setup

`auth_module` can trigger social provider login if configured,
but native provider setup still belongs to the consuming app.

### Required app files

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### AndroidManifest.xml example

Use your project-level social login settings in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
	<uses-permission android:name="android.permission.INTERNET"/>

	<application
			android:label="YourApp"
			android:name="${applicationName}"
			android:icon="@mipmap/ic_launcher">
		<activity
				android:name=".MainActivity"
				android:exported="true"
				android:launchMode="singleTop"
				android:theme="@style/LaunchTheme"
				android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
				android:hardwareAccelerated="true"
				android:windowSoftInputMode="adjustResize">
			<intent-filter>
				<action android:name="android.intent.action.MAIN"/>
				<category android:name="android.intent.category.LAUNCHER"/>
			</intent-filter>
		</activity>

		<activity
				android:name="com.aboutyou.dart_packages.sign_in_with_apple.SignInWithAppleCallback"
				android:exported="true">
			<intent-filter>
				<action android:name="android.intent.action.VIEW"/>
				<category android:name="android.intent.category.DEFAULT"/>
				<category android:name="android.intent.category.BROWSABLE"/>
				<data android:scheme="signinwithapple"/>
				<data android:path="callback"/>
			</intent-filter>
		</activity>
	</application>
</manifest>
```

After setup, use `loginWithSocial(provider: SocialProvider.google)` or `loginWithSocial(provider: SocialProvider.apple)`.

## Tests

Run all tests:

```bash
flutter test
```

Run auth module tests only:

```bash
flutter test test/auth_module_test.dart
```

## Notes

- Module is logic only (no UI/widgets).
- Module accepts `DioHelper` through `AuthModule.init`.
- Pass your notification module instance directly with `notificationModule`.
- `init()` restores token only; call `fetchCurrentUser()` to populate `auth.user` from API.
- Models are annotation-based: `UserModel`, `OtpResponse`, `ResponsiveImageModelJsonConv`.
