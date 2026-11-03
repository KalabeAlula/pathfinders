import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/active_circle_store.dart';
import '../data/supabase_circle_repository.dart';
import '../domain/circle_repository.dart';
import '../domain/circle_snapshot.dart';
import '../domain/circle_summary.dart';

part 'circle_providers.g.dart';

@Riverpod(keepAlive: true)
CircleRepository circleRepository(Ref ref, String userId) =>
    SupabaseCircleRepository(ref.watch(supabaseClientProvider), userId: userId);

@Riverpod(keepAlive: true)
ActiveCircleStore activeCircleStore(Ref ref) =>
    ActiveCircleStore(ref.watch(sharedPreferencesProvider));

/// Every group the signed-in member belongs to, oldest membership first.
@riverpod
Stream<List<CircleSummary>> circles(Ref ref, String userId) =>
    ref.watch(circleRepositoryProvider(userId)).watchCircles();

/// The group currently on screen. A saved id wins only while it still matches
/// a membership; otherwise the oldest group is used so a removed group cannot
/// leave the app pointing at nothing.
@Riverpod(keepAlive: true)
class ActiveCircleController extends _$ActiveCircleController {
  @override
  String? build(String userId) {
    final saved = ref.watch(activeCircleStoreProvider).read(userId);
    final circles = ref.watch(circlesProvider(userId));
    final memberships = circles.value ?? const <CircleSummary>[];
    if (memberships.isEmpty) return saved;
    if (saved == null) return memberships.first.id;
    if (memberships.any((circle) => circle.id == saved)) return saved;
    // A newly created group is selected before the refreshed list arrives.
    // Keep that choice while the list is still loading; once it settles
    // without the id, the membership is genuinely gone.
    if (circles.isLoading) return saved;
    return memberships.first.id;
  }

  Future<void> select(String circleId) async {
    await ref.read(activeCircleStoreProvider).write(userId, circleId);
    if (!ref.mounted) return;
    state = circleId;
  }
}

@riverpod
CircleSummary? activeCircle(Ref ref, String userId) {
  final activeId = ref.watch(activeCircleControllerProvider(userId));
  final memberships =
      ref.watch(circlesProvider(userId)).value ?? const <CircleSummary>[];
  for (final circle in memberships) {
    if (circle.id == activeId) return circle;
  }
  return null;
}

/// Live data for the active group. Changing the active id rebuilds this
/// stream, which cancels the previous repository subscription (and its
/// realtime channel) before the next one starts.
@riverpod
Stream<CircleSnapshot?> circleSnapshot(Ref ref, String userId) {
  final circleId = ref.watch(activeCircleControllerProvider(userId));
  if (circleId == null) return Stream<CircleSnapshot?>.value(null);
  return ref.watch(circleRepositoryProvider(userId)).watchCircle(circleId);
}
