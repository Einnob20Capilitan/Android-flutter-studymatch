import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_theme.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  // Step 0 — Role
  String? _role;

  // Step 1 — Basic Info
  final _schoolCtrl = TextEditingController();
  final _bioCtrl    = TextEditingController();
  final _degreeCtrl = TextEditingController(); // ✅ NEW: tutor degree input
  String? _gender;
  DateTime? _dob;
  String? _department; // used only for students

  // Step 2 — Subjects
  final Set<String> _subjects   = {};
  final Set<String> _strengths  = {};
  final Set<String> _weaknesses = {};

  // Step 3 — Schedule
  final Set<String> _days       = {};
  final Set<String> _timeBlocks = {};

  // Step 4 — Study Style
  final Set<String> _learningStyles = {};
  final Set<String> _studyStyles    = {};

  bool _saving = false;

  static const _subjectList = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English',
    'Computer Science', 'History', 'Economics', 'Statistics', 'Filipino',
  ];
  static const _deptList  = ['CET', 'CTE', 'CCJ', 'CAS', 'CBE', 'COAHS'];
  static const _dayList   = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _timeList  = [
    'Morning (6am-12pm)', 'Afternoon (12pm-6pm)',
    'Evening (6pm-9pm)',  'Night (9pm-6am)',
  ];
  static const _learnStyles = [
    ('👁️', 'Visual',      'Learn through diagrams & charts'),
    ('🎧', 'Auditory',    'Learn through listening & discussion'),
    ('📖', 'Reading',     'Learn through reading & writing'),
    ('🤚', 'Kinesthetic', 'Learn through practice & doing'),
  ];
  static const _studyFmts = [
    ('👥', 'Group',      'Learn better with others'),
    ('🧘', 'Individual', 'Learn better alone'),
  ];

  bool get _isTutor => _role == 'tutor';

  // ✅ FIX: total steps is 5 (0–4), so this must be 5
  static const int _totalSteps = 5;

  @override
  void dispose() {
    _schoolCtrl.dispose();
    _bioCtrl.dispose();
    _degreeCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final state = context.read<AppState>();
    final step  = state.onboardingStep;

    if (step == 0) {
      if (_role == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select your role to continue'),
          backgroundColor: AppTheme.error,
        ));
        return;
      }
      state.updateUserProfile({'role': _role});
      state.nextOnboardingStep();

    } else if (step == 1) {
      state.updateUserProfile({
        'school':      _schoolCtrl.text.trim(),
        'gender':      _gender,
        'dateOfBirth': _dob?.toIso8601String(),
        // ✅ tutors save their degree as department; students save chip selection
        'department':  _isTutor ? _degreeCtrl.text.trim() : _department,
        'bio':         _bioCtrl.text.trim(),
      });
      state.nextOnboardingStep();

    } else if (step == 2) {
      state.updateUserProfile({
        'subjects':   _subjects.toList(),
        'strengths':  _strengths.toList(),
        'weaknesses': _weaknesses.toList(),
      });
      state.nextOnboardingStep();

    } else if (step == 3) {
      final avail = <String, List<String>>{};
      for (final d in _days) avail[d] = _timeBlocks.toList();
      state.updateUserProfile({'availability': avail});
      state.nextOnboardingStep();

    } else if (step == 4) {
      state.updateUserProfile({
        'learningStyles': _learningStyles.toList(),
        'studyStyles':    _studyStyles.toList(),
      });
      setState(() => _saving = true);
      await state.completeOnboarding();
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() => context.read<AppState>().previousOnboardingStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final step  = state.onboardingStep;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Icon
            Text(
              ['🎭', '🎓', '📖', '📅', '✨'][step],
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              ['Who are you?', 'Basic Information', 'Your Subjects',
               'Study Schedule', 'Study Style'][step],
              style: const TextStyle(
                color: Colors.white, fontSize: 24,
                fontWeight: FontWeight.bold, fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              _stepSubtitle(step),
              style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),

            // Progress bar — ✅ uses _totalSteps = 5
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: List.generate(_totalSteps, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= step ? AppTheme.primary : AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 24),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1535),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: _buildStep(step),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.divider),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('← Back',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontFamily: 'Poppins')),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      // ✅ FIX: onPressed is always active (not null) unless saving
                      onPressed: _saving ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              // ✅ FIX: last step is index 4 (_totalSteps - 1)
                              step == _totalSteps - 1 ? '✨ Finish Setup' : 'Next →',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepSubtitle(int step) {
    return [
      'Choose your role in StudyMatch',
      'Tell us about your academic background',
      _isTutor
          ? 'Select subjects you can teach and your expertise'
          : 'Select subjects you study and where you need help',
      _isTutor ? 'When are you available to tutor?' : 'When are you available to study?',
      'How do you prefer to learn?',
    ][step];
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0: return _buildRoleSelection();
      case 1: return _buildBasicInfo();
      case 2: return _isTutor ? _buildTutorSubjects() : _buildStudentSubjects();
      case 3: return _buildSchedule();
      case 4: return _buildStudyStyle();
      default: return const SizedBox();
    }
  }

  // ── Step 0 — Role Selection ───────────────────────────────────────────────
  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Select your role'),
        const SizedBox(height: 8),
        const Text(
          'Your role determines how you are matched with others. You can always update this later from your profile.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'Poppins', height: 1.5),
        ),
        const SizedBox(height: 20),
        _RoleCard(
          emoji: '🎓', title: 'Student', subtitle: 'I want to find study partners and tutors to help me with difficult subjects.',
          badge: 'Learner', badgeColor: const Color(0xFF3B82F6),
          features: const [
            '📚 Get matched with tutors in your weak subjects',
            '👥 Find study partners at your level',
            '📈 Track your learning progress',
          ],
          selected: _role == 'student',
          onTap: () => setState(() => _role = 'student'),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          emoji: '🏫', title: 'Tutor', subtitle: 'I want to help other students by sharing my knowledge in my strong subjects.',
          badge: 'Educator', badgeColor: AppTheme.success,
          features: const [
            '💪 Get matched with students who need your expertise',
            '⭐ Build your reputation with ratings',
            '🤝 Grow your tutoring network',
          ],
          selected: _role == 'tutor',
          onTap: () => setState(() => _role = 'tutor'),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Students are matched with tutors whose strong subjects overlap with the student\'s weak subjects — so everyone finds the right partner.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Poppins', height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 1 — Basic Info ───────────────────────────────────────────────────
  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roleBadge(),
        const SizedBox(height: 20),

        _label('School / University'),
        const SizedBox(height: 8),
        _textField(_schoolCtrl, 'e.g. University of Santo Tomas', icon: Icons.school_outlined),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Gender'),
                  const SizedBox(height: 8),
                  _dropdown(
                    value: _gender,
                    hint: 'Select gender',
                    items: const ['Male', 'Female', 'Non-Binary', 'Prefer not to say'],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Date of Birth'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dob ?? DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.primary,
                              surface: AppTheme.bgCard,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (d != null) setState(() => _dob = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, color: AppTheme.textMuted, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _dob != null ? '${_dob!.month}/${_dob!.day}/${_dob!.year}' : 'mm/dd/yyyy',
                          style: TextStyle(
                            color: _dob != null ? AppTheme.textPrimary : AppTheme.textMuted,
                            fontFamily: 'Poppins', fontSize: 13,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ✅ TUTORS get a free-text degree field; STUDENTS get department chips
        if (_isTutor) ...[
          _label('College Degree'),
          const SizedBox(height: 8),
          _textField(
            _degreeCtrl,
            'e.g. Bachelor of Science in Computer Science',
            icon: Icons.school_outlined,
          ),
        ] else ...[
          _label('College Department'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _deptList.map((d) => _chip(
              d, _department == d,
              () => setState(() => _department = _department == d ? null : d),
            )).toList(),
          ),
        ],

        const SizedBox(height: 16),
        _label('Bio (Optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins', fontSize: 13),
          decoration: InputDecoration(
            hintText: _isTutor
                ? 'Tell students about your teaching approach...'
                : 'Tell others about yourself...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
            filled: true,
            fillColor: AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }

  // ── Step 2 — Subjects: Student ────────────────────────────────────────────
  Widget _buildStudentSubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roleBadge(),
        const SizedBox(height: 20),
        _label('Subjects you study'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => _chip(
            s, _subjects.contains(s),
            () => setState(() => _subjects.contains(s) ? _subjects.remove(s) : _subjects.add(s)),
          )).toList(),
        ),
        const SizedBox(height: 24),
        _label('😅 Subjects you need help with'),
        const SizedBox(height: 6),
        const Text('Tutors strong in these subjects will be prioritised in your matches',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => _chip(
            s, _weaknesses.contains(s),
            () => setState(() => _weaknesses.contains(s) ? _weaknesses.remove(s) : _weaknesses.add(s)),
            selectedColor: AppTheme.error,
          )).toList(),
        ),
      ],
    );
  }

  // ── Step 2 — Subjects: Tutor ──────────────────────────────────────────────
  Widget _buildTutorSubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roleBadge(),
        const SizedBox(height: 20),
        _label('Subjects you teach / know well'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => _chip(
            s, _subjects.contains(s),
            () => setState(() => _subjects.contains(s) ? _subjects.remove(s) : _subjects.add(s)),
          )).toList(),
        ),
        const SizedBox(height: 24),
        _label('💪 Subjects you can tutor (your expertise)'),
        const SizedBox(height: 6),
        const Text('Students who are weak in these subjects will be matched with you',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => _chip(
            s, _strengths.contains(s),
            () => setState(() => _strengths.contains(s) ? _strengths.remove(s) : _strengths.add(s)),
            selectedColor: AppTheme.success,
          )).toList(),
        ),
        const SizedBox(height: 24),
        _label('📖 Subjects you\'re still learning (Optional)'),
        const SizedBox(height: 6),
        const Text('Helps find peer study partners for these subjects',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => _chip(
            s, _weaknesses.contains(s),
            () => setState(() => _weaknesses.contains(s) ? _weaknesses.remove(s) : _weaknesses.add(s)),
            selectedColor: const Color(0xFF8B5CF6),
          )).toList(),
        ),
      ],
    );
  }

  // ── Step 3 — Schedule ─────────────────────────────────────────────────────
  Widget _buildSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roleBadge(),
        const SizedBox(height: 20),
        _label(_isTutor ? 'Days you\'re available to tutor' : 'Study Days'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _dayList.map((d) => _chip(
            d, _days.contains(d),
            () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
          )).toList(),
        ),
        const SizedBox(height: 20),
        _label('Time Blocks'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _timeList.map((t) => _chip(
            t, _timeBlocks.contains(t),
            () => setState(() => _timeBlocks.contains(t) ? _timeBlocks.remove(t) : _timeBlocks.add(t)),
          )).toList(),
        ),
      ],
    );
  }

  // ── Step 4 — Study Style ──────────────────────────────────────────────────
  Widget _buildStudyStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roleBadge(),
        const SizedBox(height: 20),
        _label(_isTutor ? 'Your teaching & learning style' : 'Pick your study style'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            ..._learnStyles.map((s) => _styleCard(
              s.$1, s.$2, s.$3,
              _learningStyles.contains(s.$2),
              () => setState(() => _learningStyles.contains(s.$2)
                  ? _learningStyles.remove(s.$2)
                  : _learningStyles.add(s.$2)),
            )),
            ..._studyFmts.map((s) => _styleCard(
              s.$1, s.$2, s.$3,
              _studyStyles.contains(s.$2),
              () => setState(() => _studyStyles.contains(s.$2)
                  ? _studyStyles.remove(s.$2)
                  : _studyStyles.add(s.$2)),
            )),
          ],
        ),
      ],
    );
  }

  // ── Role badge ────────────────────────────────────────────────────────────
  Widget _roleBadge() {
    final color = _isTutor ? AppTheme.success : const Color(0xFF3B82F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isTutor ? '🏫' : '🎓', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            _isTutor ? 'Tutor — setting up your teaching profile' : 'Student — setting up your learning profile',
            style: TextStyle(
              color: _isTutor ? AppTheme.success : const Color(0xFF60A5FA),
              fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Style card ────────────────────────────────────────────────────────────
  Widget _styleCard(String emoji, String label, String sub, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.2) : const Color(0xFF0F0B1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
                color: selected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(sub, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Poppins'));

  Widget _textField(TextEditingController ctrl, String hint, {IconData? icon}) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
          prefixIcon: icon != null ? Icon(icon, color: AppTheme.textMuted, size: 20) : null,
          filled: true,
          fillColor: AppTheme.inputBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
        ),
      );

  Widget _dropdown({required String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) =>
      Container(
        decoration: BoxDecoration(
          color: AppTheme.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(hint, style: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins')),
            ),
            isExpanded: true,
            dropdownColor: AppTheme.bgCard,
            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            borderRadius: BorderRadius.circular(10),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color? selectedColor}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? (selectedColor ?? AppTheme.primary).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? (selectedColor ?? AppTheme.primary) : AppTheme.divider),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? (selectedColor ?? AppTheme.primaryLight) : AppTheme.textSecondary,
                fontFamily: 'Poppins', fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Role Card Widget
// ═════════════════════════════════════════════════════════════════════════════
class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<String> features;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.badge, required this.badgeColor, required this.features,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.12) : const Color(0xFF0F0B1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: TextStyle(
                              color: selected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: badgeColor.withOpacity(0.4)),
                            ),
                            child: Text(badge, style: TextStyle(
                                color: badgeColor, fontSize: 10,
                                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12, fontFamily: 'Poppins', height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppTheme.primary : Colors.transparent,
                    border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: 2),
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 14),
              const Divider(color: AppTheme.divider, height: 1),
              const SizedBox(height: 12),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(f, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Poppins', height: 1.4)),
              )),
            ],
          ],
        ),
      ),
    );
  }
}