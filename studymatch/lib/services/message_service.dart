import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageService {
  static const _base   = 'http://localhost/StudyMatch/studymatch-api/messages.php';
  static const _apiKey = 'studymatch_api_key_2026';

  // ── Send message ────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base?action=send&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id':   senderId,
          'receiver_id': receiverId,
          'content':     content,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Get messages between two users ──────────────────────────
  static Future<List<Map<String, dynamic>>> getMessages({
    required String userId,
    required String otherId,
    int limit  = 100,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'action':   'get_messages',
        'api_key':  _apiKey,
        'user_id':  userId,
        'other_id': otherId,
        'limit':    limit.toString(),
        'offset':   offset.toString(),
      });
      final res  = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data'] as List);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Get inbox ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getInbox({
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'action':  'get_inbox',
        'api_key': _apiKey,
        'user_id': userId,
      });
      final res  = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data'] as List);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Get unread count ────────────────────────────────────────
  static Future<int> getUnreadCount({required String userId}) async {
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'action':  'get_unread',
        'api_key': _apiKey,
        'user_id': userId,
      });
      final res  = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return (data['data']['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ── Mark read ───────────────────────────────────────────────
  static Future<void> markRead({
    required String userId,
    required String otherId,
  }) async {
    try {
      await http.post(
        Uri.parse('$_base?action=mark_read&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':  userId,
          'other_id': otherId,
        }),
      );
    } catch (_) {}
  }
}