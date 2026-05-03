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

// ── Messages Screen ───────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchCtrl = TextEditingController();
  List<RealUser>             _allUsers  = [];
  List<RealUser>             _filtered  = [];
  List<Map<String, dynamic>> _inbox     = [];
  bool   _loadingUsers = false;
  bool   _loadingInbox = true;
  bool   _showUserList = false;
  Timer? _refreshTimer;

  static const _base = 'http://localhost/StudyMatch/studymatch-api';
  static const _key  = 'studymatch_api_key_2026';

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
      if (mounted) {
        setState(() {
          _inbox       = data;
          _loadingInbox = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInbox = false);
    }
  }

  Future<void> _loadUsers() async {
    final me = context.read<AppState>().currentUser;
    if (me == null) return;
    setState(() => _loadingUsers = true);
    try {
      final uri = Uri.parse('$_base/api.php').replace(queryParameters: {
        'action':     'get_users',
        'api_key':    _key,
        'exclude_id': me.id,
      });
      final res  = await http.get(uri);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true && mounted) {
        setState(() {
          _allUsers = (data['data'] as List)
              .map((u) => RealUser.fromJson(u as Map<String, dynamic>))
              .toList();
          _filtered = _allUsers;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingUsers = false);
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _allUsers
          : _allUsers
              .where((u) =>
                  u.fullName.toLowerCase().contains(q.toLowerCase()) ||
                  (u.department ?? '')
                      .toLowerCase()
                      .contains(q.toLowerCase()))
              .toList();
    });
  }

  void _openChat(RealUser user) {
    setState(() {
      _showUserList = false;
      _searchCtrl.clear();
      _filtered = _allUsers;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(participant: user)),
    ).then((_) => _loadInbox());
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().currentUser;
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                    icon: Icon(
                      _showUserList ? Icons.close : Icons.edit_outlined,
                      color: AppTheme.textSecondary),
                    tooltip: _showUserList ? 'Cancel' : 'New Message',
                    onPressed: () =>
                        setState(() => _showUserList = !_showUserList),
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
                onChanged: (v) {
                  _onSearch(v);
                  if (v.isNotEmpty) setState(() => _showUserList = true);
                },
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 14),
                decoration: InputDecoration(
                  hintText: _showUserList
                      ? 'Search users...'
                      : 'Search conversations...',
                  hintStyle: const TextStyle(
                      color: AppTheme.textMuted, fontFamily: 'Poppins'),
                  prefixIcon: const Icon(Icons.search,
                      color: AppTheme.textMuted, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          })
                      : null,
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

            // Body
            Expanded(
              child: _showUserList
                  ? _buildUserList()
                  : _buildInbox(me?.id ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_loadingUsers) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_filtered.isEmpty) {
      return Center(
          child: Text(
        _searchCtrl.text.isEmpty
            ? 'No users found'
            : 'No results for "${_searchCtrl.text}"',
        style: const TextStyle(
            color: AppTheme.textMuted, fontFamily: 'Poppins'),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            '${_filtered.length} users — tap to message',
            style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontFamily: 'Poppins'),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppTheme.divider, height: 1),
            itemBuilder: (ctx, i) {
              final user = _filtered[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6),
                leading: UserAvatar(realUser: user, radius: 24),
                title: Text(user.fullName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 15)),
                subtitle: Text(
                    user.department ?? user.school ?? user.email,
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontFamily: 'Poppins',
                        fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Message',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                onTap: () => _openChat(user),
              );
            },
          ),
        ),
      ],
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
            const Text('Tap ✏️ to start a conversation',
                style: TextStyle(
                    color: AppTheme.textMuted, fontFamily: 'Poppins')),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showUserList = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('New Message',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8),
            leading: UserAvatar(realUser: participant, radius: 26),
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

  List<Map<String, dynamic>> _messages    = [];
  bool   _loading      = true;
  bool   _sending      = false;
  bool   _pausePolling = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _loadMessages(silent: true));
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

  // ── Load messages ───────────────────────────────────────────
  Future<void> _loadMessages({bool silent = false}) async {
    if (_pausePolling) return;
    if (!silent) setState(() => _loading = true);
    try {
      final msgs = await MessageService.getMessages(
        userId:  _myId,
        otherId: widget.participant.id,
      );
      if (mounted && !_pausePolling) {
        final wasAtBottom = _scrollCtrl.hasClients &&
            _scrollCtrl.position.pixels >=
                _scrollCtrl.position.maxScrollExtent - 100;
        setState(() {
          _messages = msgs;
          _loading  = false;
        });
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

  // ── Send message ────────────────────────────────────────────
  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _sending) return;

    _msgCtrl.clear();
    _pausePolling = true;
    setState(() => _sending = true);

    // Add optimistic message
    final tempId  = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id':         tempId,
      'senderId':   _myId,
      'receiverId': widget.participant.id,
      'content':    txt,
      'isRead':     false,
      'createdAt':  DateTime.now().toIso8601String(),
      'senderName': 'Me',
    };
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      final result = await MessageService.sendMessage(
        senderId:   _myId,
        receiverId: widget.participant.id,
        content:    txt,
      );

      if (result['success'] == true) {
        // Fetch real messages BEFORE resuming poll
        final msgs = await MessageService.getMessages(
          userId:  _myId,
          otherId: widget.participant.id,
        );
        _pausePolling = false;
        if (mounted) {
          setState(() {
            _messages = msgs;
            _sending  = false;
          });
          _scrollToBottom();
        }
      } else {
        _pausePolling = false;
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m['id'] == tempId);
            _sending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                result['message'] as String? ?? 'Failed to send'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
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
        title: Row(
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
                    widget.participant.department ??
                        widget.participant.school ??
                        '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                                child: Text(
                                  widget.participant.initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28),
                                ),
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
                border: Border(
                    top: BorderSide(color: AppTheme.divider))),
            child: Row(
              children: [
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
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppTheme.primary, AppTheme.accent]),
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
    final time = _formatTime(msg['createdAt'] as String? ?? '');
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
          border:
              isMe ? null : Border.all(color: AppTheme.divider),
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

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}