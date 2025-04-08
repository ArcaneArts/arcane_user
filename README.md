Easily construct a user service with Arcane & FireCrud

1. Define your user models
```dart
class MyUser with ModelCrud {
  @override
  List<FireModel<ModelCrud>> get childModels => [
    FireModel<MyCapabilities>(
      model: MyCapabilities(),
      collection: "data",
      exclusiveDocumentId: "capabilities",
      fromMap: (_) => MyCapabilities(),
      toMap: (_) => {},
    ),
    FireModel<MySettings>(
      model: MySettings(),
      collection: "data",
      exclusiveDocumentId: "settings",
      fromMap: (_) => MySettings(),
      toMap: (_) => {},
    ),
  ];
}

class MyCapabilities with ModelCrud {
  @override
  List<FireModel<ModelCrud>> get childModels => [];
}

class MySettings with ModelCrud {
  @override
  List<FireModel<ModelCrud>> get childModels => [];
}
```

2. Create your user service

```dart
// You can define global accessors for your stuff like so
Stream<MyUser?> get $userStream => svc<UserService>().$userStream;
Stream<MySettings?> get $settingsStream => svc<UserService>().$settingsStream;
Stream<MyCapabilities?> get $capabilitiesStream =>
    svc<UserService>().$capabilitiesStream;
MyUser get $user => svc<UserService>().$user;
MySettings get $settings => svc<UserService>().$settings;
MyCapabilities get $capabilities => svc<UserService>().$capabilities;

// User service macro
class UserService extends ArcaneUserService<MyUser, MyCapabilities, MySettings> {
  @override
  MyCapabilities createUserCapabilitiesModel(UserMeta meta) => MyCapabilities();

  @override
  MyUser createUserModel(UserMeta meta) => MyUser();

  @override
  MySettings createUserSettingsModel(UserMeta meta) => MySettings();
  
  // Optional event methods
  void onLoggedIn(U user) {}
  Future<void> onPreSignOut() async {}
  Future<void> onPostSignOut() async {}
  Future<void> onPostBind(U user) async {}
  Future<void> onPostUnbind() async {}
}
```