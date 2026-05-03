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
  // Step 0 — Basic Info
  final _schoolCtrl = TextEditingController();
  final _bioCtrl    = TextEditingController();
  String? _gender;
  DateTime? _dob;
  String? _department;

  // Step 1 — Subjects
  final Set<String> _subjects   = {};
  final Set<String> _strengths  = {};
  final Set<String> _weaknesses = {};

  // Step 2 — Schedule
  final Set<String> _days       = {};
  final Set<String> _timeBlocks = {};

  // Step 3 — Study Style
  final Set<String> _learningStyles = {};
  final Set<String> _studyStyles    = {};

  bool _saving = false;

  static const _subjectList = [
    'Mathematics','Physics','Chemistry','Biology','English',
    'Computer Science','History','Economics','Statistics','Filipino',
  ];
  static const _deptList = ['CET','CTE','CCJ','CAS','CBE','COAHS'];
  static const _dayList  = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  static const _timeList = ['Morning (6am-12pm)','Afternoon (12pm-6pm)','Evening (6pm-9pm)','Night (9pm-6am)'];
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

  @override
  void dispose() {
    _schoolCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final state = context.read<AppState>();
    final step  = state.onboardingStep;

    if (step == 0) {
      state.updateUserProfile({
        'school': _schoolCtrl.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dob?.toIso8601String(),
        'department': _department,
        'bio': _bioCtrl.text.trim(),
      });
      state.nextOnboardingStep();
    } else if (step == 1) {
      state.updateUserProfile({
        'subjects': _subjects.toList(),
        'strengths': _strengths.toList(),
        'weaknesses': _weaknesses.toList(),
      });
      state.nextOnboardingStep();
    } else if (step == 2) {
      final avail = <String, List<String>>{};
      for (final d in _days) avail[d] = _timeBlocks.toList();
      state.updateUserProfile({'availability': avail});
      state.nextOnboardingStep();
    } else if (step == 3) {
      state.updateUserProfile({
        'learningStyles': _learningStyles.toList(),
        'studyStyles': _studyStyles.toList(),
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
    final total = state.totalOnboardingSteps;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Icon
            _stepIcon(step),
            const SizedBox(height: 16),
            // Title
            Text(_stepTitle(step),
                style: const TextStyle(color: Colors.white,
                    fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            Text(_stepSubtitle(step),
                style: const TextStyle(color: AppTheme.textSecondary,
                    fontSize: 13, fontFamily: 'Poppins')),
            const SizedBox(height: 20),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: List.generate(total, (i) => Expanded(
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
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.divider),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('← Back',
                            style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Poppins')),
                      ),
                    ),
                  if (step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(step == total - 1 ? '✨ Finish Setup' : 'Next →',
                              style: const TextStyle(fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600, fontSize: 15)),
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

  Widget _stepIcon(int step) {
    const icons = ['🎓', '📖', '📅', '✨'];
    return Text(icons[step], style: const TextStyle(fontSize: 48));
  }

  String _stepTitle(int step) {
    const titles = ['Basic Information', 'Your Subjects', 'Study Schedule', 'Study Style'];
    return titles[step];
  }

  String _stepSubtitle(int step) {
    const subs = [
      'Tell us about your academic background',
      'Select your subjects and set your strengths & weaknesses',
      'When are you available to study?',
      'How do you prefer to learn?',
    ];
    return subs[step];
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0: return _buildBasicInfo();
      case 1: return _buildSubjects();
      case 2: return _buildSchedule();
      case 3: return _buildStudyStyle();
      default: return const SizedBox();
    }
  }

  // ── Step 0: Basic Info ──────────────────────────────────────────────────
  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('School / University'),
        const SizedBox(height: 8),
        _textField(_schoolCtrl, 'e.g. University of Santo Tomas',
            icon: Icons.school_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Column(
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
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
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
                            primary: AppTheme.primary, surface: AppTheme.bgCard)),
                        child: child!),
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
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Text(_dob != null
                          ? '${_dob!.month}/${_dob!.day}/${_dob!.year}'
                          : 'mm/dd/yyyy',
                          style: TextStyle(
                            color: _dob != null ? AppTheme.textPrimary : AppTheme.textMuted,
                            fontFamily: 'Poppins', fontSize: 13)),
                    ]),
                  ),
                ),
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),
        _label('College Department'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
            children: _deptList.map((d) => _chip(d, _department == d,
                () => setState(() => _department = _department == d ? null : d))).toList()),
        const SizedBox(height: 16),
        _label('Bio (Optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins', fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Tell others about yourself...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
            filled: true, fillColor: AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Subjects ────────────────────────────────────────────────────
  Widget _buildSubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Subjects you study'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
            children: _subjectList.map((s) => _chip(s, _subjects.contains(s),
                () => setState(() => _subjects.contains(s)
                    ? _subjects.remove(s) : _subjects.add(s)))).toList()),
        const SizedBox(height: 20),
        _label('💪 Your Strong Subjects'),
        const SizedBox(height: 6),
        const Text('Subjects you can help others with',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
            children: _subjectList.map((s) => _chip(s, _strengths.contains(s),
                () => setState(() => _strengths.contains(s)
                    ? _strengths.remove(s) : _strengths.add(s)),
                selectedColor: AppTheme.success)).toList()),
        const SizedBox(height: 20),
        _label('😅 Your Weak Subjects'),
        const SizedBox(height: 6),
        const Text('Subjects you need help with',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
            children: _subjectList.map((s) => _chip(s, _weaknesses.contains(s),
                () => setState(() => _weaknesses.contains(s)
                    ? _weaknesses.remove(s) : _weaknesses.add(s)),
                selectedColor: AppTheme.error)).toList()),
      ],
    );
  }

  // ── Step 2: Schedule ────────────────────────────────────────────────────
  Widget _buildSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Study Days'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
            children: _dayList.map((d) => _chip(d, _days.contains(d),
                () => setState(() => _days.contains(d)
                    ? _days.remove(d) : _days.add(d)))).toList()),
        const SizedBox(height: 20),
        _label('Time Blocks'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8,
            children: _timeList.map((t) => _chip(t, _timeBlocks.contains(t),
                () => setState(() => _timeBlocks.contains(t)
                    ? _timeBlocks.remove(t) : _timeBlocks.add(t)))).toList()),
      ],
    );
  }

  // ── Step 3: Study Style ─────────────────────────────────────────────────
  Widget _buildStudyStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Pick your study style'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            ..._learnStyles.map((s) => _styleCard(s.$1, s.$2, s.$3,
                _learningStyles.contains(s.$2),
                () => setState(() => _learningStyles.contains(s.$2)
                    ? _learningStyles.remove(s.$2) : _learningStyles.add(s.$2)))),
            ..._studyFmts.map((s) => _styleCard(s.$1, s.$2, s.$3,
                _studyStyles.contains(s.$2),
                () => setState(() => _studyStyles.contains(s.$2)
                    ? _studyStyles.remove(s.$2) : _studyStyles.add(s.$2)))),
          ],
        ),
      ],
    );
  }

  Widget _styleCard(String emoji, String label, String sub, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.2) : const Color(0xFF0F0B1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.divider, width: selected ? 2 : 1),
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
                  style: const TextStyle(color: AppTheme.textMuted,
                      fontSize: 10, fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: const TextStyle(color: AppTheme.textSecondary,
          fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Poppins'));

  Widget _textField(TextEditingController ctrl, String hint, {IconData? icon}) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
          prefixIcon: icon != null ? Icon(icon, color: AppTheme.textMuted, size: 20) : null,
          filled: true, fillColor: AppTheme.inputBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary)),
        ),
      );

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
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
            border: Border.all(
                color: selected ? (selectedColor ?? AppTheme.primary) : AppTheme.divider),
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