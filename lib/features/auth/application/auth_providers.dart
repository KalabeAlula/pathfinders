import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    SupabaseAuthRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
Stream<AuthSession?> authSession(Ref ref) =>
    ref.watch(authRepositoryProvider).watchSession();
