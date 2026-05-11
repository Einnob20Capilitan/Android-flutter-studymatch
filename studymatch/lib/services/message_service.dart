import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MessageService {
  static const _base   = 'http://localhost/StudyMatch/studymatch-api/messages.php';
  static const _apiKey = 'studymatch_api_key_2026';

  // ── Send text message ────────────────────────────────────────────────────────
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
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Send file or image message ───────────────────────────────────────────────
  /// [fileBytes]  — raw bytes of the file
  /// [fileName]   — original file name (e.g. "photo.jpg", "notes.pdf")
  /// [mimeType]   — MIME type (e.g. "image/jpeg", "application/pdf")
  static Future<Map<String, dynamic>> sendFile({
    required String    senderId,
    required String    receiverId,
    required Uint8List fileBytes,
    required String    fileName,
    required String    mimeType,
  }) async {
    try {
      final uri = Uri.parse('$_base?action=send_file&api_key=$_apiKey');

      final request = http.MultipartRequest('POST', uri)
        ..fields['sender_id']   = senderId
        ..fields['receiver_id'] = receiverId
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          // http package will send this as Content-Type on the part
        ));

      final streamed = await request.send();
      final body     = await streamed.stream.bytesToString();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  // ── Get messages between two users ───────────────────────────────────────────
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
    } catch (_) {
      return [];
    }
  }

  // ── Get inbox ────────────────────────────────────────────────────────────────
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
    } catch (_) {
      return [];
    }
  }

  // ── Get unread count ─────────────────────────────────────────────────────────
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
    } catch (_) {
      return 0;
    }
  }

  // ── Mark read ────────────────────────────────────────────────────────────────
  static Future<void> markRead({
    required String userId,
    required String otherId,
  }) async {
    try {
      await http.post(
        Uri.parse('$_base?action=mark_read&api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'other_id': otherId}),
      );
    } catch (_) {}
  }

  // ── Helper: human-readable file size ─────────────────────────────────────────
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024)       return '${bytes} B';
    if (bytes < 1048576)    return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // ── Helper: detect if a URL is an image ──────────────────────────────────────
  static bool isImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg')  ||
           lower.endsWith('.jpeg') ||
           lower.endsWith('.png')  ||
           lower.endsWith('.gif')  ||
           lower.endsWith('.webp');
  }
}