// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatNotifications)
final chatNotificationsProvider = ChatNotificationsProvider._();

final class ChatNotificationsProvider
    extends $FunctionalProvider<ChatNotifier, ChatNotifier, ChatNotifier>
    with $Provider<ChatNotifier> {
  ChatNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatNotificationsHash();

  @$internal
  @override
  $ProviderElement<ChatNotifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatNotifier create(Ref ref) {
    return chatNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatNotifier>(value),
    );
  }
}

String _$chatNotificationsHash() => r'6529890df9989bbf0e73e5d607f926a30a3a70cd';

/// The circle a chat notification tap asked to open. The shell consumes it
/// once, so the request survives the frame that switches both tab and circle.

@ProviderFor(ChatNotificationTarget)
final chatNotificationTargetProvider = ChatNotificationTargetProvider._();

/// The circle a chat notification tap asked to open. The shell consumes it
/// once, so the request survives the frame that switches both tab and circle.
final class ChatNotificationTargetProvider
    extends $NotifierProvider<ChatNotificationTarget, String?> {
  /// The circle a chat notification tap asked to open. The shell consumes it
  /// once, so the request survives the frame that switches both tab and circle.
  ChatNotificationTargetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatNotificationTargetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatNotificationTargetHash();

  @$internal
  @override
  ChatNotificationTarget create() => ChatNotificationTarget();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$chatNotificationTargetHash() =>
    r'9b6dd452bc7ceeed8e05587e1bf0acb5c122529e';

/// The circle a chat notification tap asked to open. The shell consumes it
/// once, so the request survives the frame that switches both tab and circle.

abstract class _$ChatNotificationTarget extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Turns notification taps into a pending chat target.
///
/// Lives above the signed-in shell so a cold-start tap is not lost while the
/// session gate is still resolving.

@ProviderFor(chatNotificationRouter)
final chatNotificationRouterProvider = ChatNotificationRouterProvider._();

/// Turns notification taps into a pending chat target.
///
/// Lives above the signed-in shell so a cold-start tap is not lost while the
/// session gate is still resolving.

final class ChatNotificationRouterProvider
    extends
        $FunctionalProvider<
          ChatNotificationRouter,
          ChatNotificationRouter,
          ChatNotificationRouter
        >
    with $Provider<ChatNotificationRouter> {
  /// Turns notification taps into a pending chat target.
  ///
  /// Lives above the signed-in shell so a cold-start tap is not lost while the
  /// session gate is still resolving.
  ChatNotificationRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatNotificationRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatNotificationRouterHash();

  @$internal
  @override
  $ProviderElement<ChatNotificationRouter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatNotificationRouter create(Ref ref) {
    return chatNotificationRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatNotificationRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatNotificationRouter>(value),
    );
  }
}

String _$chatNotificationRouterHash() =>
    r'f0420f1e3db6d464df8ac1c822523512b96bd609';
