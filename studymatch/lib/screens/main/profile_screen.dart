import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/app_state.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user  = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1F5E), Color(0xFF1A0A3A)],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('My Profile',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'Poppins')),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined,
                                  color: AppTheme.textSecondary),
                              onPressed: () => _showSettings(context, state),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen())),
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.accent]),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 38,
                                      fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2, right: 2,
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(user.fullName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),

                      // Email
                      Text(user.email,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontFamily: 'Poppins',
                              fontSize: 13)),

                      // School
                      if (user.school != null && user.school!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined,
                                color: AppTheme.textMuted, size: 14),
                            const SizedBox(width: 4),
                            Text(user.school!,
                                style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontFamily: 'Poppins',
                                    fontSize: 13)),
                          ],
                        ),
                      ],

                      // Department
                      if (user.department != null &&
                          user.department!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(user.department!,
                              style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],

                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(user.bio!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  height: 1.5)),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Stats bar — real data
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider)),
                          child: Row(
                            children: [
                              _ProfileStat(
                                value: '${state.matchUsers.length}',
                                label: 'Partners',
                                icon: Icons.people_alt_rounded,
                                color: AppTheme.primary,
                              ),
                              _VerticalDivider(),
                              _ProfileStat(
                                value: '${state.unreadMessageCount}',
                                label: 'Messages',
                                icon: Icons.chat_bubble_rounded,
                                color: AppTheme.accent,
                              ),
                              _VerticalDivider(),
                              _ProfileStat(
                                value: '${state.dbResources.length}',
                                label: 'Resources',
                                icon: Icons.library_books_rounded,
                                color: AppTheme.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Sections
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Subjects
                        if (user.subjects.isNotEmpty) ...[
                          _ProfileSection(
                            title: '📚 Subjects',
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: user.subjects.map((s) =>
                                  _tag(s, AppTheme.primary)).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Strengths
                        if (user.strengths.isNotEmpty) ...[
                          _ProfileSection(
                            title: '💪 Strong Subjects',
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: user.strengths.map((s) =>
                                  _tag(s, AppTheme.success)).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Weaknesses
                        if (user.weaknesses.isNotEmpty) ...[
                          _ProfileSection(
                            title: '📖 Needs Help With',
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: user.weaknesses.map((s) =>
                                  _tag(s, AppTheme.error)).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Learning styles
                        if (user.learningStyles.isNotEmpty) ...[
                          _ProfileSection(
                            title: '🧠 Learning Style',
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: user.learningStyles.map((s) =>
                                  _tag(s, AppTheme.accent)).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Study format
                        if (user.studyStyles.isNotEmpty) ...[
                          _ProfileSection(
                            title: '👥 Study Format',
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: user.studyStyles.map((s) =>
                                  _tag(s, AppTheme.warning)).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Availability
                        if (user.availability.isNotEmpty) ...[
                          _ProfileSection(
                            title: '📅 Availability',
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: user.availability.keys.map((day) =>
                                  _tag(day, const Color(0xFF3B82F6))).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Account settings
                        _ProfileSection(
                          title: '⚙️ Account',
                          child: Column(
                            children: [
                              _SettingsRow(
                                icon: Icons.person_outline,
                                label: 'Edit Profile',
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen())),
                              ),
                              _SettingsRow(
                                icon: Icons.notifications_outlined,
                                label: 'Notifications',
                                onTap: () {},
                              ),
                              _SettingsRow(
                                icon: Icons.privacy_tip_outlined,
                                label: 'Privacy Settings',
                                onTap: () {},
                              ),
                              _SettingsRow(
                                icon: Icons.help_outline,
                                label: 'Help & Support',
                                onTap: () {},
                              ),
                              _SettingsRow(
                                icon: Icons.logout,
                                label: 'Sign Out',
                                color: AppTheme.error,
                                onTap: () => _confirmSignOut(context, state),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
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

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );

  void _showSettings(BuildContext context, AppState state) {}

  void _confirmSignOut(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(
                color: AppTheme.textSecondary, fontFamily: 'Poppins')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              state.signOut();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Sign Out',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppTheme.divider);
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: c, size: 20),
      title: Text(label,
          style:
              TextStyle(color: c, fontFamily: 'Poppins', fontSize: 14)),
      trailing: color == null
          ? const Icon(Icons.chevron_right,
              color: AppTheme.textMuted, size: 20)
          : null,
      onTap: onTap,
    );
  }
}