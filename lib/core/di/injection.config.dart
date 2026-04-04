// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:gasosa_app/application/auth/login_email_password_use_case.dart'
    as _i769;
import 'package:gasosa_app/application/auth/login_with_google_use_case.dart'
    as _i239;
import 'package:gasosa_app/application/auth/logout_use_case.dart' as _i310;
import 'package:gasosa_app/application/auth/register_use_case.dart' as _i345;
import 'package:gasosa_app/application/photos/delete_photo_use_case.dart'
    as _i596;
import 'package:gasosa_app/application/photos/save_photo_use_case.dart'
    as _i808;
import 'package:gasosa_app/application/refuel/create_or_update_refuel_use_case.dart'
    as _i1031;
import 'package:gasosa_app/application/refuel/delete_refuel_use_case.dart'
    as _i693;
import 'package:gasosa_app/application/refuel/get_previous_refuel_use_case.dart'
    as _i657;
import 'package:gasosa_app/application/refuel/get_refuel_by_id_use_case.dart'
    as _i760;
import 'package:gasosa_app/application/refuel/get_refuels_by_vehicle_use_case.dart'
    as _i182;
import 'package:gasosa_app/application/refuel/load_refuels_by_vehicle_use_case.dart'
    as _i1064;
import 'package:gasosa_app/application/vehicles/create_or_update_vehicle_use_case.dart'
    as _i469;
import 'package:gasosa_app/application/vehicles/delete_vehicle_use_case.dart'
    as _i62;
import 'package:gasosa_app/application/vehicles/get_vehicle_by_id_use_case.dart'
    as _i1042;
import 'package:gasosa_app/application/vehicles/load_vehicles_use_case.dart'
    as _i183;
import 'package:gasosa_app/core/di/register_module.dart' as _i53;
import 'package:gasosa_app/data/auth/firebase_auth_service.dart' as _i821;
import 'package:gasosa_app/data/local/dao/refuel_dao.dart' as _i621;
import 'package:gasosa_app/data/local/dao/user_dao.dart' as _i876;
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart' as _i353;
import 'package:gasosa_app/data/local/db/app_database.dart' as _i409;
import 'package:gasosa_app/data/local/local_photo_storage_impl.dart' as _i198;
import 'package:gasosa_app/data/repositories/refuel_repository_impl.dart'
    as _i146;
import 'package:gasosa_app/data/repositories/vehicle_repository_impl.dart'
    as _i106;
import 'package:gasosa_app/domain/repositories/refuel_repository.dart' as _i857;
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart' as _i35;
import 'package:gasosa_app/domain/services/auth_service.dart' as _i602;
import 'package:gasosa_app/domain/services/local_photo_storage.dart' as _i312;
import 'package:gasosa_app/domain/services/refuel_business_rules.dart' as _i188;
import 'package:gasosa_app/presentation/screens/auth/viewmodel/login_viewmodel.dart'
    as _i788;
import 'package:gasosa_app/presentation/screens/auth/viewmodel/register_viewmodel.dart'
    as _i979;
import 'package:gasosa_app/presentation/screens/dashboard/viewmodel/dashboard_viewmodel.dart'
    as _i327;
