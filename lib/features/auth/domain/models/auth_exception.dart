class AuthException implements Exception {
  final String code;
  final String? message;

  const AuthException({required this.code, this.message});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
