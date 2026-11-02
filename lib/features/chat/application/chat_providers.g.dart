// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatSeenStore)
final chatSeenStoreProvider = ChatSeenStoreProvider._();

final class ChatSeenStoreProvider
    extends $FunctionalProvider<ChatSeenStore, ChatSeenStore, ChatSeenStore>
    with $Provider<ChatSeenStore> {
  ChatSeenStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatSeenStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSeenStoreHash();

  @$internal
  @override
  $ProviderElement<ChatSeenStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatSeenStore create(Ref ref) {
    return chatSeenStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatSeenStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatSeenStore>(value),
    );
  }
}

String _$chatSeenStoreHash() => r'c83df972218dda7e09350e96bec4fa885f3307ac';

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryFamily._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._({
    required ChatRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @override
  String toString() {
    return r'chatRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    final argument = this.argument as String;
    return chatRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatRepositoryHash() => r'76e2014cd340fe8283cc86c1a5bac1148a4db892';

final class ChatRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<ChatRepository, String> {
  ChatRepositoryFamily._()
    : super(
        retry: null,
        name: r'chatRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ChatRepositoryProvider call(String circleId) =>
      ChatRepositoryProvider._(argument: circleId, from: this);

  @override
  String toString() => r'chatRepositoryProvider';
}

@ProviderFor(circleMessages)
final circleMessagesProvider = CircleMessagesFamily._();

final class CircleMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  CircleMessagesProvider._({
    required CircleMessagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'circleMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$circleMessagesHash();

  @override
  String toString() {
    return r'circleMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as String;
    return circleMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CircleMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$circleMessagesHash() => r'2d307980f64450660dfa0a9097e14507f12524c6';

final class CircleMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, String> {
  CircleMessagesFamily._()
    : super(
        retry: null,
        name: r'circleMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CircleMessagesProvider call(String circleId) =>
      CircleMessagesProvider._(argument: circleId, from: this);

  @override
  String toString() => r'circleMessagesProvider';
}

/// The moment this device last looked at the thread, restored after restarts
/// so the map's badge only counts messages the member has not opened yet.

@ProviderFor(ChatSeenController)
final chatSeenControllerProvider = ChatSeenControllerFamily._();

/// The moment this device last looked at the thread, restored after restarts
/// so the map's badge only counts messages the member has not opened yet.
final class ChatSeenControllerProvider
    extends $NotifierProvider<ChatSeenController, DateTime> {
  /// The moment this device last looked at the thread, restored after restarts
  /// so the map's badge only counts messages the member has not opened yet.
  ChatSeenControllerProvider._({
    required ChatSeenControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatSeenControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatSeenControllerHash();

  @override
  String toString() {
    return r'chatSeenControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatSeenController create() => ChatSeenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSeenControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatSeenControllerHash() =>
    r'45e3c48ce3d1622a8d9f35d1906a9628d8fbc62d';

/// The moment this device last looked at the thread, restored after restarts
/// so the map's badge only counts messages the member has not opened yet.

final class ChatSeenControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatSeenController,
          DateTime,
          DateTime,
          DateTime,
          String
        > {
  ChatSeenControllerFamily._()
    : super(
        retry: null,
        name: r'chatSeenControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The moment this device last looked at the thread, restored after restarts
  /// so the map's badge only counts messages the member has not opened yet.

  ChatSeenControllerProvider call(String circleId) =>
      ChatSeenControllerProvider._(argument: circleId, from: this);

  @override
  String toString() => r'chatSeenControllerProvider';
}

/// The moment this device last looked at the thread, restored after restarts
/// so the map's badge only counts messages the member has not opened yet.

abstract class _$ChatSeenController extends $Notifier<DateTime> {
  late final _$args = ref.$arg as String;
  String get circleId => _$args;

  DateTime build(String circleId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(chatUnreadCount)
final chatUnreadCountProvider = ChatUnreadCountFamily._();

final class ChatUnreadCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  ChatUnreadCountProvider._({
    required ChatUnreadCountFamily super.from,
    required ChatUnreadQuery super.argument,
  }) : super(
         retry: null,
         name: r'chatUnreadCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatUnreadCountHash();

  @override
  String toString() {
    return r'chatUnreadCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as ChatUnreadQuery;
    return chatUnreadCount(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatUnreadCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatUnreadCountHash() => r'82ed24f4bd10a6e39ad13cf8e27d1900473a29a3';

final class ChatUnreadCountFamily extends $Family
    with $FunctionalFamilyOverride<int, ChatUnreadQuery> {
  ChatUnreadCountFamily._()
    : super(
        retry: null,
        name: r'chatUnreadCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatUnreadCountProvider call(ChatUnreadQuery query) =>
      ChatUnreadCountProvider._(argument: query, from: this);

  @override
  String toString() => r'chatUnreadCountProvider';
}
