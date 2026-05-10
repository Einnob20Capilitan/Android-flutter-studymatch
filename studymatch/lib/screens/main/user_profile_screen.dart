import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/app_state.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../main/messages_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final RealUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // ── Reviews state ──────────────────────────────────────────────────────────
  List<TutorReview> _reviews     = [];
  bool _loadingReviews           = false;
  int? _myExistingRating;
  String _myExistingReview       = '';

  @override
  void initState() {
    super.initState();
    if (widget.user.role == 'tutor') {
      _fetchReviews();
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => _loadingReviews = true);
    final me = context.read<AppState>().currentUser;
    final result = await ApiService.getReviews(
      tutorId:  widget.user.id,
      raterId:  me?.id,
    );
    if (mounted) {
      setState(() {
        _reviews           = result.reviews;
        _myExistingRating  = result.myRating;
        _myExistingReview  = result.myReview ?? '';
        _loadingReviews    = false;
      });
    }
  }

  // ── Rate & Review bottom sheet ─────────────────────────────────────────────
  void _showRateSheet(BuildContext context) {
    final me = context.read<AppState>().currentUser;
    if (me == null) return;

    // Seed with existing values if the user already rated
    int selectedStars           = _myExistingRating ?? 0;
    final reviewCtrl            = TextEditingController(text: _myExistingReview);
    bool submitting             = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1035),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF2E2850), width: 1),
              left: BorderSide(color: Color(0xFF2E2850), width: 1),
              right: BorderSide(color: Color(0xFF2E2850), width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2850),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(widget.user.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Poppins')),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _myExistingRating != null
                                ? 'Update Your Review'
                                : 'Rate This Tutor',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                fontFamily: 'Poppins'),
                          ),
                          Text(widget.user.fullName,
                              style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontFamily: 'Poppins',
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Star picker
                const Text('How would you rate this tutor?',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < selectedStars;
                    return GestureDetector(
                      onTap: () => setS(() => selectedStars = i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: filled ? AppTheme.warning : const Color(0xFF3D3660),
                          size: 44,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _starLabel(selectedStars),
                    style: TextStyle(
                        color: selectedStars > 0 ? AppTheme.warning : AppTheme.textMuted,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),

                // Written review
                const Text('Write a review (optional)',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                TextField(
                  controller: reviewCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this tutor. '
                        'How helpful were they? What did they teach well?',
                    hintStyle: const TextStyle(
                        color: AppTheme.textMuted,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        height: 1.5),
                    filled: true,
                    fillColor: const Color(0xFF120D2A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2E2850))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2E2850))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primary)),
                    counterStyle: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (submitting || selectedStars == 0)
                        ? null
                        : () async {
                            setS(() => submitting = true);
                            final result = await context.read<AppState>().rateUser(
                              ratedId: widget.user.id,
                              score:   selectedStars,
                              review:  reviewCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              final ok = result['success'] == true;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok
                                    ? '✅ Review submitted!'
                                    : result['message'] ?? 'Failed to submit'),
                                backgroundColor: ok ? AppTheme.success : AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ));
                              if (ok) _fetchReviews();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.primary.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _myExistingRating != null
                                ? 'Update Review'
                                : 'Submit Review',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return 'Tap a star to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final me       = state.currentUser;
    final isTutor  = widget.user.role == 'tutor';
    final roleColor = isTutor ? AppTheme.success : const Color(0xFF3B82F6);
    final roleLabel = isTutor ? '🏫 Tutor' : '🎓 Student';

    final myWeaknesses = me?.weaknesses ?? [];
    final myStrengths  = me?.strengths  ?? [];

    int compatScore = 0;
    if (isTutor) {
      compatScore = widget.user.strengths
          .where((s) => myWeaknesses.contains(s)).length;
    } else {
      compatScore = widget.user.weaknesses
          .where((s) => myStrengths.contains(s)).length;
    }

    // Can the current user rate this tutor?
    final canRate = me != null && me.id != widget.user.id && isTutor;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
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
                // ── App bar ────────────────────────────────────────────────
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
                        // Rate button in app bar (tutors only)
                        if (canRate)
                          TextButton.icon(
                            onPressed: () => _showRateSheet(context),
                            icon: Icon(
                              _myExistingRating != null
                                  ? Icons.edit_outlined
                                  : Icons.star_outline_rounded,
                              color: AppTheme.warning,
                              size: 18,
                            ),
                            label: Text(
                              _myExistingRating != null ? 'Edit Review' : 'Rate',
                              style: const TextStyle(
                                  color: AppTheme.warning,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Hero section ───────────────────────────────────────────
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
                          child: Text(widget.user.initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 38,
                                  fontFamily: 'Poppins')),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(widget.user.fullName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),

                      Text(widget.user.email,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontFamily: 'Poppins',
                              fontSize: 13)),
                      const SizedBox(height: 10),

                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      if (widget.user.school != null && widget.user.school!.isNotEmpty) ...[
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.school_outlined, color: AppTheme.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Text(widget.user.school!,
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontFamily: 'Poppins', fontSize: 13)),
                        ]),
                        const SizedBox(height: 4),
                      ],

                      // Department
                      if (widget.user.department != null && widget.user.department!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(widget.user.department!,
                              style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Bio
                      if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(widget.user.bio!,
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
                            // Rating card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: AppTheme.bgCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.divider)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (i) => Icon(
                                            i < widget.user.rating.round()
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            color: AppTheme.warning, size: 16)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.user.rating.toStringAsFixed(1)} (${widget.user.ratingCount})',
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
                            // Compatibility card
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
                                            ? AppTheme.success.withOpacity(0.4)
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
                                        compatScore > 0 ? '✅ Match!' : 'No match',
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

                // ── Attribute + Review sections ────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      if (widget.user.subjects.isNotEmpty) ...[
                        _Section(title: '📚 Subjects',
                            child: _chips(widget.user.subjects, AppTheme.primary)),
                        const SizedBox(height: 12),
                      ],

                      if (widget.user.strengths.isNotEmpty) ...[
                        _Section(
                          title: isTutor
                              ? '💪 Can Tutor (Expert Subjects)'
                              : '💪 Strong Subjects',
                          child: _chips(widget.user.strengths, AppTheme.success),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (widget.user.weaknesses.isNotEmpty) ...[
                        _Section(
                          title: isTutor ? '📖 Still Learning' : '😅 Needs Help With',
                          child: _chips(widget.user.weaknesses, AppTheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (widget.user.learningStyles.isNotEmpty) ...[
                        _Section(
                            title: '🧠 Learning Style',
                            child: _chips(widget.user.learningStyles, AppTheme.accent)),
                        const SizedBox(height: 12),
                      ],

                      if (widget.user.studyStyles.isNotEmpty) ...[
                        _Section(
                            title: '👥 Study Format',
                            child: _chips(widget.user.studyStyles, AppTheme.warning)),
                        const SizedBox(height: 12),
                      ],

                      // ── Reviews section (tutors only) ─────────────────────
                      if (isTutor) ...[
                        _ReviewsSection(
                          reviews:        _reviews,
                          loading:        _loadingReviews,
                          myExistingRating: _myExistingRating,
                          canRate:        canRate,
                          onRate:         () => _showRateSheet(context),
                          currentUserId:  me?.id ?? '',
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Message button ─────────────────────────────────────
                      if (me != null && me.id != widget.user.id) ...[
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
                                        ChatScreen(participant: widget.user)),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text(
                                'Message ${widget.user.fullName.split(' ').first}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
        spacing: 8, runSpacing: 8,
        children: items
            .map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

// ── Reviews section widget ────────────────────────────────────────────────────
class _ReviewsSection extends StatelessWidget {
  final List<TutorReview> reviews;
  final bool loading;
  final int? myExistingRating;
  final bool canRate;
  final VoidCallback onRate;
  final String currentUserId;

  const _ReviewsSection({
    required this.reviews,
    required this.loading,
    required this.myExistingRating,
    required this.canRate,
    required this.onRate,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('⭐ Ratings & Reviews',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Poppins')),
                ),
                if (canRate)
                  GestureDetector(
                    onTap: onRate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            myExistingRating != null
                                ? Icons.edit_rounded
                                : Icons.star_rounded,
                            color: Colors.white, size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            myExistingRating != null ? 'Edit' : 'Rate',
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2)),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  const Text('No reviews yet',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    canRate
                        ? 'Be the first to leave a review!'
                        : 'No one has reviewed this tutor yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        height: 1.4),
                  ),
                  if (canRate) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: onRate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Write a Review',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 20, color: AppTheme.divider, thickness: 0.5),
              itemBuilder: (_, i) => _ReviewTile(review: reviews[i]),
            ),
        ],
      ),
    );
  }
}

// ── Single review tile ────────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final TutorReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final initial = review.raterName.isNotEmpty
        ? review.raterName[0].toUpperCase()
        : '?';

    // Parse date
    String dateStr = '';
    try {
      final dt = DateTime.parse(review.createdAt);
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {}

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: review.isOwn
                ? const LinearGradient(colors: [AppTheme.primary, AppTheme.accent])
                : const LinearGradient(
                    colors: [Color(0xFF2D1F5E), Color(0xFF3D2F7E)]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Poppins')),
          ),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + "You" badge + date
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          review.isOwn ? 'You' : review.raterName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        if (review.isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                            ),
                            child: const Text('Your review',
                                style: TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontFamily: 'Poppins',
                            fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),

              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.score
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppTheme.warning,
                    size: 15,
                  ),
                ),
              ),

              // Review text
              if (review.review.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(review.review,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        height: 1.5)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────
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