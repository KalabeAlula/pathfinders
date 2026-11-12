// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'countdown_reminder_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(countdownReminderScheduler)
final countdownReminderSchedulerProvider =
    CountdownReminderSchedulerProvider._();

final class CountdownReminderSchedulerProvider
    extends
        $FunctionalProvider<
          CountdownReminderScheduler,
          CountdownReminderScheduler,
          CountdownReminderScheduler
        >
    with $Provider<CountdownReminderScheduler> {
  CountdownReminderSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countdownReminderSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countdownReminderSchedulerHash();

  @$internal
  @override
  $ProviderElement<CountdownReminderScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CountdownReminderScheduler create(Ref ref) {
    return countdownReminderScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountdownReminderScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountdownReminderScheduler>(value),
    );
  }
}

String _$countdownReminderSchedulerHash() =>
    r'5402d7f96fd272026381a81501b88378084b7478';

/// The countdown a reminder tap asked to open. The shell consumes it once,
/// after switching the circle and the tab, so the request survives the frames
/// in between.

@ProviderFor(CountdownReminderTarget)
final countdownReminderTargetProvider = CountdownReminderTargetProvider._();

/// The countdown a reminder tap asked to open. The shell consumes it once,
/// after switching the circle and the tab, so the request survives the frames
/// in between.
final class CountdownReminderTargetProvider
    extends $NotifierProvider<CountdownReminderTarget, CountdownTap?> {
  /// The countdown a reminder tap asked to open. The shell consumes it once,
  /// after switching the circle and the tab, so the request survives the frames
  /// in between.
  CountdownReminderTargetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countdownReminderTargetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countdownReminderTargetHash();

  @$internal
  @override
  CountdownReminderTarget create() => CountdownReminderTarget();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountdownTap? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CountdownTap?>(value),
    );
  }
}

String _$countdownReminderTargetHash() =>
    r'a3c07d788ef77b4d2c4eb1c8fc862624ba5d2d91';

/// The countdown a reminder tap asked to open. The shell consumes it once,
/// after switching the circle and the tab, so the request survives the frames
/// in between.

abstract class _$CountdownReminderTarget extends $Notifier<CountdownTap?> {
  CountdownTap? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CountdownTap?, CountdownTap?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CountdownTap?, CountdownTap?>,
              CountdownTap?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Keeps the OS alarm queue in step with the countdowns this member can see.
///
/// Watched from the circle gate, which stays mounted for the whole signed-in
/// session, so every circle's milestones and every edit reach the scheduler.

@ProviderFor(countdownReminders)
final countdownRemindersProvider = CountdownRemindersFamily._();

/// Keeps the OS alarm queue in step with the countdowns this member can see.
///
/// Watched from the circle gate, which stays mounted for the whole signed-in
/// session, so every circle's milestones and every edit reach the scheduler.

final class CountdownRemindersProvider
    extends
        $FunctionalProvider<
          List<CountdownReminder>,
          List<CountdownReminder>,
          List<CountdownReminder>
        >
    with $Provider<List<CountdownReminder>> {
  /// Keeps the OS alarm queue in step with the countdowns this member can see.
  ///
  /// Watched from the circle gate, which stays mounted for the whole signed-in
  /// session, so every circle's milestones and every edit reach the scheduler.
  CountdownRemindersProvider._({
    required CountdownRemindersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'countdownRemindersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$countdownRemindersHash();

  @override
  String toString() {
    return r'countdownRemindersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<CountdownReminder>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CountdownReminder> create(Ref ref) {
    final argument = this.argument as String;
    return countdownReminders(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CountdownReminder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CountdownReminder>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CountdownRemindersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$countdownRemindersHash() =>
    r'233e53ea55d58b2af495a48b694d0f898994d466';

/// Keeps the OS alarm queue in step with the countdowns this member can see.
///
/// Watched from the circle gate, which stays mounted for the whole signed-in
/// session, so every circle's milestones and every edit reach the scheduler.

final class CountdownRemindersFamily extends $Family
    with $FunctionalFamilyOverride<List<CountdownReminder>, String> {
  CountdownRemindersFamily._()
    : super(
        retry: null,
        name: r'countdownRemindersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps the OS alarm queue in step with the countdowns this member can see.
  ///
  /// Watched from the circle gate, which stays mounted for the whole signed-in
  /// session, so every circle's milestones and every edit reach the scheduler.

  CountdownRemindersProvider call(String userId) =>
      CountdownRemindersProvider._(argument: userId, from: this);

  @override
  String toString() => r'countdownRemindersProvider';
}
