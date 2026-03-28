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
