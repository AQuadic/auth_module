# Auth Module

Logic-only authentication module for Flutter projects.

Supports:
- Email + password login
- Phone + country + password login
- Phone + country login without password (OTP flow with CloudWA/check-state pattern)
- Social login token exchange (Google/Apple)
- Firebase Auth token exchange (including phone OTP credential flow)
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
      		url: https://github.com/aquadic/auth_module.git
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

### 5) Firebase auth login


```dart
final sendResult = await auth.sendFirebasePhoneOtp(
	phoneNumber: '+201234567890', // E.164 format
);

if (!sendResult.isSuccess) {
	// show sendResult.message
	return;
}

final verifyResult = await auth.verifyFirebasePhoneOtp(
	smsCode: smsCodeFromUser,
);

if (verifyResult.isSuccess) {
	final UserModel? user = verifyResult.data;
	// auth.user is assigned internally as well
}
```

`verifyFirebasePhoneOtp` uses the internally stored Firebase `verificationId` from `sendFirebasePhoneOtp`.
You can still pass a custom `verificationId` when needed.

Both methods send the token to `users/auth/firebase` by default (`AuthModuleConfig.firebaseLoginEndpoint`) and include provider as `'FIREBASE'` by default.


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

// Optional: skip Firebase sign-out
await auth.logout(withFirebase: false);
```

`logout()` now performs all of the following in one call:
- Calls backend logout endpoint (when token exists and `callApi` is true).
- Signs out Firebase session via `FirebaseAuth.instance.signOut()` when `withFirebase` is true.
- Clears local auth state (`token`, `tempToken`, `user`, `otpResponse`, Firebase verification id).
- Clears persisted token and notification tokens.

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
			...
		</activity>

		<!-- Add this config in file -->
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

### Add Apple signin configrations (ios/android) automatically (from this module)

If this module is added from Git in your app dependencies, run this command directly from your app root:
**Before running the command, ensure that the capability is enabled in Xcode → Signing & Capabilities**

```bash
dart run auth_module:add_apple_signin_configs
```

This one command configures both:
- `android/app/src/main/AndroidManifest.xml` (adds `SignInWithAppleCallback` activity)
- `ios/Runner/Runner.entitlements` (adds `com.apple.developer.applesignin` key)

If `ios/Runner/Runner.entitlements` does not exist, the command creates it and ensures this is set in `ios/Runner.xcodeproj/project.pbxproj` under Debug/Release/Profile `buildSettings`:

----

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
