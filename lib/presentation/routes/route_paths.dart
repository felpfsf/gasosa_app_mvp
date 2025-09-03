class RoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const vehicle = '/vehicle';
  static const vehicleManageCreate = '/vehicle/manage';
  static String vehicleManageEdit(String id) => '/vehicle/$id/manage';
  static String vehicleDetail(String id) => '/vehicle/$id';
  static String refuelManageCreate(String vehicleId) => '/refuel/create/$vehicleId';
  static String refuelManageEdit(String id) => '/refuel/$id/manage';
}
