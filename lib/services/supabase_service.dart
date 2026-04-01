import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/habit.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  static User? get currentUser => _client.auth.currentUser;
  static String? get currentUserId => _client.auth.currentUser?.id;
  static String? get currentUserEmail => _client.auth.currentUser?.email;
  static String? get currentUserName =>
      _client.auth.currentUser?.userMetadata?['full_name'] as String?;
  static String? get currentUserAvatarUrl =>
      _client.auth.currentUser?.userMetadata?['avatar_url'] as String?;


  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  static Future<AuthResponse> signInWithGoogle() async {
    try {
      // IMPORTANT: This MUST start with 559273478063 to match your google-services.json
      const webClientId = '559273478063-YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com';
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled by user');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('No ID token received. Ensure the Web Client ID is correct.');
      }

      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      print('Google Sign-In Error details: $e');
      rethrow;
    }
  }


  // ─── AVATAR ───────────────────────────────────────────────────────────────
  static Future<String> uploadAvatar(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    final ext = imageFile.path.split('.').last.toLowerCase();
    final filePath = 'avatars/$userId.$ext';
    await _client.storage.from('avatars').upload(
      filePath,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );
    final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);
    final url = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    await _client.auth.updateUser(UserAttributes(
      data: {'avatar_url': url},
    ));
    return url;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> updateUserName(String name) async {
    await _client.auth.updateUser(UserAttributes(
      data: {'full_name': name},
    ));
  }

  // ─── HABITS ───────────────────────────────────────────────────────────────

  static Future<List<Habit>> fetchHabits() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => Habit.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<Habit> createHabit(Habit habit) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final data = {
      'user_id': userId,
      'name': habit.name,
      'description': habit.description,
      'color': habit.color,
      'icon': habit.icon,
      'history': habit.completionHistory,
    };

    final response =
    await _client.from('habits').insert(data).select().single();

    return Habit.fromJson(response as Map<String, dynamic>);
  }

  static Future<void> updateHabit(Habit habit) async {
    await _client.from('habits').update({
      'name': habit.name,
      'description': habit.description,
      'color': habit.color,
      'icon': habit.icon,
      'history': habit.completionHistory,
    }).eq('id', habit.id);
  }

  static Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
  }

  static Future<void> toggleHabitCompletion(Habit habit) async {
    await _client.from('habits').update({
      'history': habit.completionHistory,
    }).eq('id', habit.id);
  }
}
