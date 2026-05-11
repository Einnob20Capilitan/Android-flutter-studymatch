import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_state.dart';
import '../../services/message_service.dart';
import '../../models/models.dart';
import 'user_profile_screen.dart';

// ── Messages Screen ───────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _inbox     = [];
  bool   _loadingInbox = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadInbox();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _loadInbox());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInbox() async {
    final me = context.read<AppState>().currentUser;
    if (me == null) return;
    try {
      final data = await MessageService.getInbox(userId: me.id);
      if (mounted) setState(() { _inbox = data; _loadingInbox = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingInbox = false);
    }
  }

  void _openChat(RealUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(participant: user)),
    ).then((_) => _loadInbox());
  }

  void _viewProfile(RealUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final me      = state.currentUser;
    final matched = state.matchedUsers;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Messages',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          fontFamily: 'Poppins')),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppTheme.textSecondary),
                    tooltip: 'New Message',
                    onPressed: () => _showNewMessageSheet(context, state),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: const TextStyle(
                      color: AppTheme.textMuted, fontFamily: 'Poppins'),
                  prefixIcon: const Icon(Icons.search,
                      color: AppTheme.textMuted, size: 20),
                  filled: true,
                  fillColor: AppTheme.inputBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Matched users row
            if (matched.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Matches',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            fontFamily: 'Poppins')),
                    Text('${matched.length} matched',
                        style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontFamily: 'Poppins')),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: matched.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) {
                    final user = matched[i];
                    return GestureDetector(
                      onTap: () => _openChat(user),
                      onLongPress: () => _viewProfile(user),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [AppTheme.primary, AppTheme.accent]),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.success, width: 2),
                                ),
                                child: Center(
                                  child: Text(user.initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          fontFamily: 'Poppins')),
                                ),
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  width: 16, height: 16,
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.bgDark, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 56,
                            child: Text(
                              user.fullName.split(' ').first,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Messages',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Poppins')),
              ),
              const SizedBox(height: 8),
            ],

            // Inbox
            Expanded(child: _buildInbox(state, me?.id ?? '')),
          ],
        ),
      ),
    );
  }

  Widget _buildInbox(AppState state, String myId) {
    if (_loadingInbox) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final matchedIds    = state.matchedUsers.map((u) => u.id).toSet();
    final filteredInbox = _inbox
        .where((c) => matchedIds.contains(c['participantId'] as String?))
        .toList();

    if (filteredInbox.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline,
                color: AppTheme.textMuted, size: 56),
            const SizedBox(height: 20),
            const Text('No messages yet',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            const Text('Match with someone to start chatting!',
                style: TextStyle(
                    color: AppTheme.textMuted, fontFamily: 'Poppins')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInbox,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredInbox.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppTheme.divider, height: 1),
        itemBuilder: (ctx, i) {
          final c        = filteredInbox[i];
          final isUnread = (c['unreadCount'] as int? ?? 0) > 0;
          final isMe     = c['lastMessageSenderId'] == myId;
          final lastMsg  = c['lastMessage']     as String? ?? '';
          final lastType = c['lastMessageType'] as String? ?? 'text';
          final time     = c['lastMessageTime'] as String? ?? '';

          // Build a readable preview for file messages
          final preview = _buildInboxPreview(isMe, lastMsg, lastType);

          final participant = _buildRealUser(c);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: GestureDetector(
              onTap: () => _viewProfile(participant),
              child: UserAvatar(realUser: participant, radius: 26),
            ),
            title: Text(participant.fullName,
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight:
                        isUnread ? FontWeight.bold : FontWeight.w500,
                    fontFamily: 'Poppins',
                    fontSize: 15)),
            subtitle: Row(
              children: [
                if (lastType == 'image')
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.image_outlined,
                        size: 13, color: AppTheme.textMuted),
                  )
                else if (lastType == 'file')
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.attach_file,
                        size: 13, color: AppTheme.textMuted),
                  ),
                Expanded(
                  child: Text(preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isUnread
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 13)),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatTime(time),
                    style: TextStyle(
                        color: isUnread
                            ? AppTheme.primaryLight
                            : AppTheme.textMuted,
                        fontSize: 11,
                        fontFamily: 'Poppins')),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${c['unreadCount']}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => ChatScreen(participant: participant)),
            ).then((_) => _loadInbox()),
          );
        },
      ),
    );
  }

  String _buildInboxPreview(bool isMe, String lastMsg, String lastType) {
    final prefix = isMe ? 'You: ' : '';
    switch (lastType) {
      case 'image': return '${prefix}📷 Image';
      case 'file':  return '${prefix}📎 File';
      default:      return '$prefix$lastMsg';
    }
  }

  RealUser _buildRealUser(Map<String, dynamic> c) => RealUser(
    id:         c['participantId']    as String,
    fullName:   c['participantName']  as String,
    email:      c['participantEmail'] as String? ?? '',
    role:       c['participantRole']  as String? ?? 'student',
    department: c['participantDept']   as String?,
    school:     c['participantSchool'] as String?,
    bio:        c['participantBio']    as String?,
    rating: (c['participantRating'] as num?)?.toDouble() ?? 0,
    ratingCount: c['participantRatingCount'] as int? ?? 0,
    subjects: List<String>.from((c['participantSubjects']       as List?) ?? []),
    strengths: List<String>.from((c['participantStrengths']     as List?) ?? []),
    weaknesses: List<String>.from((c['participantWeaknesses']   as List?) ?? []),
    learningStyles: List<String>.from((c['participantLearningStyles'] as List?) ?? []),
    studyStyles: List<String>.from((c['participantStudyStyles'] as List?) ?? []),
  );

  void _showNewMessageSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('New Message',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Poppins')),
            ),
            const Divider(color: AppTheme.divider, height: 1),
            if (state.matchedUsers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Your Matches',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5)),
                ),
              ),
              ...state.matchedUsers.map((user) => ListTile(
                    leading: UserAvatar(realUser: user, radius: 22),
                    title: Text(user.fullName,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins')),
                    subtitle: Text(
                      user.isTutor ? '🏫 Tutor' : '🎓 Student',
                      style: TextStyle(
                          color: user.isTutor
                              ? AppTheme.success
                              : const Color(0xFF3B82F6),
                          fontFamily: 'Poppins',
                          fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openChat(user);
                    },
                  )),
            ] else
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No matches yet. Swipe right to match!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontFamily: 'Poppins')),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt   = DateTime.parse(isoTime);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60)  return 'now';
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m';
      if (diff.inHours   < 24)  return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) { return ''; }
  }
}

