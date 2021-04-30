class FTPException implements Exception {
  final String message;
  final String? response;

  FTPException(this.message, [this.response]);

  @override
  String toString() {
    return 'FTPException: $message (Response: $response)';
  }
}
