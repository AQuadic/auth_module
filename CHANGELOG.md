## 0.0.1

* Initial release of logic-only auth module.
* Added login flows for email/password and phone/country/password.
* Added OTP flows: request, verify, resend, and account-state check.
* Added sign-up flow and logout cleanup.
* Added token persistence via pluggable `AuthTokenStorage`.
* Added optional notification module integration via `setToken`, `addDevice`, and `deleteFCMToken`.
* Added `fetchCurrentUser()` with support for both wrapped (`user` key) and direct user JSON response shapes.
* Updated `signUp()` API to accept optional `image` as multipart file and removed the `extra` parameter.
* Added `editUser()` API with multipart profile update support, including optional image upload (`XFile`).
* Added test coverage for `fetchCurrentUser()` success with stored token and direct user JSON payload.

## 0.0.2

* Added `deleteAccount()` API to call configured delete endpoint and clear local auth state on success.

## 0.0.3

* Added `loginWithSocial()` API to authenticate using provider tokens (`provider`, `access_token`, optional `id_token`).
* Added test coverage for social login success and admin social endpoint mode.
* Updated README with social login usage and Android app setup guidance for provider configuration.

## 0.0.4

* Added provider-configured social login via `loginWithConfiguredSocial()`.
* Added social config keys in `AuthModuleConfig` (`socialLoginProvider`, `googleClientId`, `googleAuthScopes`, `appleClientId`, `appleRedirectUri`).
* Added `SocialSignInClient` abstraction with plugin implementation for Google and Apple sign-in.
* Added tests for configured provider flow, provider override, and provider sign-in failure handling.
