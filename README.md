# Auth Module

Logic-only authentication module for Flutter projects.

Supports:
- Email + password login
- Phone + country + password login
- Phone + country login without password (OTP flow with CloudWA/check-state pattern)
- Optional forgot-password entry on login screen (`forgetType`)
- Forgot-password UI flow for email, phone+CloudWA, and phone+OTP
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

Check account state (Polling/callback reference):

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

### Forgot & Reset password

The module supports the 3-step forgot/reset cycle:

1) Start forgot password:

```dart
final forgot = await auth.forgotPassword(
	email: 'user@example.com',
	resetType: 'mail_otp',
);

// OR phone flow
final forgotByPhone = await auth.forgotPassword(
	phoneCountry: 'EG',
	phone: '01000000000',
	// resetType defaults to 'whatsapp_send'
);
```

On success, the module stores temp token and OTP callback reference internally.

2) Poll verification state:

```dart
final check = await auth.checkPhoneOtpState(
	phone: '01000000000',
	phoneCountry: 'EG',
	// reference is optional; module uses cached otpResponse.reference
);
```

When verified, backend reset token is persisted internally.

3) Submit new password:

```dart
final reset = await auth.resetPassword(
	phone: '01000000000',
	phoneCountry: 'EG',
	password: 'NewPass123',
	passwordConfirmation: 'NewPass123',
	// resetToken optional; defaults to locally stored reset token
);
```

### Change current password

```dart
final change = await auth.changePassword(
	oldPassword: 'OldPass123',
	newPassword: 'NewPass123',
	confirmPassword: 'NewPass123',
);
```

## UI screens usage

### LoginScreen with optional forgot password

If `forgetType` is null, forgot-password button is hidden.
The login screen now also shows a translated `Don't have an account? Sign Up` action and navigates to `SignUpScreen`.
If `hasCompleteProfile` is true, signup row is hidden and post-login routing checks user profile completeness.

```dart
LoginScreen(
	loginType: LoginType.emailAndPassword,
	forgetType: ForgetType.email, // null => hide forgot button
	langCode: 'en',
	mainAppScreen: const HomeScreen(),
	// Sign up behavior (defaults shown)
	signupHasEmail: true,
	signupHasPhoneNumber: true,
	signupHasPassword: true,
	hasCompleteProfile: true,
	signupTitle: 'Create account',
	signupSubtitle: 'Let\'s get you started',
	// Optional custom look for forgot screen
	forgetTitle: 'Reset your password',
	forgetSubtitle: 'We will send a verification code',
	forgetLogo: const Icon(Icons.lock_reset),
);
```

Supported forgot types:
- `ForgetType.email`: email field, then goes to `OtpScreen`, then `ResetPasswordScreen`
- `ForgetType.phoneWithVerificationCloudwa`: phone field, then `WaitingResponseScreen`, then `ResetPasswordScreen`
- `ForgetType.phoneWithVerificationOtp`: phone field, then `OtpScreen`, then `ResetPasswordScreen`

### Continue as Guest

The login screen also shows a translated `Continue as Guest` action at the bottom.
It navigates directly to `mainAppScreen` and clears the navigation stack.

### CompleteProfileScreen

When `hasCompleteProfile` is enabled in `LoginScreen`, after any successful login path (`email/password`, `phone/password`, `CloudWA`, or `OTP`), the module fetches current user and checks the default-name rule.

If user name contains `user`, navigation goes to `CompleteProfileScreen`; otherwise it continues to `mainAppScreen`.

```dart
CompleteProfileScreen(
	langCode: 'en',
	mainAppScreen: const HomeScreen(),
	title: 'Complete Your Profile',
	subtitle: 'Add your details to continue',
	primaryColor: Theme.of(context).colorScheme.primary,
);
```

`CompleteProfileScreen` includes:
- Profile image picker
- Name (required)
- Email (optional)
- Phone (optional)
- Submit action (`Submit`)

### EditProfileScreen

`EditProfileScreen` is for editing the current signed-in user profile.
It initializes its form from `AuthModule.instance.user` and saves changes with `updateUser()`.

Includes:
- Profile image picker using `ImagePicker`
- Responsive image preview from the user image model
- Name field
- Email field
- Phone field with country selector
- Gender selection (`Male` / `Female`)
- Save action

```dart
EditProfileScreen(
	langCode: 'en',
	primaryColor: Theme.of(context).colorScheme.primary,
)
```

Localized strings used by this screen:
- `edit_profile`
- `choose_from_gallery`
- `take_photo`
- `gender`
- `male`
- `female`
- `profile_updated`
- `profile_update_failed`

