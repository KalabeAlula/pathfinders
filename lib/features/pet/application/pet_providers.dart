import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/supabase_pet_repository.dart';
import '../domain/pet_repository.dart';

part 'pet_providers.g.dart';

@Riverpod(keepAlive: true)
PetRepository petRepository(Ref ref, String circleId) {
  return SupabasePetRepository(
    ref.watch(supabaseClientProvider),
    circleId: circleId,
  );
}
