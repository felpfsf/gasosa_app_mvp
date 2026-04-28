import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/auth/delete_account_use_case.dart';
import 'package:gasosa_app/application/auth/logout_use_case.dart';
import 'package:gasosa_app/application/auth/remove_user_avatar_use_case.dart';
import 'package:gasosa_app/application/auth/update_display_name_use_case.dart';
import 'package:gasosa_app/application/auth/update_user_avatar_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileViewModel {
  ProfileViewModel(
    this._auth,
    this._userRepository,
    this._updateAvatar,
    this._removeAvatar,
    this._updateDisplayName,
    this._logout,
    this._deleteAccount,
  );

  final AuthService _auth;
  final UserRepository _userRepository;
  final UpdateUserAvatarUseCase _updateAvatar;
  final RemoveUserAvatarUseCase _removeAvatar;
  final UpdateDisplayNameUseCase _updateDisplayName;
  final LogoutUseCase _logout;
  final DeleteAccountUseCase _deleteAccount;

  final ValueNotifier<AuthUser?> _currentUser = ValueNotifier(null);
  ValueListenable<AuthUser?> get currentUser => _currentUser;

  final ValueNotifier<File?> _localAvatar = ValueNotifier(null);
  ValueListenable<File?> get localAvatar => _localAvatar;

  StreamSubscription<AuthUser?>? _userChangesSubscription;
  StreamSubscription<Either<Failure, AuthUser?>>? _watchUserSubscription;

  Future<void> init() async {
    _currentUser.value = await _auth.currentUser();

    _userChangesSubscription?.cancel();
    _userChangesSubscription = _auth.userChanges().listen((user) {
      if (user != null) _currentUser.value = user;
    });

    final uid = _currentUser.value?.id;
    if (uid == null || uid.isEmpty) return;

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
  }

  Future<Either<Failure, String>> updateAvatar(File file) async {
    final result = await _updateAvatar(file);
    result.fold(
      (_) {},
      (newPath) => _localAvatar.value = File(newPath),
    );
    return result;
  }

  Future<Either<Failure, void>> removeAvatar() async {
    final result = await _removeAvatar();
    if (result.isRight) _localAvatar.value = null;
    return result;
  }

  Future<Either<Failure, void>> updateDisplayName(String name) => _updateDisplayName(name);

  Future<Either<Failure, void>> logout() => _logout();

  Future<Either<Failure, void>> deleteAccount() => _deleteAccount();

  void dispose() {
    _userChangesSubscription?.cancel();
    _watchUserSubscription?.cancel();
    _currentUser.dispose();
    _localAvatar.dispose();
  }
}
