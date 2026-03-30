// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refuel_dao.dart';

// ignore_for_file: type=lint
mixin _$RefuelDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  $RefuelsTable get refuels => attachedDatabase.refuels;
  RefuelDaoManager get managers => RefuelDaoManager(this);
}

class RefuelDaoManager {
  final _$RefuelDaoMixin _db;
  RefuelDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
  $$RefuelsTableTableManager get refuels =>
      $$RefuelsTableTableManager(_db.attachedDatabase, _db.refuels);
}
