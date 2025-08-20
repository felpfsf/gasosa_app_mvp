class Flavor {
  const Flavor({
    required this.name,
    required this.dbName,
  });

  final String name;
  final String dbName;

  static late Flavor instance;
}
