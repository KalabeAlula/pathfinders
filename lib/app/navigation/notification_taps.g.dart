// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_taps.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Routes notification taps to the feature that owns each payload.
///
/// `NotificationPlugin` reports the cold-start payload to a single reader, so
/// one dispatcher reads it and hands it to every router. It lives above the
/// signed-in shell so a tap is not lost while the session gate is resolving.

@ProviderFor(notificationTapDispatcher)
final notificationTapDispatcherProvider = NotificationTapDispatcherProvider._();

/// Routes notification taps to the feature that owns each payload.
///
/// `NotificationPlugin` reports the cold-start payload to a single reader, so
/// one dispatcher reads it and hands it to every router. It lives above the
/// signed-in shell so a tap is not lost while the session gate is resolving.

final class NotificationTapDispatcherProvider
    extends
        $FunctionalProvider<
          NotificationTapDispatcher,
          NotificationTapDispatcher,
          NotificationTapDispatcher
        >
    with $Provider<NotificationTapDispatcher> {
  /// Routes notification taps to the feature that owns each payload.
  ///
  /// `NotificationPlugin` reports the cold-start payload to a single reader, so
  /// one dispatcher reads it and hands it to every router. It lives above the
  /// signed-in shell so a tap is not lost while the session gate is resolving.
  NotificationTapDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationTapDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationTapDispatcherHash();

  @$internal
  @override
  $ProviderElement<NotificationTapDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationTapDispatcher create(Ref ref) {
    return notificationTapDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationTapDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationTapDispatcher>(value),
    );
  }
}

String _$notificationTapDispatcherHash() =>
    r'2a7c0d20026b374dc9bb1a0a86006b3b4bb95963';
