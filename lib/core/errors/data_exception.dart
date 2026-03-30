class DataException implements Exception {
  const DataException(this.message);

  final String message;

  @override
  String toString() => 'DataException: $message';
}
