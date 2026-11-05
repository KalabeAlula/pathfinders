// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_tab.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Remembers the selected destination so it survives rebuilds triggered by
/// circle data, nudges, or telemetry.

@ProviderFor(ActiveTabController)
final activeTabControllerProvider = ActiveTabControllerProvider._();

/// Remembers the selected destination so it survives rebuilds triggered by
/// circle data, nudges, or telemetry.
final class ActiveTabControllerProvider
    extends $NotifierProvider<ActiveTabController, AppTab> {
  /// Remembers the selected destination so it survives rebuilds triggered by
  /// circle data, nudges, or telemetry.
  ActiveTabControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeTabControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeTabControllerHash();

  @$internal
  @override
  ActiveTabController create() => ActiveTabController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppTab value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppTab>(value),
    );
  }
}

String _$activeTabControllerHash() =>
    r'e88b632057ceb1db94442d00ac5f04804788672f';

/// Remembers the selected destination so it survives rebuilds triggered by
/// circle data, nudges, or telemetry.

abstract class _$ActiveTabController extends $Notifier<AppTab> {
  AppTab build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppTab, AppTab>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppTab, AppTab>,
              AppTab,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
