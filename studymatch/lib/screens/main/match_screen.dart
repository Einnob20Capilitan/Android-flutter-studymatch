import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_theme.dart';
import '../../models/models.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _rotate;
  Offset _dragOffset = Offset.zero;
  bool? _liking;

  final _searchCtrl = TextEditingController();
  String _selectedSubject = 'All';
  bool _showSearch = false;

  final List<String> _subjects = [
    'All', 'Mathematics', 'Physics', 'Chemistry', 'Biology',
    'Computer Science', 'English', 'History', 'Statistics',
    'Calculus', 'Algebra', 'Programming',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(2, 0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _rotate = Tween<double>(begin: 0, end: 0.1).animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadMatchUsers();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    context.read<AppState>().loadMatchUsers(
      subject: _selectedSubject == 'All' ? null : _selectedSubject,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  void _swipe(bool like, AppState state) async {
    if (state.matchUsers.isEmpty) return;
    setState(() => _liking = like);
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(like ? 2 : -2, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _rotate = Tween<double>(begin: 0, end: like ? 0.15 : -0.15).animate(_ctrl);
    _ctrl.forward().then((_) {
      final userId = state.matchUsers.first.id;
      if (like) state.likeUser(userId);
      else state.passUser(userId);
      _ctrl.reset();
      setState(() { _liking = null; _dragOffset = Offset.zero; });
    });
  }

  void _showRatingDialog(BuildContext context, RealUser user) {
    int _selectedScore = 0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Rate ${user.fullName}',
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate this study partner?',
                  style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Poppins', fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setS(() => _selectedScore = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _selectedScore ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppTheme.warning,
                      size: 36,
                    ),
                  ),
                )),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: _selectedScore == 0 ? null : () async {
                Navigator.pop(ctx);
                await context.read<AppState>().rateUser(
                  ratedId: user.id, score: _selectedScore);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rating submitted!'), backgroundColor: AppTheme.success));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Submit', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('StudyMatch',
                              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold,
                                  fontSize: 18, fontFamily: 'Poppins')),
                        ]),
                        const Text('Find your study partner',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'Poppins')),
                      ]),
                      IconButton(
                        icon: Icon(_showSearch ? Icons.search_off : Icons.search,
                            color: AppTheme.textSecondary),
                        onPressed: () => setState(() => _showSearch = !_showSearch),
                      ),
                    ],
                  ),

                  // Search Panel
                  if (_showSearch) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search field
                          TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
                            decoration: InputDecoration(
                              hintText: 'Search by name...',
                              hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                              filled: true,
                              fillColor: AppTheme.inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                          const SizedBox(height: 12),
                          // Subject filter
                          const Text('Filter by Subject',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12,
                                  fontFamily: 'Poppins', letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _subjects.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final s = _subjects[i];
                                final sel = _selectedSubject == s;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedSubject = s),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: sel ? AppTheme.primary : AppTheme.inputBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: sel ? AppTheme.primary : AppTheme.divider),
                                    ),
                                    child: Text(s,
                                        style: TextStyle(
                                          color: sel ? Colors.white : AppTheme.textSecondary,
                                          fontFamily: 'Poppins', fontSize: 12,
                                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                                        )),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _search,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Search', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cards
            Expanded(
              child: state.loadingUsers
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : state.matchUsers.isEmpty
                      ? _EmptyState(onRefresh: () => state.loadMatchUsers())
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            if (state.matchUsers.length > 1)
                              Positioned(
                                top: 10,
                                child: Transform.scale(
                                  scale: 0.95,
                                  child: _MatchCard(
                                    user: state.matchUsers[1],
                                    overlay: null,
                                    onRate: () {},
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onPanUpdate: (d) => setState(() {
                                _dragOffset += d.delta;
                                _liking = _dragOffset.dx > 40 ? true
                                    : (_dragOffset.dx < -40 ? false : null);
                              }),
                              onPanEnd: (d) {
                                if (_dragOffset.dx.abs() > 100)
                                  _swipe(_dragOffset.dx > 0, state);
                                else
                                  setState(() { _dragOffset = Offset.zero; _liking = null; });
                              },
                              child: Transform.translate(
                                offset: _dragOffset,
                                child: Transform.rotate(
                                  angle: _dragOffset.dx / 400,
                                  child: SlideTransition(
                                    position: _slide,
                                    child: _MatchCard(
                                      user: state.matchUsers.first,
                                      overlay: _liking,
                                      onRate: () => _showRatingDialog(context, state.matchUsers.first),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SwipeButton(icon: Icons.close, color: AppTheme.error,
                      onTap: state.matchUsers.isNotEmpty ? () => _swipe(false, state) : null),
                  _SwipeButton(icon: Icons.star_rounded, color: AppTheme.warning,
                      onTap: state.matchUsers.isNotEmpty
                          ? () => _showRatingDialog(context, state.matchUsers.first) : null),
                  _SwipeButton(icon: Icons.favorite, color: AppTheme.success, size: 64,
                      onTap: state.matchUsers.isNotEmpty ? () => _swipe(true, state) : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final RealUser user;
  final bool? overlay;
  final VoidCallback onRate;

  const _MatchCard({required this.user, this.overlay, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 48,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D1F5E), Color(0xFF1A1730)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: overlay == true ? AppTheme.success.withOpacity(0.5)
              : overlay == false ? AppTheme.error.withOpacity(0.5)
              : AppTheme.divider,
          width: overlay != null ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(user.initials,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold, fontSize: 28, fontFamily: 'Poppins'))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName,
                                style: const TextStyle(color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
                            if (user.department != null) ...[
                              const SizedBox(height: 2),
                              Text(user.department!,
                                  style: const TextStyle(color: AppTheme.textSecondary,
                                      fontFamily: 'Poppins', fontSize: 13)),
                            ],
                            if (user.school != null) ...[
                              const SizedBox(height: 2),
                              Text(user.school!,
                                  style: const TextStyle(color: AppTheme.textMuted,
                                      fontFamily: 'Poppins', fontSize: 12)),
                            ],
                            const SizedBox(height: 6),
                            // Rating
                            GestureDetector(
                              onTap: onRate,
                              child: Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(
                                    i < user.rating.round()
                                        ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: AppTheme.warning, size: 16,
                                  )),
                                  const SizedBox(width: 4),
                                  Text('${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                                      style: const TextStyle(color: AppTheme.textMuted,
                                          fontSize: 11, fontFamily: 'Poppins')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 12),
                  if (user.subjects.isNotEmpty) ...[
                    _CardSection(title: '📚 Subjects', chips: user.subjects),
                    const SizedBox(height: 12),
                  ],
                  if (user.learningStyles.isNotEmpty) ...[
                    _CardSection(title: '🧠 Learning Style', chips: user.learningStyles),
                    const SizedBox(height: 12),
                  ],
                  if (user.studyStyles.isNotEmpty)
                    _CardSection(title: '👥 Study Format', chips: user.studyStyles),
                ],
              ),
            ),
            if (overlay != null)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: (overlay! ? AppTheme.success : AppTheme.error).withOpacity(0.15),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (overlay! ? AppTheme.success : AppTheme.error).withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(overlay! ? Icons.favorite : Icons.close,
                          color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final List<String> chips;
  const _CardSection({required this.title, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textSecondary,
            fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: chips.map((c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.chipBg, borderRadius: BorderRadius.circular(20)),
            child: Text(c, style: const TextStyle(color: AppTheme.textPrimary,
                fontSize: 11, fontFamily: 'Poppins')),
          )).toList(),
        ),
      ],
    );
  }
}

class _SwipeButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;
  const _SwipeButton({required this.icon, required this.color, this.onTap, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppTheme.bgCard, shape: BoxShape.circle,
                border: Border.all(color: AppTheme.divider)),
            child: const Icon(Icons.people_alt_outlined, color: AppTheme.textMuted, size: 38),
          ),
          const SizedBox(height: 20),
          const Text("No users found", style: TextStyle(color: AppTheme.textPrimary,
              fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          const Text('Try a different subject or search term.',
              style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Poppins')),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh', style: TextStyle(fontFamily: 'Poppins')),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}