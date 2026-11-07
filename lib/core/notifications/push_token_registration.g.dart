// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token_registration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps this device reachable by cloud push for the signed-in member.
///
/// FlutterFire 17 registers through Firebase Installations and hands back the
/// installation ID, which is what the server sends to. The shell watches this
/// for the whole session; signing out disposes it and removes the row, so the
/// device drops off the old account's delivery list.
///
/// This is also where the tray permission is requested, because the push
/// handler cannot show anything without it.

@ProviderFor(pushTokenRegistration)
final pushTokenRegistrationProvider = PushTokenRegistrationFamily._();

/// Keeps this device reachable by cloud push for the signed-in member.
///
/// FlutterFire 17 registers through Firebase Installations and hands back the
/// installation ID, which is what the server sends to. The shell watches this
/// for the whole session; signing out disposes it and removes the row, so the
/// device drops off the old account's delivery list.
///
/// This is also where the tray permission is requested, because the push
/// handler cannot show anything without it.

final class PushTokenRegistrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Keeps this device reachable by cloud push for the signed-in member.
  ///
  /// FlutterFire 17 registers through Firebase Installations and hands back the
  /// installation ID, which is what the server sends to. The shell watches this
  /// for the whole session; signing out disposes it and removes the row, so the
  /// device drops off the old account's delivery list.
  ///
  /// This is also where the tray permission is requested, because the push
  /// handler cannot show anything without it.
  PushTokenRegistrationProvider._({
    required PushTokenRegistrationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pushTokenRegistrationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pushTokenRegistrationHash();

  @override
  String toString() {
    return r'pushTokenRegistrationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return pushTokenRegistration(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PushTokenRegistrationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pushTokenRegistrationHash() =>
    r'7b9acfec2ba9545347d246ec05eaa4193d455181';

/// Keeps this device reachable by cloud push for the signed-in member.
///
/// FlutterFire 17 registers through Firebase Installations and hands back the
/// installation ID, which is what the server sends to. The shell watches this
/// for the whole session; signing out disposes it and removes the row, so the
/// device drops off the old account's delivery list.
///
/// This is also where the tray permission is requested, because the push
/// handler cannot show anything without it.

final class PushTokenRegistrationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  PushTokenRegistrationFamily._()
    : super(
        retry: null,
        name: r'pushTokenRegistrationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps this device reachable by cloud push for the signed-in member.
  ///
  /// FlutterFire 17 registers through Firebase Installations and hands back the
  /// installation ID, which is what the server sends to. The shell watches this
  /// for the whole session; signing out disposes it and removes the row, so the
  /// device drops off the old account's delivery list.
  ///
  /// This is also where the tray permission is requested, because the push
  /// handler cannot show anything without it.

  PushTokenRegistrationProvider call(String userId) =>
      PushTokenRegistrationProvider._(argument: userId, from: this);

  @override
  String toString() => r'pushTokenRegistrationProvider';
}
