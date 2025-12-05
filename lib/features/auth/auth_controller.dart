import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

final authProvider = StreamProvider<AuthState>((ref) {
  return SupabaseClientConfig.instance.auth.onAuthStateChange;
});

final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.session?.user;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  
  try {
    final data = await SupabaseClientConfig.instance
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  } catch (e) {
    return null;
  }
});
