// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:gasosa_app/application/commands/auth/loggin_with_google_command.dart'
    as _i318;
import 'package:gasosa_app/application/commands/auth/login_email_password_command.dart'
    as _i13;
import 'package:gasosa_app/application/commands/auth/register_command.dart'
    as _i728;
import 'package:gasosa_app/application/commands/photos/delete_photo_command.dart'
    as _i458;
import 'package:gasosa_app/application/commands/photos/save_photo_command.dart'
    as _i180;
import 'package:gasosa_app/application/commands/refuel/calculate_consumption_command.dart'
    as _i53;
import 'package:gasosa_app/application/commands/refuel/create_or_update_refuel_command.dart'
    as _i188;
import 'package:gasosa_app/application/commands/refuel/delete_refuel_command.dart'
    as _i142;
import 'package:gasosa_app/application/commands/refuel/load_refuels_by_vehicle_command.dart'
    as _i237;
import 'package:gasosa_app/application/commands/vehicles/create_or_update_vehicle_command.dart'
    as _i328;
import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart'
    as _i215;
import 'package:gasosa_app/application/commands/vehicles/load_vehicles_command.dart'
    as _i459;
import 'package:gasosa_app/core/di/register_module.dart' as _i53;
import 'package:gasosa_app/core/viewmodel/loading_controller.dart' as _i209;
import 'package:gasosa_app/data/local/dao/refuel_dao.dart' as _i621;
import 'package:gasosa_app/data/local/dao/user_dao.dart' as _i876;
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart' as _i353;
import 'package:gasosa_app/data/local/db/app_database.dart' as _i409;
import 'package:gasosa_app/data/repositories/refuel_repository_impl.dart'
    as _i146;
import 'package:gasosa_app/data/repositories/user_repository_impl.dart' as _i57;
import 'package:gasosa_app/data/repositories/vehicle_repository_impl.dart'
    as _i106;
