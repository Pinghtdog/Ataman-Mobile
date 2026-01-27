import 'dart:io';
import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../injector.dart';
import 'notification_service.dart';

class ServiceInitializer {
  static Future<bool> initialize() async {
    try {
      await dotenv.load(fileName: ".env");

      // Initialize Hive for Offline Sync
      await Hive.initFlutter();
      await Hive.openBox('facilities_cache');
      await Hive.openBox('user_settings');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception("Missing Supabase credentials in .env file");
      }

      if (kDebugMode) {
        HttpOverrides.global = _DevHttpOverrides();
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      if (geminiApiKey != null) {
        // Removed modelName as it's not supported in Gemini.init for this package version
        Gemini.init(apiKey: geminiApiKey);
      }

      await Firebase.initializeApp();
      await NotificationService.initialize();
      
      await initInjector();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      return true;
    } catch (e) {
      debugPrint("INITIALIZATION ERROR: $e");
      return false;
    }
  }
}

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
