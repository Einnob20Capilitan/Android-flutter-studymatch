import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/app_state.dart';
import '../../models/models.dart';
import '../main/messages_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final RealUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final me       = state.currentUser;
    final isTutor  = user.role == 'tutor';
    final roleColor = isTutor ? AppTheme.success : const Color(0xFF3B82F6);
    final roleLabel = isTutor ? '🏫 Tutor' : '🎓 Student';

    // Compatibility score between me and this user
    final myWeaknesses = me?.weaknesses ?? [];
    final myStrengths  = me?.strengths  ?? [];
    final theirStrengths  = user.strengths;
    final theirWeaknesses = user.weaknesses;

    int compatScore = 0;
    if (isTutor) {
      compatScore = theirStrengths
          .where((s) => myWeaknesses.contains(s)).length;
    } else {
      compatScore = theirWeaknesses
          .where((s) => myStrengths.contains(s)).length;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Gradient header
          Container(
            height: 280,
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
                // App bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text('Profile',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  ),
                ),

                // Hero
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Avatar
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent]),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(user.initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 38,
                                  fontFamily: 'Poppins')),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(user.fullName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),

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
                          border: Border.all(color: roleColor.withOpacity(0.5)),
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
                      if (user.school != null && user.school!.isNotEmpty) ...[
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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

                      // Department
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
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 12),

                      // Stats row: rating + compatibility
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // Rating
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: AppTheme.bgCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.divider)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                          5,
                                          (i) => Icon(
                                                i < user.rating.round()
                                                    ? Icons.star_rounded
                                                    : Icons
                                                        .star_border_rounded,
                                                color: AppTheme.warning,
                                                size: 16,
                                              )),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontFamily: 'Poppins'),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Rating',
                                        style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 11,
                                            fontFamily: 'Poppins')),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Compatibility
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: compatScore > 0
                                        ? AppTheme.success.withOpacity(0.1)
                                        : AppTheme.bgCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: compatScore > 0
                                            ? AppTheme.success
                                                .withOpacity(0.4)
                                            : AppTheme.divider)),
                                child: Column(
                                  children: [
                                    Text('$compatScore',
                                        style: TextStyle(
                                            color: compatScore > 0
                                                ? AppTheme.success
                                                : AppTheme.textMuted,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins')),
                                    const SizedBox(height: 2),
                                    Text(
                                        compatScore > 0
                                            ? '✅ Match!'
                                            : 'No match',
                                        style: TextStyle(
                                            color: compatScore > 0
                                                ? AppTheme.success
                                                : AppTheme.textMuted,
                                            fontSize: 11,
                                            fontFamily: 'Poppins')),
                                    const SizedBox(height: 2),
                                    const Text('Compatibility',
                                        style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 11,
                                            fontFamily: 'Poppins')),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Attribute sections
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      if (user.subjects.isNotEmpty) ...[
                        _Section(title: '📚 Subjects',
                            child: _chips(user.subjects, AppTheme.primary)),
                        const SizedBox(height: 12),
                      ],

                      if (user.strengths.isNotEmpty) ...[
                        _Section(
                          title: isTutor
                              ? '💪 Can Tutor (Expert Subjects)'
                              : '💪 Strong Subjects',
                          child: _chips(user.strengths, AppTheme.success),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.weaknesses.isNotEmpty) ...[
                        _Section(
                          title: isTutor
                              ? '📖 Still Learning'
                              : '😅 Needs Help With',
                          child: _chips(user.weaknesses, AppTheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user.learningStyles.isNotEmpty) ...[
                        _Section(
                            title: '🧠 Learning Style',
                            child: _chips(
                                user.learningStyles, AppTheme.accent)),
                        const SizedBox(height: 12),
                      ],

                      if (user.studyStyles.isNotEmpty) ...[
                        _Section(
                            title: '👥 Study Format',
                            child: _chips(
                                user.studyStyles, AppTheme.warning)),
                        const SizedBox(height: 12),
                      ],

                      // Message button
                      if (me != null && me.id != user.id) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(participant: user)),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 18),
                            label: Text(
                                'Message ${user.fullName.split(' ').first}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
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

  Widget _chips(List<String> items, Color color) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((s) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          color: color,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ))
            .toList(),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

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