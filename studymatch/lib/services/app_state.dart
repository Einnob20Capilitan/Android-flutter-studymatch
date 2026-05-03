import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/models.dart';
import 'api_service.dart';
import 'message_service.dart'; 

enum AuthState { unauthenticated, onboarding, authenticated }

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  int _onboardingStep = 0;
  static const int _totalOnboardingSteps = 4;
  int get totalOnboardingSteps => _totalOnboardingSteps;

  List<RealUser> _matchUsers = [];
  List<DBResource> _dbResources = [];
  bool _loadingUsers = false;
  bool _loadingResources = false;
  final List<Conversation> _conversations = [];

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  int get onboardingStep => _onboardingStep;
  List<RealUser> get matchUsers => List.unmodifiable(_matchUsers);
  List<DBResource> get dbResources => List.unmodifiable(_dbResources);
  bool get loadingUsers => _loadingUsers;
  bool get loadingResources => _loadingResources;
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  int get unreadMessageCount =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  AuthState get authState {
    if (_currentUser == null) return AuthState.unauthenticated;
    if (!_currentUser!.onboardingComplete) return AuthState.onboarding;
    return AuthState.authenticated;
  }

  AppState() {
    _loadSession();
  }

  // ── Session ───────────────────────────────────────────────────────────────
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sm_session');
    if (raw != null) {
      _currentUser = UserModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
      if (_currentUser!.onboardingComplete) {
        await loadMatchUsers();
        await loadResources();
      }
    }
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sm_session', jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sm_session');
  }

  // ── Load users ────────────────────────────────────────────────────────────
  Future<void> loadMatchUsers({String? subject, String? search}) async {
    _loadingUsers = true;
    notifyListeners();
    try {
      _matchUsers = await ApiService.getUsers(
        subject: subject,
        search: search,
        excludeId: _currentUser?.id,
        myStrengths: _currentUser?.strengths,
        myWeaknesses: _currentUser?.weaknesses,
      );
    } catch (_) {
      _matchUsers = [];
    }
    _loadingUsers = false;
    notifyListeners();
  }

  // ── Load resources ────────────────────────────────────────────────────────
  Future<void> loadResources({String? subject, String? search}) async {
    _loadingResources = true;
    notifyListeners();
    try {
      _dbResources = await ApiService.getResources(
          subject: subject, search: search);
    } catch (_) {
      _dbResources = [];
    }
    _loadingResources = false;
    notifyListeners();
  }
  

  // ── Upload resource ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadResource({
    required String title,
    required String subject,
    required String description,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final result = await ApiService.uploadResource(
      uploaderId: _currentUser!.id,
      title: title,
      subject: subject,
      description: description,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    if (result['success'] == true) await loadResources();
    return result;
  }

  // ── Rate user ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> rateUser({
    required String ratedId,
    required int score,
  }) async {
    try {
      final result = await ApiService.rateUser(
          raterId: _currentUser!.id, ratedId: ratedId, score: score);
      if (result['success'] == true) {
        final idx = _matchUsers.indexWhere((u) => u.id == ratedId);
        if (idx != -1) {
          final u = _matchUsers[idx];
          _matchUsers[idx] = RealUser(
            id: u.id,
            fullName: u.fullName,
            email: u.email,
            school: u.school,
            department: u.department,
            profilePhotoUrl: u.profilePhotoUrl,
            bio: u.bio,
            subjects: u.subjects,
            learningStyles: u.learningStyles,
            studyStyles: u.studyStyles,
            strengths: u.strengths,
            weaknesses: u.weaknesses,
            rating: (result['newRating'] as num).toDouble(),
            ratingCount: result['ratingCount'] as int,
            compatibilityScore: u.compatibilityScore,
          );
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final result = await ApiService.register(
          id: id, name: name, email: email, password: password);
      if (result['success'] == true) return null;
      return result['message'] as String?;
    } catch (e) {
      return 'Network error: $e';
    }
  }

  

  // ── Sign In ───────────────────────────────────────────────────────────────
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result =
          await ApiService.login(email: email, password: password);
      if (result['success'] == true) {
        final user = UserModel.fromJson(
            result['user'] as Map<String, dynamic>);
        _currentUser = user;
        _onboardingStep = 0;
        await _saveSession(user);
        if (user.onboardingComplete) {
          await loadMatchUsers();
          await loadResources();
        }
        notifyListeners();
        return null;
      }
      return result['message'] as String?;
    } catch (e) {
      return 'Network error: $e';
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      return await ApiService.forgotPassword(email);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _currentUser = null;
    _onboardingStep = 0;
    _matchUsers = [];
    _dbResources = [];
    _conversations.clear();
    await _clearSession();
    notifyListeners();
  }

  // ── Onboarding ────────────────────────────────────────────────────────────
  void nextOnboardingStep() {
    if (_onboardingStep < _totalOnboardingSteps - 1) {
      _onboardingStep++;
      notifyListeners();
    }
  }

  void previousOnboardingStep() {
    if (_onboardingStep > 0) {
      _onboardingStep--;
      notifyListeners();
    }
  }

  void updateUserProfile(Map<String, dynamic> fields) {
    if (_currentUser == null) return;
    final json = _currentUser!.toJson()..addAll(fields);
    _currentUser = UserModel.fromJson(json);
    notifyListeners();
  }
 
  Future<void> completeOnboarding() async {
    if (_currentUser == null) return;
    final updated = UserModel(
      id: _currentUser!.id,
      fullName: _currentUser!.fullName,
      email: _currentUser!.email,
      profilePhotoUrl: _currentUser!.profilePhotoUrl,
      school: _currentUser!.school,
      department: _currentUser!.department,
      topic: _currentUser!.topic,
      yearLevel: _currentUser!.yearLevel,
      dateOfBirth: _currentUser!.dateOfBirth,
      gender: _currentUser!.gender,
      bio: _currentUser!.bio,
      subjects: _currentUser!.subjects,
      learningStyles: _currentUser!.learningStyles,
      studyStyles: _currentUser!.studyStyles,
      availability: _currentUser!.availability,
      strengths: _currentUser!.strengths,
      weaknesses: _currentUser!.weaknesses,
      onboardingComplete: true,
    );
    await ApiService.updateUser(updated);
    _currentUser = updated;
    await _saveSession(updated);
    await loadMatchUsers();
    await loadResources();
    notifyListeners();
  }

  // ── Save profile (edit profile screen) ───────────────────────────────────
  Future<String?> saveProfile(Map<String, dynamic> fields) async {
    if (_currentUser == null) return 'Not logged in';
    try {
      final json = _currentUser!.toJson()..addAll(fields);
      final updated = UserModel.fromJson(json);
      final result = await ApiService.updateUser(updated);
      if (result['success'] == true) {
        _currentUser = updated;
        await _saveSession(updated);
        notifyListeners();
        return null;
      }
      return result['message'] as String?;
    } catch (e) {
      return 'Network error: $e';
    }
  }

  // ── Match actions ─────────────────────────────────────────────────────────
  void likeUser(String userId) {
    _matchUsers.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  void passUser(String userId) {
    _matchUsers.removeWhere((u) => u.id == userId);
    notifyListeners();
  }
  // Add this method to AppState
Future<int> fetchUnreadCount() async {
  if (_currentUser == null) return 0;
  try {
    return await MessageService.getUnreadCount(userId: _currentUser!.id);
  } catch (_) { return 0; }
}

}