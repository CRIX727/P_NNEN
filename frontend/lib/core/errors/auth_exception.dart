class AuthRepositoryException implements Exception {
  const AuthRepositoryException(
    this.message, {
    this.retryable = false,
  });

  final String message;
  final bool retryable;

  @override
  String toString() => message;
}

