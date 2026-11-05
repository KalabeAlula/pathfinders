// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryFamily._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._({
    required ProfileRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profileRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @override
  String toString() {
    return r'profileRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    final argument = this.argument as String;
    return profileRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileRepositoryHash() => r'f011467c10feb078f73beb4dcebd3f9a12a7b070';

final class ProfileRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<ProfileRepository, String> {
  ProfileRepositoryFamily._()
    : super(
        retry: null,
        name: r'profileRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ProfileRepositoryProvider call(String userId) =>
      ProfileRepositoryProvider._(argument: userId, from: this);

  @override
  String toString() => r'profileRepositoryProvider';
}

/// The member's own profile, kept live so the header and avatar picker follow
/// changes made on another device.

@ProviderFor(ProfileController)
final profileControllerProvider = ProfileControllerFamily._();

/// The member's own profile, kept live so the header and avatar picker follow
/// changes made on another device.
final class ProfileControllerProvider
    extends $NotifierProvider<ProfileController, AsyncValue<ProfileDetails>> {
  /// The member's own profile, kept live so the header and avatar picker follow
  /// changes made on another device.
  ProfileControllerProvider._({
    required ProfileControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profileControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileControllerHash();

  @override
  String toString() {
    return r'profileControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProfileController create() => ProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ProfileDetails> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ProfileDetails>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileControllerHash() => r'73b8bbcf732985ebcbf3681b6a044fa810fc748e';

/// The member's own profile, kept live so the header and avatar picker follow
/// changes made on another device.

final class ProfileControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfileController,
          AsyncValue<ProfileDetails>,
          AsyncValue<ProfileDetails>,
          AsyncValue<ProfileDetails>,
          String
        > {
  ProfileControllerFamily._()
    : super(
        retry: null,
        name: r'profileControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The member's own profile, kept live so the header and avatar picker follow
  /// changes made on another device.

  ProfileControllerProvider call(String userId) =>
      ProfileControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'profileControllerProvider';
}

/// The member's own profile, kept live so the header and avatar picker follow
/// changes made on another device.

abstract class _$ProfileController
    extends $Notifier<AsyncValue<ProfileDetails>> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  AsyncValue<ProfileDetails> build(String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ProfileDetails>, AsyncValue<ProfileDetails>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ProfileDetails>,
                AsyncValue<ProfileDetails>
              >,
              AsyncValue<ProfileDetails>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
