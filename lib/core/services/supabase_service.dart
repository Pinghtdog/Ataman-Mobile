import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  Session? get currentSession => client.auth.currentSession;

  String? get userId => client.auth.currentUser?.id;

  /// Generic function to upload a file to a Supabase bucket
  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required dynamic file, // Can be File (dart:io) or bytes
  }) async {
    try {
      await client.storage.from(bucket).upload(path, file);
      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }
}
