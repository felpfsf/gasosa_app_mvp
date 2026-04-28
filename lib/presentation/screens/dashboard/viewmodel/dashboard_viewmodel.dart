import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/sync/sync_use_case.dart';
import 'package:gasosa_app/application/vehicles/load_vehicles_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/stream_command.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class DashboardViewModel {
  DashboardViewModel(
    this._auth,
    this._loadVehicles,
    this._sync,
    this._userRepository,
  ) : watchVehicles = StreamCommand<List<VehicleEntity>>();

  final AuthService _auth;
  final LoadVehiclesUseCase _loadVehicles;
  final SyncUseCase _sync;
  final UserRepository _userRepository;

  final StreamCommand<List<VehicleEntity>> watchVehicles;
  final ValueNotifier<AuthUser?> _currentUser = ValueNotifier(null);
  ValueListenable<AuthUser?> get currentUser => _currentUser;

  /// Foto local do usuário (prioridade sobre photoUrl do AuthUser).
  final ValueNotifier<File?> _localAvatar = ValueNotifier(null);
  ValueListenable<File?> get localAvatar => _localAvatar;

  StreamSubscription<AuthUser?>? _userChangesSubscription;
  StreamSubscription<Either<Failure, AuthUser?>>? _watchUserSubscription;

  Future<void> init() async {
    _currentUser.value = await _auth.currentUser();

    // Reage a atualizações de perfil (ex: displayName após registro)
    _userChangesSubscription?.cancel();
    _userChangesSubscription = _auth.userChanges().listen((user) {
      if (user != null) _currentUser.value = user;
    });

    final uid = _currentUser.value?.id;
    if (uid == null || uid.isEmpty) {
      watchVehicles.state.value = const UiError(ValidationFailure('Usuário não autenticado'));
      return;
    }

    // Observa foto local do usuário no banco
    _watchUserSubscription?.cancel();
    _watchUserSubscription = _userRepository.watchUser(uid).listen((either) {
      either.fold(
        (_) {},
        (user) {
          final path = user?.photoUrl;
          _localAvatar.value = (path != null && path.isNotEmpty) ? File(path) : null;
        },
      );
    });

    // Sync cloud ↔ local antes de carregar veículos
    dev.log('[Dashboard] triggering sync for user=$uid', name: 'sync');
    unawaited(
      _sync()
          .then((result) {
            result.fold(
              (f) => dev.log('[Dashboard] sync failed: $f', name: 'sync'),
              (r) => dev.log('[Dashboard] sync ok: total=${r.total}', name: 'sync'),
            );
          })
          .catchError((Object e, StackTrace st) {
            dev.log('[Dashboard] sync error: $e', name: 'sync', error: e, stackTrace: st);
          }),
    );

    watchVehicles.watch(
      () => _loadVehicles(uid).transform(
        StreamTransformer.fromHandlers(
          handleData: (either, sink) => either.fold(
            (f) => sink.addError(f),
            (v) => sink.add(v),
          ),
        ),
      ),
      keepLastData: true,
    );
  }

  Future<void> refresh() async {
    dev.log('[Dashboard] pull-to-refresh: syncing...', name: 'sync');
    try {
      final result = await _sync();
      result.fold(
        (f) => dev.log('[Dashboard] refresh sync failed: $f', name: 'sync'),
        (r) => dev.log('[Dashboard] refresh sync ok: total=${r.total}', name: 'sync'),
      );
    } catch (e, st) {
      dev.log('[Dashboard] refresh sync error: $e', name: 'sync', error: e, stackTrace: st);
    }
  }

  void retry() => init();

  void dispose() {
    _userChangesSubscription?.cancel();
    _watchUserSubscription?.cancel();
    watchVehicles.dispose();
    _currentUser.dispose();
    _localAvatar.dispose();
  }
}