// ── Chat Screen ───────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final RealUser participant;
  const ChatScreen({super.key, required this.participant});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool   _loading      = true;
  bool   _sending      = false;
  bool   _pausePolling = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  String get _myId =>
      context.read<AppState>().currentUser?.id ?? '';

  Future<void> _loadMessages({bool silent = false}) async {
    if (_pausePolling) return;
    if (!silent) setState(() => _loading = true);
    try {
      final msgs = await MessageService.getMessages(
          userId: _myId, otherId: widget.participant.id);
      if (mounted && !_pausePolling) {
        final wasAtBottom = _scrollCtrl.hasClients &&
            _scrollCtrl.position.pixels >=
                _scrollCtrl.position.maxScrollExtent - 100;
        setState(() { _messages = msgs; _loading = false; });
        if (wasAtBottom || !silent) _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  // ── Send text ─────────────────────────────────────────────────────────────
  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _sending) return;
    _msgCtrl.clear();
    _pausePolling = true;
    setState(() => _sending = true);

    final tempId  = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id':          tempId,
      'senderId':    _myId,
      'receiverId':  widget.participant.id,
      'content':     txt,
      'messageType': 'text',
      'fileUrl':     null,
      'fileName':    null,
      'fileSize':    null,
      'isRead':      false,
      'createdAt':   DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      final result = await MessageService.sendMessage(
          senderId: _myId, receiverId: widget.participant.id, content: txt);
      if (result['success'] == true) {
        final msgs = await MessageService.getMessages(
            userId: _myId, otherId: widget.participant.id);
        _pausePolling = false;
        if (mounted) {
          setState(() { _messages = msgs; _sending = false; });
          _scrollToBottom();
        }
      } else {
        _pausePolling = false;
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m['id'] == tempId);
            _sending = false;
          });
        }
      }
    } catch (_) {
      _pausePolling = false;
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
          _sending = false;
        });
      }
    }
  }

  // ── Show attachment picker ────────────────────────────────────────────────
  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            // Camera
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.primaryLight),
              ),
              title: const Text('Take Photo',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontFamily: 'Poppins')),
              subtitle: const Text('Open camera',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontFamily: 'Poppins',
                      fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendImage(ImageSource.camera);
              },
            ),
            // Gallery
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.accent),
              ),
              title: const Text('Photo Library',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontFamily: 'Poppins')),
              subtitle: const Text('Choose from gallery',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontFamily: 'Poppins',
                      fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendImage(ImageSource.gallery);
              },
            ),
            // File
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.attach_file_rounded,
                    color: AppTheme.success),
              ),
              title: const Text('Document / File',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontFamily: 'Poppins')),
              subtitle: const Text('PDF, Word, Excel and more',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontFamily: 'Poppins',
                      fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendFile();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Pick image and upload ─────────────────────────────────────────────────
  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: source, imageQuality: 80);
      if (img == null) return;

      final bytes    = await img.readAsBytes();
      final fileName = img.name;
      final ext      = fileName.split('.').last.toLowerCase();
      final mime     = ext == 'png' ? 'image/png' : 'image/jpeg';

      await _uploadAndInsert(
          fileBytes: bytes, fileName: fileName, mimeType: mime);
    } catch (e) {
      _showError('Could not pick image: $e');
    }
  }

  // ── Pick file and upload ──────────────────────────────────────────────────
  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Could not read file');
        return;
      }

      final bytes    = file.bytes!;
      final fileName = file.name;
      // Guess MIME from extension; server will verify with mime_content_type()
      final mime     = _mimeFromFileName(fileName);

      await _uploadAndInsert(
          fileBytes: bytes, fileName: fileName, mimeType: mime);
    } catch (e) {
      _showError('Could not pick file: $e');
    }
  }

  String _mimeFromFileName(String name) {
    final ext = name.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif',  'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'zip': 'application/zip',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  // ── Core: upload file and inject optimistic bubble ────────────────────────
  Future<void> _uploadAndInsert({
    required Uint8List fileBytes,
    required String    fileName,
    required String    mimeType,
  }) async {
    final isImage = mimeType.startsWith('image/');

    _pausePolling = true;
    setState(() => _sending = true);

    // Optimistic bubble
    final tempId  = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id':          tempId,
      'senderId':    _myId,
      'receiverId':  widget.participant.id,
      'content':     isImage ? '📷 Image' : '📎 $fileName',
      'messageType': isImage ? 'image' : 'file',
      'fileUrl':     null,             // no URL yet — shows a progress indicator
      'fileName':    fileName,
      'fileSize':    fileBytes.length,
      'isRead':      false,
      'createdAt':   DateTime.now().toIso8601String(),
      '_uploading':  true,             // custom flag for UI
    };
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      final result = await MessageService.sendFile(
        senderId:   _myId,
        receiverId: widget.participant.id,
        fileBytes:  fileBytes,
        fileName:   fileName,
        mimeType:   mimeType,
      );

      if (result['success'] == true) {
        // Reload real messages from server
        final msgs = await MessageService.getMessages(
            userId: _myId, otherId: widget.participant.id);
        _pausePolling = false;
        if (mounted) {
          setState(() { _messages = msgs; _sending = false; });
          _scrollToBottom();
        }
      } else {
        _pausePolling = false;
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m['id'] == tempId);
            _sending = false;
          });
          _showError(result['message'] as String? ?? 'Upload failed');
        }
      }
    } catch (e) {
      _pausePolling = false;
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
          _sending = false;
        });
        _showError('Upload error: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UserProfileScreen(user: widget.participant)),
          ),
          child: Row(
            children: [
              UserAvatar(realUser: widget.participant, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.participant.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text(
                      widget.participant.isTutor ? '🏫 Tutor' : '🎓 Student',
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.participant.isTutor
                              ? AppTheme.success
                              : const Color(0xFF3B82F6),
                          fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: widget.participant)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: AppTheme.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.accent]),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(widget.participant.initials,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(widget.participant.fullName,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'Poppins')),
                            const SizedBox(height: 8),
                            const Text('Say hello! 👋',
                                style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontFamily: 'Poppins')),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg  = _messages[i];
                          final isMe = msg['senderId'] == _myId;
                          return _Bubble(msg: msg, isMe: isMe);
                        },
                      ),
          ),

          // ── Input bar ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: const BoxDecoration(
                color: AppTheme.bgCard,
                border: Border(top: BorderSide(color: AppTheme.divider))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                GestureDetector(
                  onTap: _sending ? null : _showAttachmentSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40, height: 40,
                    margin: const EdgeInsets.only(right: 8, bottom: 2),
                    decoration: BoxDecoration(
                      color: _sending
                          ? AppTheme.divider
                          : AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: _sending
                          ? AppTheme.textMuted
                          : AppTheme.primaryLight,
                      size: 22,
                    ),
                  ),
                ),

                // Text input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.divider)),
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                          fontSize: 14),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                            color: AppTheme.textMuted,
                            fontFamily: 'Poppins'),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),

                // Send button
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent]),
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final msgType   = msg['messageType'] as String? ?? 'text';
    final fileUrl   = msg['fileUrl']    as String?;
    final fileName  = msg['fileName']   as String?;
    final fileSize  = msg['fileSize']   as int?;
    final uploading = msg['_uploading'] as bool? ?? false;
    final time      = _fmt(msg['createdAt'] as String? ?? '');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ── Image bubble ──────────────────────────────────────────────
            if (msgType == 'image')
              _ImageBubble(
                  fileUrl: fileUrl, uploading: uploading, isMe: isMe)

            // ── File bubble ───────────────────────────────────────────────
            else if (msgType == 'file')
              _FileBubble(
                  fileUrl: fileUrl,
                  fileName: fileName,
                  fileSize: fileSize,
                  uploading: uploading,
                  isMe: isMe)

            // ── Text bubble ───────────────────────────────────────────────
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent])
                      : null,
                  color: isMe ? null : AppTheme.bgCard,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(16),
                    topRight:    const Radius.circular(16),
                    bottomLeft:  Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppTheme.divider),
                ),
                child: Text(msg['content'] as String? ?? '',
                    style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        height: 1.4)),
              ),

            // ── Timestamp + read tick ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time,
                      style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontFamily: 'Poppins')),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      (msg['isRead'] as bool? ?? false)
                          ? Icons.done_all
                          : Icons.done,
                      size: 12,
                      color: (msg['isRead'] as bool? ?? false)
                          ? AppTheme.primaryLight
                          : AppTheme.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}