### SignUpScreen

`SignUpScreen` uses internal module instance automatically (no `module` parameter).

Defaults:
- `hasEmail: true`
- `hasPhoneNumber: true`
- `hasPassword: true`

When `hasPassword` is false, password fields are hidden.
After successful sign up, if phone is enabled and provided, it navigates to `WaitingResponseScreen` (CloudWA flow) then to `mainAppScreen` after verification.

```dart
SignUpScreen(
	langCode: 'en',
	mainAppScreen: const HomeScreen(),
	hasEmail: true,
	hasPhoneNumber: true,
	hasPassword: true,
	title: 'Create Account',
	subtitle: 'Join us now',
	primaryColor: Theme.of(context).colorScheme.primary,
);
```

`SignUpScreen` includes:
- Profile image picker
- Name field
- Optional email field
- Optional phone field
- Optional password + confirm password fields
- Back-to-login action (`Already have an account? Sign In`)

### ResetPasswordScreen (forgot flow)

`ResetPasswordScreen` now only handles forgot-password reset and contains:
- New password
- Confirm new password

After successful reset, it shows a translated success snackbar with the primary color, then returns to the login screen.

```dart
ResetPasswordScreen(
	langCode: 'en',
	mainAppScreen: const HomeScreen(),
	email: 'user@example.com', // or phone + phoneCountry
	resetType: 'mail_otp',
	// resetToken optional, uses saved token from verify/check-state
);
```

### ChangePasswordScreen (in-app password update)

`ChangePasswordScreen` is a separate screen with 3 fields:
- Old password
- New password
- Confirm new password

```dart
ChangePasswordScreen(
	langCode: 'en',
	mainAppScreen: const HomeScreen(),
	title: 'Change Password',
	subtitle: 'Keep your account secure',
);
```

Use this screen for authenticated password updates. It includes:
- Old password
- New password
- Confirm new password

It uses the regular change-password API flow, not the forgot/reset token flow.

### Direct ForgotPasswordScreen usage

```dart
ForgotPasswordScreen(
	forgetType: ForgetType.phoneWithVerificationOtp,
	langCode: 'ar',
	mainAppScreen: const HomeScreen(),
	title: 'نسيت كلمة المرور؟',
	subtitle: 'ادخل رقم الهاتف للمتابعة',
);
```

`ForgotPasswordScreen` accepts `title`, `subtitle`, and `logo` like `LoginScreen`.

## Localization

Localized for English and Arabic in `ModuleLocalizations`:
- `forgot_password`
- `forgot_password_msg`
- `reset_password`
- `reset_password_msg`
- `reset_password_success_title`
- `reset_password_success_msg`
- `change_password`
- `change_password_msg`
- `old_password`
- `new_password`
- `confirm_new_password`
- `old_password_is_required`
- `new_password_is_required`
- `confirm_new_password_is_required`
- `passwords_not_match`
- `continue_as_guest`
- `sign_up`
- `signup_msg`
- `name`
- `name_is_required`
- `dont_have_account`
- `already_have_account`
- `add_photo`
- `submit`
- `complete_profile_title`
- `complete_profile_subtitle`

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
Email/password are supported and can be omitted when your backend flow does not require them.

```dart
import 'package:dio/dio.dart';

await auth.signUp(
	name: name,
	email: email, // optional
	password: password, // optional
	passwordConfirmation: passwordConfirmation, // optional
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

## UI Components

The module includes ready-to-use Flutter widgets for login, OTP, and phone verification flows. The cubit and state management are handled automatically—no need to wrap the app.

### Navigation Flow (Splash/Onboarding → Login → Main App)

From your screen, navigate directly to `LoginScreen` with `loginType` parameter, passing `mainAppScreen` (where to go after successful login):

```dart
import 'package:auth_module/auth_module.dart';

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          loginType: LoginType.emailAndPassword,
		  langCode: 'en',
          mainAppScreen: LayoutScreen(), // Destination after login
          primaryColor: Theme.of(context).colorScheme.primary,
          socialProviders: const [
            SocialProvider.google,
            SocialProvider.apple,
          ],
        ),
      ),
      (route) => false,
    );