import 'package:gasosa_app/domain/repositories/refuel_repository.dart' as _i857;
import 'package:gasosa_app/domain/repositories/user_repository.dart' as _i754;
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart' as _i35;
import 'package:gasosa_app/domain/services/auth_service.dart' as _i602;
import 'package:gasosa_app/domain/services/firebase_auth_service.dart' as _i40;
import 'package:gasosa_app/domain/services/local_photo_storage.dart' as _i312;
import 'package:gasosa_app/domain/services/local_photo_storage_impl.dart'
    as _i959;
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
    gh.lazySingleton<_i583.GoRouter>(() => registerModule.router);
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    await gh.lazySingletonAsync<_i116.GoogleSignIn>(
      () => registerModule.googleSignIn,
      preResolve: true,
    );
    gh.lazySingleton<_i409.AppDatabase>(() => registerModule.appDatabase);
    gh.lazySingleton<_i209.LoadingController>(() => _i209.LoadingController());
    gh.lazySingleton<_i188.RefuelBusinessRules>(
      () => const _i188.RefuelBusinessRules(),
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
    gh.lazySingleton<_i312.LocalPhotoStorage>(
      () => _i959.LocalPhotoStorageImpl(),
    );
    gh.lazySingleton<_i857.RefuelRepository>(
      () => _i146.RefuelRepositoryImpl(gh<_i621.RefuelDao>()),
    );
    gh.lazySingleton<_i35.VehicleRepository>(
      () => _i106.VehicleRepositoryImpl(gh<_i353.VehicleDao>()),
    );
    gh.lazySingleton<_i602.AuthService>(
      () => _i40.FirebaseAuthService(
        auth: gh<_i59.FirebaseAuth>(),
        google: gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i754.UserRepository>(
      () => _i57.UserRepositoryImpl(gh<_i876.UserDao>()),
    );
    gh.factory<_i458.DeletePhotoCommand>(
      () => _i458.DeletePhotoCommand(gh<_i312.LocalPhotoStorage>()),
    );
    gh.factory<_i180.SavePhotoCommand>(
      () => _i180.SavePhotoCommand(gh<_i312.LocalPhotoStorage>()),
    );
    gh.factory<_i53.CalculateConsumptionCommand>(
      () => _i53.CalculateConsumptionCommand(
        repository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i188.CreateOrUpdateRefuelCommand>(
      () => _i188.CreateOrUpdateRefuelCommand(
        repository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i142.DeleteRefuelCommand>(
      () => _i142.DeleteRefuelCommand(repository: gh<_i857.RefuelRepository>()),
    );
    gh.factory<_i237.LoadRefuelsByVehicleCommand>(
      () => _i237.LoadRefuelsByVehicleCommand(
        repository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i1034.ManageRefuelViewmodel>(
      () => _i1034.ManageRefuelViewmodel(
        repository: gh<_i857.RefuelRepository>(),
        vehicleRepository: gh<_i35.VehicleRepository>(),
        loading: gh<_i209.LoadingController>(),
        saveRefuel: gh<_i188.CreateOrUpdateRefuelCommand>(),
        saveReceiptPhoto: gh<_i180.SavePhotoCommand>(),
        deleteReceiptPhoto: gh<_i458.DeletePhotoCommand>(),
        deleteRefuel: gh<_i142.DeleteRefuelCommand>(),
        businessRules: gh<_i188.RefuelBusinessRules>(),
      ),
    );
    gh.factory<_i318.LoginWithGoogleCommand>(
      () => _i318.LoginWithGoogleCommand(auth: gh<_i602.AuthService>()),
    );
    gh.factory<_i13.LoginEmailPasswordCommand>(
      () => _i13.LoginEmailPasswordCommand(auth: gh<_i602.AuthService>()),
    );
    gh.factory<_i728.RegisterCommand>(
      () => _i728.RegisterCommand(auth: gh<_i602.AuthService>()),
    );
    gh.factory<_i328.CreateOrUpdateVehicleCommand>(
      () => _i328.CreateOrUpdateVehicleCommand(
        repository: gh<_i35.VehicleRepository>(),
      ),
    );
    gh.factory<_i215.DeleteVehicleCommand>(
      () =>
          _i215.DeleteVehicleCommand(repository: gh<_i35.VehicleRepository>()),
    );
    gh.factory<_i459.LoadVehiclesCommand>(
      () => _i459.LoadVehiclesCommand(repository: gh<_i35.VehicleRepository>()),
    );
    gh.factory<_i464.VehicleDetailViewModel>(
      () => _i464.VehicleDetailViewModel(
        repository: gh<_i35.VehicleRepository>(),
        delete: gh<_i215.DeleteVehicleCommand>(),
        loading: gh<_i209.LoadingController>(),
        refuelRepository: gh<_i857.RefuelRepository>(),
      ),
    );
    gh.factory<_i212.ManageVehicleViewModel>(
      () => _i212.ManageVehicleViewModel(
        repository: gh<_i35.VehicleRepository>(),
        saveVehicle: gh<_i328.CreateOrUpdateVehicleCommand>(),
        deleteVehicle: gh<_i215.DeleteVehicleCommand>(),
        savePhoto: gh<_i180.SavePhotoCommand>(),
        deletePhoto: gh<_i458.DeletePhotoCommand>(),
        loading: gh<_i209.LoadingController>(),
      ),
    );
    gh.factory<_i788.LoginViewModel>(
      () => _i788.LoginViewModel(
        loginGoogle: gh<_i318.LoginWithGoogleCommand>(),
        loginEmailPassword: gh<_i13.LoginEmailPasswordCommand>(),
        loading: gh<_i209.LoadingController>(),
      ),
    );
    gh.factory<_i327.DashboardViewModel>(
      () => _i327.DashboardViewModel(
        loadVehicles: gh<_i459.LoadVehiclesCommand>(),
        loading: gh<_i209.LoadingController>(),
        deleteVehicle: gh<_i215.DeleteVehicleCommand>(),
      ),
    );
    gh.factory<_i979.RegisterViewModel>(
      () => _i979.RegisterViewModel(
        registerCommand: gh<_i728.RegisterCommand>(),
        loading: gh<_i209.LoadingController>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i53.RegisterModule {}
