import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const _base    = 'http://localhost/StudyMatch/studymatch-api';
  static const _apiKey  = 'studymatch_api_key_2026';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String id,
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api.php?action=register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'fullName': name,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api.php?action=login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$_base/api.php?action=forgot_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String name,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api.php?action=send_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'name': name}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api.php?action=verify_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateUser(UserModel user) async {
    final res = await http.post(
      Uri.parse('$_base/api.php?action=update_profile&api_key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Users / Matching ──────────────────────────────────────────────────────
  static Future<List<RealUser>> getUsers({
    String? subject,
    String? search,
    String? excludeId,
    List<String>? myStrengths,
    List<String>? myWeaknesses,
  }) async {
    final params = <String, String>{
      'action':  'get_users',
      'api_key': _apiKey,
    };
    if (subject != null && subject.isNotEmpty) params['subject']      = subject;
    if (search  != null && search.isNotEmpty)  params['search']       = search;
    if (excludeId != null)                     params['exclude_id']   = excludeId;
    if (myStrengths  != null && myStrengths.isNotEmpty)
      params['my_strengths']  = jsonEncode(myStrengths);
    if (myWeaknesses != null && myWeaknesses.isNotEmpty)
      params['my_weaknesses'] = jsonEncode(myWeaknesses);

    try {
      final uri = Uri.parse('$_base/api.php').replace(queryParameters: params);
      final res  = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((u) => RealUser.fromJson(u as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> rateUser({
    required String raterId,
    required String ratedId,
    required int score,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api.php?action=rate_user&api_key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rater_id': raterId,
        'rated_id': ratedId,
        'score':    score,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Resources ─────────────────────────────────────────────────────────────
  static Future<List<DBResource>> getResources({
    String? subject,
    String? search,
  }) async {
    final params = <String, String>{
      'action':  'get_resources',
      'api_key': _apiKey,
    };
    if (subject != null && subject != 'All') params['subject'] = subject;
    if (search  != null && search.isNotEmpty) params['search']  = search;

    try {
      final uri  = Uri.parse('$_base/api.php').replace(queryParameters: params);
      final res  = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((r) => DBResource.fromJson(r as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> uploadResource({
    required String uploaderId,
    required String title,
    required String subject,
    required String description,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final uri     = Uri.parse('$_base/api.php?action=upload_resource&api_key=$_apiKey');
    final request = http.MultipartRequest('POST', uri);
    request.fields['uploader_id'] = uploaderId;
    request.fields['title']       = title;
    request.fields['subject']     = subject;
    request.fields['description'] = description;
    request.files.add(http.MultipartFile.fromBytes(
        'file', fileBytes, filename: fileName));
    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}