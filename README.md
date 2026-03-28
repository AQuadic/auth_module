# Auth Module

Logic-only authentication module for Flutter projects.

Supports:
- Email + password login
- Phone + country + password login
- Phone + country login without password (OTP flow with CloudWA/check-state pattern)
- Sign up
- Delete account
- Token persistence
- Current user getter, token getter, and `isLoggedIn`
- Direct integration with your notification module for `addDevice`

> Social login is intentionally excluded.

## Install

```yaml
dependencies:
	auth_module:
		path: ../auth_module
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
  - `user/user`, `user/login`, `user/signup`, `user/logout`, `user/resend`, `user/verify`, `user/update`, `user/verifyInfo`, `user/otp/check`, `user/destroy`
- `isAdmin: true` uses:
  - `admin/getCurrentAdmin`, `admin/login`, `admin/signup`, `admin/logout`, `admin/resend`, `admin/verify`, `admin/forgot`, `admin/change_password`, `admin/update`, `admin/verifyInfo`, `admin/otp/check`, `admin/destroy`

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
- response keys (`token`, `user`, `message`, `otp_callback`, `reference`)
- default verify types (`whatsapp`, `mail_otp`, `new`)
- persisted token key

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
