import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../circle/domain/circle.dart';
import '../domain/pet_care_action.dart';
import '../domain/pet_repository.dart';
import '../domain/shared_pet.dart';

/// Care is a single membership-gated RPC so members cannot race each other's
/// stat writes; the updated circle row flows back through the circle channel.
class SupabasePetRepository implements PetRepository {
  SupabasePetRepository(this._client, {required this.circleId});

  final sb.SupabaseClient _client;
  final String circleId;

  @override
  Future<SharedPet> care(PetCareAction action) async {
    try {
      final data = await _client.rpc(
        'care_for_pet',
        params: {'p_circle_id': circleId, 'p_action': action.name},
      );
      final row = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
      return SharedPet.fromCircle(
        Circle.fromRow(row, memberIds: const []),
      );
    } on sb.PostgrestException catch (error) {
      throw StateError(error.message);
    }
  }
}
