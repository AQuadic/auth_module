## 0.1.0

* Fixed phone-with-verification login flow to perform `resendOtp` (via backend OTP callback) after `requestPhoneOtpLogin`, before navigating to `WaitingResponseScreen`.
* Added explicit UI loading state to “generate new code” action using `ModuleButton.isLoading`.
* Improved OTP scheme launch stability by relying on backend `otpResponse.scheme` in `WaitingResponseScreen`.

## 0.0.9

* Added built-in authentication UI flow components:
	* `LoginScreen` for email/password and phone/password login.
	* `OtpScreen` for OTP code entry and verification.
	* `WaitingResponseScreen` for phone verification polling flow.
* Added `AuthUiCubit` and `AuthUiState` for internal auth UI state management.
* Added `ModuleLocalizations` support for Arabic/English UI texts via `langCode`.
* Added reusable auth UI widgets (`ModuleButton`, `PasswordTextField`, `PhoneField`, `TextFieldWidget`) and `AuthModuleUiProvider`.
* Exported presentation layer APIs from `auth_module.dart` for direct package consumption.
* Updated package dependencies/assets to support the new UI components.


## 0.0.8

* Added password management APIs:
	* `forgotPassword()` to initiate password recovery flow.
	* `resetPassword()` to complete password reset with automatic stored token detection.
	* `changePassword()` to change password for authenticated users.

## 0.0.7

* Added Firebase auth integration APIs:
	* `sendFirebasePhoneOtp()` to send Firebase phone OTP from the module.
	* `verifyFirebasePhoneOtp()` to verify OTP using stored/provided Firebase `verificationId` and return `UserModel`.
	* `loginWithFirebaseIdToken()` and `loginWithFirebasePhoneOtp()` for Firebase token exchange with backend.
* Updated logout to support optional Firebase sign-out with `logout(withFirebase: true/false)`.

## 0.0.6

* Added package executable `dart run auth_module:add_apple_signin_configs` to configure Apple Sign-In for both Android and iOS in one command.
* Improved `DioHelperNetworkClient` compatibility to support helper implementations using either `query` or `body` named parameters for GET/DELETE calls.

## 0.0.5

* Refactored `AuthModule` implementation into service-focused Dart part files for better maintainability.
* Updated README with internal architecture documentation.

## 0.0.4

* Added provider-configured social login via `loginWithConfiguredSocial()`.
* Added social config keys in `AuthModuleConfig` (`socialLoginProvider`, `googleClientId`, `googleAuthScopes`, `appleClientId`, `appleRedirectUri`).
* Added `SocialSignInClient` abstraction with plugin implementation for Google and Apple sign-in.
* Added tests for configured provider flow, provider override, and provider sign-in failure handling.

## 0.0.3

* Added `loginWithSocial()` API to authenticate using provider tokens (`provider`, `access_token`, optional `id_token`).
* Added test coverage for social login success and admin social endpoint mode.
* Updated README with social login usage and Android app setup guidance for provider configuration.

## 0.0.2

* Added `deleteAccount()` API to call configured delete endpoint and clear local auth state on success.

## 0.0.1

* Initial release of logic-only auth module.
* Added login flows for email/password and phone/country/password.
* Added OTP flows: request, verify, resend, and account-state check.
* Added sign-up flow and logout cleanup.
* Added token persistence via pluggable `AuthTokenStorage`.
* Added optional notification module integration via `setToken`, `addDevice`, and `deleteFCMToken`.
* Added `fetchCurrentUser()` with support for both wrapped (`user` key) and direct user JSON response shapes.
* Updated `signUp()` API to accept optional `image` as multipart file and removed the `extra` parameter.
* Added `updateUser()` API with multipart profile update support, including optional image upload (`XFile`).
* Added test coverage for `fetchCurrentUser()` success with stored token and direct user JSON payload.
