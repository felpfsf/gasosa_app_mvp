class VehicleEntity {
  VehicleEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.plate,
    this.tankCapacity,
    this.photoPath,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? plate;
  final double? tankCapacity;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
