import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'farmer',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  // Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      return response;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (!isLoggedIn) throw Exception('User not logged in');

    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUser!.id);
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
