import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://olmgugcquqbolxyfowdy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sbWd1Z2NxdXFib2x4eWZvd2R5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzMzg1ODgsImV4cCI6MjA2OTkxNDU4OH0.DoJZWQbonZA-xBREIGKFxYgoCGpIU7qbtZqly8_XBeE';

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    // Listen to auth state changes to persist token
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _persistToken();
      }
    });
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final res = await client.auth.signInWithPassword(email: email, password: password);
    await _persistToken();
    return res;
  }

  Future<bool> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'pranthora://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
        scopes: 'openid email profile',
      );
      // Wait a bit for the in-app browser to process and close
      await Future.delayed(const Duration(milliseconds: 500));
      // Token will be persisted when auth state changes via listener
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> _persistToken() async {
    final session = client.auth.currentSession;
    if (session != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', session.accessToken);
    }
  }

  Future<bool> hasValidSession() async {
    final session = client.auth.currentSession;
    if (session != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }
}
