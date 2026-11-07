// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token_registration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps this device's FCM token tied to the signed-in member.
///
/// The shell watches this for the whole session. Signing out disposes it and
/// removes the row, so the device drops off the old account's delivery list.

@ProviderFor(pushTokenRegistration)
final pushTokenRegistrationProvider = PushTokenRegistrationFamily._();

/// Keeps this device's FCM token tied to the signed-in member.
///
/// The shell watches this for the whole session. Signing out disposes it and
/// removes the row, so the device drops off the old account's delivery list.

final class PushTokenRegistrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Keeps this device's FCM token tied to the signed-in member.
  ///
  /// The shell watches this for the whole session. Signing out disposes it and
  /// removes the row, so the device drops off the old account's delivery list.
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
    r'11f9afff37f85883d7e64d51ca2369ced5ce6550';

/// Keeps this device's FCM token tied to the signed-in member.
///
/// The shell watches this for the whole session. Signing out disposes it and
/// removes the row, so the device drops off the old account's delivery list.

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

  /// Keeps this device's FCM token tied to the signed-in member.
  ///
  /// The shell watches this for the whole session. Signing out disposes it and
  /// removes the row, so the device drops off the old account's delivery list.

  PushTokenRegistrationProvider call(String userId) =>
      PushTokenRegistrationProvider._(argument: userId, from: this);

  @override
  String toString() => r'pushTokenRegistrationProvider';
}
