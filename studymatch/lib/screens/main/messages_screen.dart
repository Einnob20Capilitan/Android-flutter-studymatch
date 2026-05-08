import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
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

  static const _base = 'http://localhost/StudyMatch/studymatch-api';
  static const _key  = 'studymatch_api_key_2026';

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
    final state = context.watch<AppState>();
    final me    = state.currentUser;
    final matched = state.matchedUsers; // ✅ users I swiped right on

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
                      borderSide:
                          const BorderSide(color: AppTheme.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.divider)),
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

            // ✅ Matched users row (like Tinder)
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
            Expanded(child: _buildInbox(me?.id ?? '')),
          ],
        ),
      ),
    );
  }

  Widget _buildInbox(String myId) {
    if (_loadingInbox) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_inbox.isEmpty) {
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
        itemCount: _inbox.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppTheme.divider, height: 1),
        itemBuilder: (ctx, i) {
          final c       = _inbox[i];
          final isUnread = (c['unreadCount'] as int? ?? 0) > 0;
          final isMe    = c['lastMessageSenderId'] == myId;
          final lastMsg = c['lastMessage']     as String? ?? '';
          final time    = c['lastMessageTime'] as String? ?? '';

          final participant = RealUser(
            id:         c['participantId']   as String,
            fullName:   c['participantName'] as String,
            email:      c['participantEmail'] as String? ?? '',
            department: c['participantDept']   as String?,
            school:     c['participantSchool'] as String?,
            bio:        c['participantBio']    as String?,
            rating: (c['participantRating'] as num?)?.toDouble() ?? 0,
            ratingCount: c['participantRatingCount'] as int? ?? 0,
            subjects: List<String>.from(
                (c['participantSubjects'] as List?) ?? []),
            strengths: List<String>.from(
                (c['participantStrengths'] as List?) ?? []),
            weaknesses: List<String>.from(
                (c['participantWeaknesses'] as List?) ?? []),
            learningStyles: List<String>.from(
                (c['participantLearningStyles'] as List?) ?? []),
            studyStyles: List<String>.from(
                (c['participantStudyStyles'] as List?) ?? []),
          );

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            // ✅ tap avatar → view profile
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
            subtitle: Text(
                isMe ? 'You: $lastMsg' : lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isUnread
                        ? AppTheme.textSecondary
                        : AppTheme.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 13)),
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
                  builder: (_) =>
                      ChatScreen(participant: participant)),
            ).then((_) => _loadInbox()),
          );
        },
      ),
    );
  }

  // ✅ New message sheet — shows matched users first
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
    } catch (_) {
      return '';
    }
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

  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _sending) return;
    _msgCtrl.clear();
    _pausePolling = true;
    setState(() => _sending = true);

    final tempId  = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id':         tempId,
      'senderId':   _myId,
      'receiverId': widget.participant.id,
      'content':    txt,
      'isRead':     false,
      'createdAt':  DateTime.now().toIso8601String(),
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
          // ✅ tap name/avatar in chat → view their profile
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    UserProfileScreen(user: widget.participant)),
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
                      widget.participant.isTutor
                          ? '🏫 Tutor'
                          : '🎓 Student',
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
                  builder: (_) =>
                      UserProfileScreen(user: widget.participant)),
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
                                gradient: LinearGradient(colors: [
                                  AppTheme.primary, AppTheme.accent]),
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
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
                color: AppTheme.bgCard,
                border:
                    Border(top: BorderSide(color: AppTheme.divider))),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: AppTheme.divider)),
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
                const SizedBox(width: 10),
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

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = _fmt(msg['createdAt'] as String? ?? '');
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg['content'] as String? ?? '',
                style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    height: 1.4)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.6)
                            : AppTheme.textMuted,
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
                        ? Colors.lightBlueAccent
                        : Colors.white.withOpacity(0.6),
                  ),
                ],
              ],
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