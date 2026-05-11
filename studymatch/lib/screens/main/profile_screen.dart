import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/app_state.dart';
import '../../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user  = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final isTutor   = user.role == 'tutor';
    final roleColor = isTutor ? AppTheme.success : const Color(0xFF3B82F6);
    final roleLabel = isTutor ? '🏫 Tutor' : '🎓 Student';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          Container(
            height: 260,
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
                // ── App bar
                SliverToBoxAdapter(
                  child: Padding(
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
                          onPressed: () => _showSettingsSheet(context, state),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hero section
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // ✅ Avatar using ProfileAvatar widget
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen())),
                        child: Stack(
                          children: [
                            ProfileAvatar(
                              photoUrl:    user.profilePhotoUrl,
                              displayName: user.fullName,
                              size:        90,
                              borderColor: Colors.white,
                              borderWidth: 3,
                            ),
                            Positioned(
                              bottom: 2,
                              right:  2,
                              child: Container(
                                width:  26,
                                height: 26,
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
                      const SizedBox(height: 10),

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
                      const SizedBox(height: 10),

                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: roleColor.withOpacity(0.5)),
                        ),
                        child: Text(roleLabel,
                            style: TextStyle(
                                color: roleColor,
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),

                      // School
                      if (user.school != null &&
                          user.school!.isNotEmpty) ...[
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
                            ]),
                        const SizedBox(height: 4),
                      ],

                      // Department / Degree
                      if (user.department != null &&
                          user.department!.isNotEmpty) ...[
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
                        const SizedBox(height: 6),
                      ],

                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(user.bio!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  height: 1.5)),
                        ),
                        const SizedBox(height: 10),
                      ],

                      const SizedBox(height: 16),

                      // Stats bar
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppTheme.divider)),
                          child: Row(
                            children: [
                              _ProfileStat(
                                value: '${state.matchUsers.length}',
                                label: isTutor ? 'Students' : 'Tutors',
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

                // ── Attribute sections
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // Personal Info
                      _ProfileSection(
                        title: '👤 Personal Info',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Role',
                              value: isTutor ? 'Tutor' : 'Student',
                              valueColor: roleColor,
                            ),
                            if (user.gender != null &&
                                user.gender!.isNotEmpty)
                              _InfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Gender',
                                  value: user.gender!),
                            if (user.dateOfBirth != null)
                              _InfoRow(
                                icon: Icons.cake_outlined,
                                label: 'Birthday',
                                value:
                                    '${user.dateOfBirth!.month}/${user.dateOfBirth!.day}/${user.dateOfBirth!.year}',
                              ),
                            if (user.school != null &&
                                user.school!.isNotEmpty)
                              _InfoRow(
                                  icon: Icons.school_outlined,
                                  label: 'School',
                                  value: user.school!),
                            if (user.department != null &&
                                user.department!.isNotEmpty)
                              _InfoRow(
                                icon: isTutor
                                    ? Icons.workspace_premium_outlined
                                    : Icons.apartment_outlined,
                                label: isTutor ? 'Degree' : 'Department',
                                value: user.department!,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (user.subjects.isNotEmpty) ...[
                        _ProfileSection(
                          title: '📚 Subjects',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.subjects
                                .map((s) => _tag(s, AppTheme.primary))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.strengths.isNotEmpty) ...[
                        _ProfileSection(
                          title: isTutor
                              ? '💪 Can Tutor (Expert Subjects)'
                              : '💪 Strong Subjects',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.strengths
                                .map((s) => _tag(s, AppTheme.success))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.weaknesses.isNotEmpty) ...[
                        _ProfileSection(
                          title: isTutor
                              ? '📖 Still Learning'
                              : '😅 Needs Help With',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.weaknesses
                                .map((s) => _tag(s, AppTheme.error))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.learningStyles.isNotEmpty) ...[
                        _ProfileSection(
                          title: '🧠 Learning Style',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.learningStyles
                                .map((s) => _tag(s, AppTheme.accent))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.studyStyles.isNotEmpty) ...[
                        _ProfileSection(
                          title: '👥 Study Format',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.studyStyles
                                .map((s) => _tag(s, AppTheme.warning))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.availability.isNotEmpty) ...[
                        _ProfileSection(
                          title: '📅 Availability',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: user.availability.entries.map((e) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(e.key,
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: e.value
                                          .map((t) => _tag(t,
                                              const Color(0xFF3B82F6)))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.subjects.isEmpty &&
                          user.strengths.isEmpty &&
                          user.weaknesses.isEmpty &&
                          user.learningStyles.isEmpty &&
                          user.studyStyles.isEmpty &&
                          user.availability.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Text('📋',
                                  style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              const Text('No profile details yet',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      fontSize: 15)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Edit your profile to add your subjects,\nlearning style, and availability.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      height: 1.5)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen())),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Profile',
                                    style:
                                        TextStyle(fontFamily: 'Poppins')),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Account section
                      _ProfileSection(
                        title: '⚙️ Account',
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: Icons.person_outline,
                              label: 'Edit Profile',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const EditProfileScreen())),
                            ),
                            _SettingsRow(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              onTap: () =>
                                  _showSettingsSheet(context, state),
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
                              onTap: () =>
                                  _confirmSignOut(context, state),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings bottom sheet ─────────────────────────────────────────────────
  void _showSettingsSheet(BuildContext context, AppState state) {
    final user = state.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Settings',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 20),

            // ✅ Account info card using ProfileAvatar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    photoUrl:    user.profilePhotoUrl,
                    displayName: user.fullName,
                    size:        48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                fontSize: 15)),
                        Text(user.email,
                            style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontFamily: 'Poppins',
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (user.isTutor
                              ? AppTheme.success
                              : const Color(0xFF3B82F6))
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isTutor ? '🏫 Tutor' : '🎓 Student',
                      style: TextStyle(
                          color: user.isTutor
                              ? AppTheme.success
                              : const Color(0xFF3B82F6),
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SheetOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your name, bio, subjects',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()));
              },
            ),
            _SheetOption(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              color: AppTheme.accent,
              onTap: () => Navigator.pop(context),
            ),
            _SheetOption(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              subtitle: 'Control your data and visibility',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.pop(context),
            ),
            _SheetOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'FAQs and contact us',
              color: AppTheme.warning,
              onTap: () => Navigator.pop(context),
            ),
            _SheetOption(
              icon: Icons.info_outline,
              title: 'About StudyMatch',
              subtitle: 'Version 1.0.0',
              color: AppTheme.textMuted,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 8),
            _SheetOption(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Log out of your account',
              color: AppTheme.error,
              onTap: () {
                Navigator.pop(context);
                _confirmSignOut(context, state);
              },
            ),
          ],
        ),
      ),
    );
  }

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
                  style:
                      TextStyle(color: AppTheme.textSecondary))),
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

  Widget _tag(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
}

// ═══════════════════════════════════════════════════════════════
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              color: color == AppTheme.error
                  ? AppTheme.error
                  : AppTheme.textPrimary,
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: AppTheme.textMuted,
              fontFamily: 'Poppins',
              fontSize: 12)),
      trailing: color == AppTheme.error
          ? null
          : const Icon(Icons.chevron_right,
              color: AppTheme.textMuted, size: 18),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _ProfileStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _ProfileStat(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

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

// ═══════════════════════════════════════════════════════════════
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppTheme.divider);
}

// ═══════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SettingsRow(
      {required this.icon,
      required this.label,
      this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: c, size: 20),
      title: Text(label,
          style: TextStyle(
              color: c, fontFamily: 'Poppins', fontSize: 14)),
      trailing: color == null
          ? const Icon(Icons.chevron_right,
              color: AppTheme.textMuted, size: 20)
          : null,
      onTap: onTap,
    );
  }
}