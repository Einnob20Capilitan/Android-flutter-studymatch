import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_state.dart';
import '../../models/models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                stops: [0, 0.3],
                colors: [Color(0xFF1A0A3A), AppTheme.bgDark],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user?.fullName.split(' ').first ?? 'Student'} 👋',
                                  style: const TextStyle(color: AppTheme.textSecondary,
                                      fontSize: 13, fontFamily: 'Poppins'),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Find your perfect\nstudy partner today!",
                                  style: TextStyle(color: AppTheme.textPrimary,
                                      fontSize: 20, fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins', height: 1.3),
                                ),
                              ],
                            ),
                            // Avatar
                            Container(
                              width: 52, height: 52,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.bold, fontSize: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Stats row
                        Row(
                          children: [
                            Expanded(child: _StatCard(
                              label: 'Study\nPartners',
                              value: '${state.matchUsers.length}',
                              icon: Icons.people_alt_rounded,
                              color: AppTheme.primary,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(
                              label: 'Unread\nMessages',
                              value: '${state.unreadMessageCount}',
                              icon: Icons.chat_bubble_rounded,
                              color: AppTheme.accent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(
                              label: 'Study\nSessions',
                              value: '0',
                              icon: Icons.calendar_month_rounded,
                              color: AppTheme.success,
                            )),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // My Profile section
                        if (user != null && user.subjects.isNotEmpty) ...[
                          const Text('My Subjects',
                              style: TextStyle(color: AppTheme.textPrimary,
                                  fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: user.subjects.take(5).map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                              ),
                              child: Text(s, style: const TextStyle(
                                  color: AppTheme.primaryLight, fontSize: 12, fontFamily: 'Poppins')),
                            )).toList(),
                          ),
                          const SizedBox(height: 28),
                        ],

                        SectionHeader(title: '🔥 Top Study Partners', actionText: 'See all'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),

                // Top partners list
                if (state.loadingUsers)
                  const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )),
                  )
                else if (state.matchUsers.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'No study partners found yet.\nComplete your profile to find matches!',
                        style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins', height: 1.5),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.matchUsers.take(5).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) =>
                            _PartnerCard(user: state.matchUsers[i]),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.conversations.isNotEmpty) ...[
                          SectionHeader(title: '💬 Recent Messages', actionText: 'See all'),
                          const SizedBox(height: 14),
                          ...state.conversations.take(2).map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MessagePreviewCard(conversation: c),
                          )),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: const Center(
                              child: Text('No messages yet.\nMatch with study partners to start chatting!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textMuted,
                                      fontFamily: 'Poppins', height: 1.5)),
                            ),
                          ),
                      ],
                    ),
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

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22,
              fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textMuted,
              fontSize: 11, fontFamily: 'Poppins', height: 1.3)),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final RealUser user;
  const _PartnerCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(user.initials,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Poppins'))),
          ),
          const SizedBox(height: 10),
          Text(user.fullName, style: const TextStyle(color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (user.department != null) ...[
            const SizedBox(height: 2),
            Text(user.department!, style: const TextStyle(color: AppTheme.textMuted,
                fontSize: 11, fontFamily: 'Poppins'),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.warning, size: 14),
              const SizedBox(width: 2),
              Text(user.rating.toStringAsFixed(1),
                  style: const TextStyle(color: AppTheme.textSecondary,
                      fontSize: 11, fontFamily: 'Poppins')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessagePreviewCard extends StatelessWidget {
  final Conversation conversation;
  const _MessagePreviewCard({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final msg = conversation.lastMessage;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: conversation.unreadCount > 0
                ? AppTheme.primary.withOpacity(0.3) : AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(conversation.participant.initials,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conversation.participant.fullName,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14)),
                if (msg != null) ...[
                  const SizedBox(height: 2),
                  Text(msg.content, style: const TextStyle(color: AppTheme.textMuted,
                      fontSize: 12, fontFamily: 'Poppins'),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
              child: Text('${conversation.unreadCount}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}