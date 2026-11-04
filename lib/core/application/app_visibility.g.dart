// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appVisibility)
final appVisibilityProvider = AppVisibilityProvider._();

final class AppVisibilityProvider
    extends $FunctionalProvider<AppVisibility, AppVisibility, AppVisibility>
    with $Provider<AppVisibility> {
  AppVisibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVisibilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVisibilityHash();

  @$internal
  @override
  $ProviderElement<AppVisibility> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppVisibility create(Ref ref) {
    return appVisibility(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppVisibility value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppVisibility>(value),
    );
  }
}

String _$appVisibilityHash() => r'3b6430cf4602367ebd706e6f54e7ae6659a3d3bf';