```

The login screen automatically builds the right form (email or phone) based on `loginType`. Cubit and state management are handled internally.

### Login Screen (Email + Password)

```dart
LoginScreen(
  loginType: LoginType.emailAndPassword,
	langCode: 'en',
  mainAppScreen: HomeScreen(),
  primaryColor: Colors.blue,
  logo: Image.asset('assets/logo.png'),
  title: 'Welcome',
  subtitle: 'Sign in to your account',
  socialProviders: [
    SocialProvider.google,
    SocialProvider.apple,
  ],
);
```

### Login Screen (Phone + Password)

```dart
LoginScreen(
  loginType: LoginType.phoneAndPassword,
	langCode: 'en',
  mainAppScreen: HomeScreen(),
  primaryColor: Theme.of(context).colorScheme.primary,
  title: 'Phone Login',
  socialProviders: const [
    SocialProvider.google,
    SocialProvider.apple,
  ],
);
```

### Full Custom Login Screen

For full control with all customization options:

```dart
LoginScreen(
  loginType: LoginType.emailAndPassword,
	langCode: 'ar', // or 'en'
  mainAppScreen: HomeScreen(),
  // Custom branding
  logo: Image.asset('assets/logo.png'),
  title: 'Sign In',
  subtitle: 'Enter your credentials',
  primaryColor: Colors.teal,
  contentPadding: const EdgeInsets.all(24),
  // Custom field labels/hints (for email)
  emailLabel: 'Email Address',
  emailHint: 'user@example.com',
  // Custom field labels/hints (for phone)
  phoneLabel: 'Phone Number',
  passwordLabel: 'Password',
  passwordHint: 'Enter secure password',
	// Sign up customization
	signupTitle: 'Create Account',
	signupSubtitle: 'Start your journey',
	signupHasEmail: true,
	signupHasPhoneNumber: true,
	signupHasPassword: true,
	hasCompleteProfile: true,
  // Social login (pass list or null to hide)
  socialProviders: [SocialProvider.google],
  // Interceptor dialog control (for phone verification)
	onInterceptorDialogFlagChange: (flag) {}, // Controls dialog behavior in waiting screen
);
```

### OTP Verification Screen

After `auth.requestPhoneOtpLogin()`, navigate to `OtpScreen`:

```dart
// Step 1: Request OTP
final result = await AuthModule.instance.requestPhoneOtpLogin(
  phoneCountry: 'EG',
  phone: '1001234567',
);

if (result.isSuccess) {
  // Step 2: Navigate to OtpScreen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OtpScreen(
				langCode: 'en',
        mainAppScreen: HomeScreen(),
				hasCompleteProfile: true,
        phone: '1001234567',
        phoneCountry: 'EG',
        primaryColor: Colors.blue,
      ),
    ),
  );
}
```

The screen shows a 6-digit input field, resend countdown, and navigates automatically when verified.

### Waiting Response Screen

For phone-only verification (SMS/WhatsApp polling):

```dart
// Step 1: Start phone OTP login
final result = await AuthModule.instance.requestPhoneOtpLogin(
  phoneCountry: 'SA',
  phone: '501234567',
);

if (result.isSuccess) {
  // Step 2: Navigate to waiting screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WaitingResponseScreen(
        phone: '501234567',
        country: 'SA',
				langCode: 'en',
				nextScreen: HomeScreen(),
				hasCompleteProfile: true,
        primaryColor: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
```

The screen automatically:
- Polls `checkPhoneOtpState()` every 2 seconds
- Navigates to `CompleteProfileScreen` (when enabled and name is default), otherwise to `nextScreen`
- Allows resend of OTP with countdown

### Wrapper Classes

For convenience, you can use wrapper classes that set the `loginType` automatically:

```dart
// Email + Password
LoginWithEmailAndPassword(
  langCode: 'en',
  mainAppScreen: HomeScreen(),
	hasCompleteProfile: true,
	onInterceptorDialogFlagChange: (flag) {}, // Controls dialog behavior in waiting screen
  // ... other parameters
);

// Phone + Password
LoginWithPhoneAndPassword(
  langCode: 'en',
  mainAppScreen: HomeScreen(),
	hasCompleteProfile: true,
	onInterceptorDialogFlagChange: (flag) {}, // Controls dialog behavior in waiting screen
  // ... other parameters
);

// Phone + Verification Code
LoginWithPhoneAndVerificationCode(
  langCode: 'en',
  mainAppScreen: HomeScreen(),
	hasCompleteProfile: true,
	onInterceptorDialogFlagChange: (flag) {}, // Controls dialog behavior in waiting screen
  // ... other parameters
);
```


## Notes

- Module provides logic APIs and optional ready-to-use UI widgets/screens.
- Module accepts `DioHelper` through `AuthModule.init`.
- Pass your notification module instance directly with `notificationModule`.
- `init()` restores token only; call `fetchCurrentUser()` to populate `auth.user` from API.
- Models are annotation-based: `UserModel`, `OtpResponse`, `ResponsiveImageModelJsonConv`.