// ── Image Bubble ──────────────────────────────────────────────────────────────
class _ImageBubble extends StatelessWidget {
  final String? fileUrl;
  final bool    uploading;
  final bool    isMe;

  const _ImageBubble({
    required this.fileUrl,
    required this.uploading,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: fileUrl != null ? () => _openUrl(fileUrl!) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(16),
          topRight:    const Radius.circular(16),
          bottomLeft:  Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        child: Stack(
          children: [
            // Image or placeholder
            if (fileUrl != null && !uploading)
              Image.network(
                fileUrl!,
                width: 220,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 220, height: 200,
                    color: AppTheme.bgCard,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 220, height: 200,
                  color: AppTheme.bgCard,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            color: AppTheme.textMuted, size: 32),
                        SizedBox(height: 4),
                        Text('Failed to load',
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontFamily: 'Poppins',
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 220, height: 200,
                color: AppTheme.bgCard,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2),
                      SizedBox(height: 10),
                      Text('Uploading...',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontFamily: 'Poppins',
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),

            // Tap-to-expand overlay hint
            if (fileUrl != null && !uploading)
              Positioned(
                bottom: 6, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.open_in_new,
                      color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

// ── File Bubble ───────────────────────────────────────────────────────────────
class _FileBubble extends StatelessWidget {
  final String? fileUrl;
  final String? fileName;
  final int?    fileSize;
  final bool    uploading;
  final bool    isMe;

  const _FileBubble({
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.uploading,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final ext      = (fileName ?? '').split('.').last.toUpperCase();
    final sizeStr  = MessageService.formatFileSize(fileSize);
    final canOpen  = fileUrl != null && !uploading;

    return GestureDetector(
      onTap: canOpen ? () => _openUrl(fileUrl!) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent])
              : null,
          color: isMe ? null : AppTheme.bgCard,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(0.15)
                    : AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: uploading
                  ? const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryLight, strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      _iconForExt(ext),
                      color: isMe ? Colors.white : AppTheme.primaryLight,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            // File info
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? 'File',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isMe ? Colors.white : AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  if (sizeStr.isNotEmpty || uploading) ...[
                    const SizedBox(height: 2),
                    Text(
                      uploading ? 'Uploading…' : sizeStr,
                      style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : AppTheme.textMuted,
                          fontFamily: 'Poppins',
                          fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            // Open arrow
            if (canOpen) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.download_rounded,
                color: isMe
                    ? Colors.white.withOpacity(0.8)
                    : AppTheme.primaryLight,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForExt(String ext) {
    switch (ext) {
      case 'PDF':                          return Icons.picture_as_pdf_outlined;
      case 'DOC': case 'DOCX':            return Icons.description_outlined;
      case 'XLS': case 'XLSX':            return Icons.table_chart_outlined;
      case 'PPT': case 'PPTX':            return Icons.slideshow_outlined;
      case 'TXT':                          return Icons.text_snippet_outlined;
      case 'ZIP': case 'RAR': case '7Z':  return Icons.folder_zip_outlined;
      default:                             return Icons.insert_drive_file_outlined;
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}