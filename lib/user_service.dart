import 'dart:async';

import 'package:arcane_auth/arcane_auth.dart';
import 'package:fast_log/fast_log.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:serviced/serviced.dart';
import 'package:toxic/toxic.dart';

abstract class ArcaneUserService<
  U extends ModelCrud,
  C extends ModelCrud,
  S extends ModelCrud
>
    extends StatelessService {
  ////////
  Stream<U?> get $userStream => _user;
  Stream<S?> get $settingsStream => _settings;
  Stream<C?> get $capabilitiesStream => _capabilities;
  U get $user => _user.value!;
  S get $settings => _settings.value!;
  C get $capabilities => _capabilities.value!;
  ////////
  final BehaviorSubject<U?> _user = BehaviorSubject.seeded(null);
  final BehaviorSubject<S?> _settings = BehaviorSubject.seeded(null);
  final BehaviorSubject<C?> _capabilities = BehaviorSubject.seeded(null);
  StreamSubscription<U?>? _uSubscription;
  StreamSubscription<S?>? _sSubscription;
  StreamSubscription<C?>? _cSubscription;

  U createUserModel(UserMeta meta);
  C createUserCapabilitiesModel(UserMeta meta);
  S createUserSettingsModel(UserMeta meta);
  void onLoggedIn(U user) {}
  Future<void> onPreSignOut() async {}
  Future<void> onPostSignOut() async {}
  Future<void> onPostBind(U user) async {}
  Future<void> onPostUnbind() async {}
  ArcaneUserService();

  Future<void> signOut(BuildContext context) async {
    await onPreSignOut();
    await svc<AuthService>().signOut(context);
    await onPostSignOut();
  }

  Future<void> bind(UserMeta user) async {
    List<Future> work = [];
    work.add(
      $crud
          .$ensureExists<U>(user.user.uid, createUserModel(user))
          .bang
          .then((i) => _user.add(i)),
    );
    work.add(
      $crud
          .$model<U>(user.user.uid)
          .ensureExistsUnique<S>(createUserSettingsModel(user))
          .bang
          .then((i) => _settings.add(i)),
    );
    work.add(
      $crud
          .$model<U>(user.user.uid)
          .getUnique<C>()
          .then((i) => i ?? createUserCapabilitiesModel(user))
          .then((i) => _capabilities.add(i)),
    );
    await Future.wait(work);
    _uSubscription = $crud.$stream<U>(user.user.uid).listen(_user.add);
    _sSubscription = $crud
        .$model<U>(user.user.uid)
        .streamUnique<S>()
        .listen(_settings.add);
    _cSubscription = $crud
        .$model<U>(user.user.uid)
        .streamUnique<C>()
        .map((i) => i ?? createUserCapabilitiesModel(user))
        .listen(_capabilities.add);
    try {
      onLoggedIn(_user.value!);
    } catch (e, es) {}

    try {
      await onPostBind(_user.value!);
    } catch (e, es) {
      error("Failed to post bind service after user sign-in.");
      error(e);
      error(es);
    }
  }

  Future<void> unbind() async {
    await Future.wait([
      _uSubscription?.cancel() ?? Future.value(),
      _sSubscription?.cancel() ?? Future.value(),
      _cSubscription?.cancel() ?? Future.value(),
    ]);
    _user.add(null);
    _settings.add(null);
    _capabilities.add(null);
    try {
      await onPostUnbind();
    } catch (e, es) {
      error("Failed to post unbind service after user sign-out.");
      error(e);
      error(es);
    }
  }
}
