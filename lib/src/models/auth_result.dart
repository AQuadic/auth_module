class AuthResult<T> {
  const AuthResult._({
    required this.isSuccess,
    this.message,
    this.error,
    this.data,
  });

  final bool isSuccess;
  final String? message;
  final String? error;
  final T? data;

  factory AuthResult.success({T? data, String? message}) {
    return AuthResult._(isSuccess: true, data: data, message: message);
  }

  factory AuthResult.failure(String error, {T? data}) {
    return AuthResult._(isSuccess: false, error: error, data: data);
  }
}
