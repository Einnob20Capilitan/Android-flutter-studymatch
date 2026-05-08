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
  static const int _totalOnboardingSteps = 5;
  int get totalOnboardingSteps => _totalOnboardingSteps;

  List<RealUser>   _matchUsers   = []; // deck — users not yet seen
  List<RealUser>   _matchedUsers = []; // users I liked (from DB)
  List<String>     _passedIds    = []; // users I passed (local only)
  List<DBResource> _dbResources  = [];
  bool _loadingUsers     = false;
  bool _loadingResources = false;
  final List<Conversation> _conversations = [];

  UserModel?       get currentUser      => _currentUser;
  bool             get isLoggedIn       => _currentUser != null;
  int              get onboardingStep   => _onboardingStep;
  List<RealUser>   get matchUsers       => List.unmodifiable(_matchUsers);
  List<RealUser>   get matchedUsers     => List.unmodifiable(_matchedUsers);
  List<DBResource> get dbResources      => List.unmodifiable(_dbResources);
  bool             get loadingUsers     => _loadingUsers;
  bool             get loadingResources => _loadingResources;
  List<Conversation> get conversations  => List.unmodifiable(_conversations);

  int get unreadMessageCount =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  AuthState get authState {
    if (_currentUser == null) return AuthState.unauthenticated;
    if (!_currentUser!.onboardingComplete) return AuthState.onboarding;
    return AuthState.authenticated;
  }

  AppState() { _loadSession(); }

  // ── Session ───────────────────────────────────────────────────────────────
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sm_session');
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(decoded);
          notifyListeners();
          if (_currentUser!.onboardingComplete) {
            await _loadPassedIds();
            await _loadMatchedUsersFromDb();
            await loadMatchUsers();
            await loadResources();
          }
        }
      }
    } catch (e) {
      await _clearSession();
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

  // ── Load matches from DB ──────────────────────────────────────────────────
  Future<void> _loadMatchedUsersFromDb() async {
    if (_currentUser == null) return;
    try {
      _matchedUsers = await ApiService.getMatches(_currentUser!.id);
      notifyListeners();
    } catch (_) {
      _matchedUsers = [];
    }
  }

  // ── Passed IDs (local only — just to prevent showing again this session) ──
  Future<void> _loadPassedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sm_passed_${_currentUser?.id}');
    if (raw != null) {
      _passedIds = List<String>.from(jsonDecode(raw) as List);
    }
  }

  Future<void> _savePassedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sm_passed_${_currentUser?.id}', jsonEncode(_passedIds));
  }

  // ── Load match deck ───────────────────────────────────────────────────────
  Future<void> loadMatchUsers({String? subject, String? search}) async {
    _loadingUsers = true;
    notifyListeners();
    try {
      final all = await ApiService.getUsers(
        subject:      subject,
        search:       search,
        excludeId:    _currentUser?.id,
        myRole:       _currentUser?.role,
        myStrengths:  _currentUser?.strengths,
        myWeaknesses: _currentUser?.weaknesses,
      );
      // Filter out already matched (from DB) and passed (local)
      final excludeIds = {
        ..._matchedUsers.map((u) => u.id),
        ..._passedIds,
      };
      _matchUsers = all.where((u) => !excludeIds.contains(u.id)).toList();
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
      _dbResources = await ApiService.getResources(subject: subject, search: search);
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
    required String authorName,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final result = await ApiService.uploadResource(
      uploaderId:  _currentUser!.id,
      title:       title,
      subject:     subject,
      description: description,
      authorName:  authorName,
      fileBytes:   fileBytes,
      fileName:    fileName,
    );
    if (result['success'] == true) await loadResources();
    return result;
  }

  // ── Rate user ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> rateUser({
    required String ratedId, required int score,
  }) async {
    try {
      final result = await ApiService.rateUser(
          raterId: _currentUser!.id, ratedId: ratedId, score: score);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        _updateRatingInList(_matchUsers, ratedId, data);
        _updateRatingInList(_matchedUsers, ratedId, data);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  void _updateRatingInList(List<RealUser> list, String id, Map<String, dynamic>? data) {
    final idx = list.indexWhere((u) => u.id == id);
    if (idx != -1 && data != null) {
      final u = list[idx];
      list[idx] = RealUser(
        id: u.id, fullName: u.fullName, email: u.email,
        school: u.school, department: u.department,
        profilePhotoUrl: u.profilePhotoUrl, bio: u.bio,
        subjects: u.subjects, learningStyles: u.learningStyles,
        studyStyles: u.studyStyles, strengths: u.strengths,
        weaknesses: u.weaknesses,
        rating: (data['newRating'] as num?)?.toDouble() ?? u.rating,
        ratingCount: (data['ratingCount'] as int?) ?? u.ratingCount,
        compatibilityScore: u.compatibilityScore,
      );
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<String?> signUp({
    required String name, required String email, required String password,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final result = await ApiService.register(
          id: id, name: name, email: email, password: password);
      if (result['success'] == true) return null;
      return result['message'] as String? ?? 'Registration failed';
    } catch (e) { return 'Network error: $e'; }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────
  Future<String?> signIn({
    required String email, required String password,
  }) async {
    try {
      final result = await ApiService.login(email: email, password: password);
      if (result['success'] == true) {
        final rawData = result['data'];
        if (rawData == null || rawData is! Map<String, dynamic>)
          return 'Login failed: unexpected server response';
        final user = UserModel.fromJson(rawData);
        _currentUser = user;
        _onboardingStep = 0;
        await _saveSession(user);
        if (user.onboardingComplete) {
          await _loadPassedIds();
          await _loadMatchedUsersFromDb();
          await loadMatchUsers();
          await loadResources();
        }
        notifyListeners();
        return null;
      }
      return result['message'] as String? ?? 'Login failed';
    } catch (e) { return 'Network error: $e'; }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try { return await ApiService.forgotPassword(email); }
    catch (e) { return {'success': false, 'message': 'Network error: $e'}; }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _currentUser  = null;
    _onboardingStep = 0;
    _matchUsers   = [];
    _matchedUsers = [];
    _passedIds    = [];
    _dbResources  = [];
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
    if (_onboardingStep > 0) { _onboardingStep--; notifyListeners(); }
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
      id: _currentUser!.id, fullName: _currentUser!.fullName,
      email: _currentUser!.email, profilePhotoUrl: _currentUser!.profilePhotoUrl,
      school: _currentUser!.school, department: _currentUser!.department,
      topic: _currentUser!.topic, yearLevel: _currentUser!.yearLevel,
      dateOfBirth: _currentUser!.dateOfBirth, gender: _currentUser!.gender,
      bio: _currentUser!.bio, role: _currentUser!.role,
      subjects: _currentUser!.subjects, learningStyles: _currentUser!.learningStyles,
      studyStyles: _currentUser!.studyStyles, availability: _currentUser!.availability,
      strengths: _currentUser!.strengths, weaknesses: _currentUser!.weaknesses,
      onboardingComplete: true,
    );
    await ApiService.updateUser(updated);
    _currentUser = updated;
    await _saveSession(updated);
    await _loadMatchedUsersFromDb();
    await loadMatchUsers();
    await loadResources();
    notifyListeners();
  }

  // ── Save profile ──────────────────────────────────────────────────────────
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
      return result['message'] as String? ?? 'Update failed';
    } catch (e) { return 'Network error: $e'; }
  }

  // ── Match actions ─────────────────────────────────────────────────────────

  /// Like → save to DB matches table, remove from deck
  Future<void> likeUser(String userId) async {
    final idx = _matchUsers.indexWhere((u) => u.id == userId);
    if (idx == -1) return;

    final liked = _matchUsers[idx];
    _matchUsers.removeAt(idx);

    // Save to DB
    if (_currentUser != null) {
      try {
        await ApiService.saveMatch(
          userId: _currentUser!.id,
          matchedId: userId,
        );
        // Add to local matched list if not already there
        if (!_matchedUsers.any((u) => u.id == userId)) {
          _matchedUsers.insert(0, liked);
        }
      } catch (_) {
        // Even if API fails, keep local state
        if (!_matchedUsers.any((u) => u.id == userId)) {
          _matchedUsers.insert(0, liked);
        }
      }
    }
    notifyListeners();
  }

  /// Pass → add to passed list (local), never show again this session
  void passUser(String userId) {
    _matchUsers.removeWhere((u) => u.id == userId);
    if (!_passedIds.contains(userId)) {
      _passedIds.add(userId);
      _savePassedIds();
    }
    notifyListeners();
  }

  /// Remove a match (unmatch)
  Future<void> unmatchUser(String userId) async {
    _matchedUsers.removeWhere((u) => u.id == userId);
    if (_currentUser != null) {
      try {
        await ApiService.removeMatch(
          userId: _currentUser!.id,
          matchedId: userId,
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  // ── Unread count ──────────────────────────────────────────────────────────
  Future<int> fetchUnreadCount() async {
    if (_currentUser == null) return 0;
    try { return await MessageService.getUnreadCount(userId: _currentUser!.id); }
    catch (_) { return 0; }
  }
}