enum FuelType { gasoline, ethanol, diesel, flex, gnv }

extension FuelTypeExtension on FuelType {
  static const Map<FuelType, String> _displayNames = {
    FuelType.gasoline: 'Gasolina',
    FuelType.ethanol: 'Etanol',
    FuelType.diesel: 'Diesel',
    FuelType.flex: 'Flex',
    FuelType.gnv: 'GNV',
  };

  String get displayName => _displayNames[this] ?? name;
}
