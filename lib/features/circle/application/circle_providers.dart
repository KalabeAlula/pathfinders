import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/supabase_circle_repository.dart';
import '../domain/circle_repository.dart';
import '../domain/circle_snapshot.dart';

part 'circle_providers.g.dart';

@Riverpod(keepAlive: true)
CircleRepository circleRepository(Ref ref, String userId) =>
    SupabaseCircleRepository(
      ref.watch(supabaseClientProvider),
      userId: userId,
    );

@riverpod
Stream<CircleSnapshot?> circleSnapshot(Ref ref, String userId) =>
    ref.watch(circleRepositoryProvider(userId)).watchCircle();
