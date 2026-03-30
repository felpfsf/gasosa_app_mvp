class DomainException implements Exception {
  const DomainException(this.message);

  final String message;

  @override
  String toString() => 'DomainException: $message';
}
