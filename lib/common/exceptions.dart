class SprintCheckException implements Exception {
  String? message;

  SprintCheckException(this.message);

  @override
  String toString() {
    if (message == null) return 'Unknown Error';
    return message!;
  }
}

class SprintCheckSdkNotInitializedException extends SprintCheckException {
  SprintCheckSdkNotInitializedException(String message) : super(message);
}

class AuthenticationException extends SprintCheckException {
  AuthenticationException(String message) : super(message);
}
