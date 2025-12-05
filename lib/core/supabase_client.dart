import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientConfig {
  static const String url = 'https://mwldonzgeruhrsfirfop.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im13bGRvbnpnZXJ1aHJzZmlyZm9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MTYwMzAsImV4cCI6MjA3ODQ5MjAzMH0.ZefZzLerTtke3rj3lD1DItLVbcBkUMBZ65p98Hk2H6w';

  static final SupabaseClient instance = Supabase.instance.client;
}