import 'package:gasosa_app/presentation/screens/refuel/viewmodel/manage_refuel_viewmodel.dart'
    as _i1034;
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/manage_vehicle_viewmodel.dart'
    as _i212;
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/vehicle_detail_viewmodel.dart'
    as _i464;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:uuid/uuid.dart' as _i706;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i706.Uuid>(() => registerModule.uuid);
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    await gh.lazySingletonAsync<_i116.GoogleSignIn>(
      () => registerModule.googleSignIn,
      preResolve: true,
    );
    gh.lazySingleton<_i409.AppDatabase>(() => registerModule.appDatabase);
    gh.lazySingleton<_i188.RefuelBusinessRules>(
      () => const _i188.RefuelBusinessRules(),
    );
    gh.lazySingleton<_i312.LocalPhotoStorage>(
      () => _i198.LocalPhotoStorageImpl(),
    );
    gh.lazySingleton<_i353.VehicleDao>(
      () => registerModule.vehicleDao(gh<_i409.AppDatabase>()),
    );
    gh.lazySingleton<_i621.RefuelDao>(
      () => registerModule.refuelDao(gh<_i409.AppDatabase>()),
    );
    gh.lazySingleton<_i876.UserDao>(
      () => registerModule.userDao(gh<_i409.AppDatabase>()),
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => registerModule.router(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i857.RefuelRepository>(
      () => _i146.RefuelRepositoryImpl(gh<_i621.RefuelDao>()),
    );
    gh.lazySingleton<_i35.VehicleRepository>(
      () => _i106.VehicleRepositoryImpl(gh<_i353.VehicleDao>()),
    );
    gh.lazySingleton<_i602.AuthService>(
      () => _i821.FirebaseAuthService(
        auth: gh<_i59.FirebaseAuth>(),
        google: gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.factory<_i596.DeletePhotoUseCase>(
      () => _i596.DeletePhotoUseCase(gh<_i312.LocalPhotoStorage>()),
    );
    gh.factory<_i808.SavePhotoUseCase>(
      () => _i808.SavePhotoUseCase(gh<_i312.LocalPhotoStorage>()),
    );
    gh.factory<_i1031.CreateOrUpdateRefuelUseCase>(
      () => _i1031.CreateOrUpdateRefuelUseCase(
        repository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i693.DeleteRefuelUseCase>(
      () => _i693.DeleteRefuelUseCase(repository: gh<_i857.RefuelRepository>()),
    );
    gh.factory<_i657.GetPreviousRefuelUseCase>(
      () => _i657.GetPreviousRefuelUseCase(
        repository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i760.GetRefuelByIdUseCase>(
      () =>
          _i760.GetRefuelByIdUseCase(repository: gh<_i857.RefuelRepository>()),
    );
    gh.factory<_i182.GetRefuelsByVehicleUseCase>(
      () => _i182.GetRefuelsByVehicleUseCase(
        repository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i1064.LoadRefuelsByVehicleUseCase>(
      () => _i1064.LoadRefuelsByVehicleUseCase(
        repository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i769.LoginEmailPasswordUseCase>(
      () => _i769.LoginEmailPasswordUseCase(auth: gh<_i602.AuthService>()),
    );
    gh.factory<_i239.LoginWithGoogleUseCase>(
      () => _i239.LoginWithGoogleUseCase(auth: gh<_i602.AuthService>()),
    );
    gh.factory<_i310.LogoutUseCase>(
      () => _i310.LogoutUseCase(auth: gh<_i602.AuthService>()),
    );
    gh.factory<_i345.RegisterUseCase>(
      () => _i345.RegisterUseCase(auth: gh<_i602.AuthService>()),
    );
    gh.factory<_i469.CreateOrUpdateVehicleUseCase>(
      () => _i469.CreateOrUpdateVehicleUseCase(
        repository: gh<_i35.VehicleRepository>(),
      ),
    );
    gh.factory<_i62.DeleteVehicleUseCase>(
      () => _i62.DeleteVehicleUseCase(repository: gh<_i35.VehicleRepository>()),
    );
    gh.factory<_i1042.GetVehicleByIdUseCase>(
      () => _i1042.GetVehicleByIdUseCase(
        repository: gh<_i35.VehicleRepository>(),
      ),
    );
    gh.factory<_i183.LoadVehiclesUseCase>(
      () => _i183.LoadVehiclesUseCase(repository: gh<_i35.VehicleRepository>()),
    );
    gh.factory<_i327.DashboardViewModel>(
      () => _i327.DashboardViewModel(
        gh<_i602.AuthService>(),
        gh<_i183.LoadVehiclesUseCase>(),
        gh<_i310.LogoutUseCase>(),
      ),
    );
    gh.factory<_i464.VehicleDetailViewModel>(
      () => _i464.VehicleDetailViewModel(
        gh<_i1042.GetVehicleByIdUseCase>(),
        gh<_i62.DeleteVehicleUseCase>(),
        gh<_i182.GetRefuelsByVehicleUseCase>(),
      ),
    );
    gh.factory<_i979.RegisterViewModel>(
      () => _i979.RegisterViewModel(gh<_i345.RegisterUseCase>()),
    );
    gh.factory<_i212.ManageVehicleViewModel>(
      () => _i212.ManageVehicleViewModel(
        gh<_i602.AuthService>(),
        gh<_i1042.GetVehicleByIdUseCase>(),
        gh<_i469.CreateOrUpdateVehicleUseCase>(),
        gh<_i62.DeleteVehicleUseCase>(),
        gh<_i808.SavePhotoUseCase>(),
        gh<_i596.DeletePhotoUseCase>(),
      ),
    );
    gh.factory<_i788.LoginViewModel>(
      () => _i788.LoginViewModel(
        gh<_i239.LoginWithGoogleUseCase>(),
        gh<_i769.LoginEmailPasswordUseCase>(),
      ),
    );
    gh.factory<_i1034.ManageRefuelViewModel>(
      () => _i1034.ManageRefuelViewModel(
        gh<_i1042.GetVehicleByIdUseCase>(),
        gh<_i1031.CreateOrUpdateRefuelUseCase>(),
        gh<_i693.DeleteRefuelUseCase>(),
        gh<_i760.GetRefuelByIdUseCase>(),
        gh<_i657.GetPreviousRefuelUseCase>(),
        gh<_i808.SavePhotoUseCase>(),
        gh<_i596.DeletePhotoUseCase>(),
        gh<_i188.RefuelBusinessRules>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i53.RegisterModule {}
