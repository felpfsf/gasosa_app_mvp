abstract final class Routes {
  // Auth — flat full paths
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';

  // Dev-only preview routes
  static const devRefuelPreview = '/dev/refuel-preview';

  // Vehicle — parent + child segments
  static const vehicle = '/vehicle';
  static const manageVehicle = 'manage';
  static const vehicleDetail = 'detail';

  /// Full path for navigation. Omit [id] when creating a new vehicle.
  static String manageVehiclePath([String? id]) => '$vehicle/$manageVehicle${id != null ? '?id=$id' : ''}';

  static String vehicleDetailPath(String id) => '$vehicle/$vehicleDetail?id=$id';

  // Refuel — parent + child segment
  static const refuel = '/refuel';
  static const manageRefuel = 'manage';

  /// Full path for navigation. Pass [vehicleId] when creating, [refuelId] when editing.
  static String manageRefuelPath({String? vehicleId, String? refuelId}) =>
      refuelId != null ? '$refuel/$manageRefuel?id=$refuelId' : '$refuel/$manageRefuel?vehicleId=$vehicleId';
}
