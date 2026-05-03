import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _schoolCtrl;

  String? _selectedTopic;
  DateTime? _dob;
  String? _selectedGender;
  String? _selectedEnrollment;
  late Set<String> _selectedSubjects;
  late Set<String> _selectedLearningStyles;
  late Set<String> _selectedStudyStyles;
  late Map<String, Set<String>> _availability;
  late Set<String> _selectedDays;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser!;
    _nameCtrl = TextEditingController(text: user.fullName);
    _schoolCtrl = TextEditingController(text: user.school ?? '');
    _selectedTopic = user.topic;
    _dob = user.dateOfBirth;
    _selectedGender = user.gender;
    _selectedEnrollment = user.yearLevel;
    _selectedSubjects = Set.from(user.subjects);
    _selectedLearningStyles = Set.from(user.learningStyles);
    _selectedStudyStyles = Set.from(user.studyStyles);
    _availability =
        user.availability.map((k, v) => MapEntry(k, Set<String>.from(v)));
    _selectedDays = Set.from(_availability.keys);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AppState>().saveProfile({
      'fullName': _nameCtrl.text.trim(),
      'school': _schoolCtrl.text.trim(),
      'topic': _selectedTopic,
      'dateOfBirth': _dob,
      'gender': _selectedGender,
      'yearLevel': _selectedEnrollment,
      'subjects': _selectedSubjects.toList(),
      'learningStyles': _selectedLearningStyles.toList(),
      'studyStyles': _selectedStudyStyles.toList(),
      'availability': _availability.map((k, v) => MapEntry(k, v.toList())),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatarHeader(),
                  _buildSection(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    child: _buildPersonalInfo(),
                  ),
                  _buildSection(
                    icon: Icons.school_outlined,
                    title: 'Academic Details',
                    child: _buildAcademicDetails(),
                  ),
                  _buildSection(
                    icon: Icons.menu_book_outlined,
                    title: 'Subjects',
                    child: _buildSubjects(),
                  ),
                  _buildSection(
                    icon: Icons.psychology_outlined,
                    title: 'Study Style',
                    child: _buildStudyStyle(),
                  ),
                  _buildSection(
                    icon: Icons.calendar_month_outlined,
                    title: 'Availability',
                    child: _buildAvailability(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                    child: GradientButton(
                      text: 'Save Changes',
                      onPressed: _save,
                      isLoading: _saving,
                      icon: Icons.check_rounded,
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

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF120D2A),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textSecondary, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _saving
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryLight),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAvatarHeader() {
    final name = _nameCtrl.text;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1F5E), Color(0xFF1A0A3A)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.bgDark, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the camera to change photo',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryLight, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        AppTextField(
          label: 'Full Name',
          hint: 'Juan dela Cruz',
          controller: _nameCtrl,
          prefixIcon: Icons.person_outline,
          validator: (v) => (v == null || v.trim().length < 2)
              ? 'Enter your full name'
              : null,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'School / University',
          hint: 'e.g. Ateneo de Davao University',
          controller: _schoolCtrl,
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 14),
        _DatePickerField(
          label: 'Date of Birth',
          value: _dob,
          onChanged: (v) => setState(() => _dob = v),
        ),
        const SizedBox(height: 14),
        _DropdownField(
          label: 'Gender',
          hint: 'Select gender',
          value: _selectedGender,
          items: const ['Male', 'Female', 'Non-Binary', 'Prefer not to say'],
          onChanged: (v) => setState(() => _selectedGender = v),
        ),
      ],
    );
  }

  Widget _buildAcademicDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DropdownField(
          label: 'Strand / Track',
          hint: 'Select strand or track',
          value: _selectedTopic,
          items: const ['STEM', 'ABM', 'HUMSS', 'GAS', 'TVL'],
          onChanged: (v) => setState(() => _selectedTopic = v),
        ),
        const SizedBox(height: 16),
        _labelText('College Enrollment'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['CTE', 'CAS', 'CET', 'CBE', 'CCJ', 'COAHS']
              .map((e) => SelectableChip(
                    label: e,
                    selected: _selectedEnrollment == e,
                    onTap: () => setState(() => _selectedEnrollment =
                        _selectedEnrollment == e ? null : e),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedSubjects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_selectedSubjects.length} selected',
              style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 13,
                  fontFamily: 'Poppins'),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Mathematics',
            'Physics',
            'Chemistry',
            'Biology',
            'English',
            'Computer Science',
            'History',
            'Geography',
            'Economics',
            'Psychology',
            'Literature',
            'Statistics',
            'Calculus',
            'Algebra',
            'Organic Chemistry',
            'Programming',
          ]
              .map((s) => SelectableChip(
                    label: s,
                    selected: _selectedSubjects.contains(s),
                    onTap: () => setState(() => _selectedSubjects.contains(s)
                        ? _selectedSubjects.remove(s)
                        : _selectedSubjects.add(s)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStudyStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('LEARNING STYLE'),
        const SizedBox(height: 10),
        ...[
          ('Visual', Icons.visibility_outlined),
          ('Auditory', Icons.headphones_outlined),
          ('Kinesthetic', Icons.sports_handball_outlined),
          ('Reading/Writing', Icons.menu_book_outlined),
        ].map(
          (pair) => _StyleOptionTile(
            icon: pair.$2,
            label: pair.$1,
            selected: _selectedLearningStyles.contains(pair.$1),
            onTap: () => setState(() =>
                _selectedLearningStyles.contains(pair.$1)
                    ? _selectedLearningStyles.remove(pair.$1)
                    : _selectedLearningStyles.add(pair.$1)),
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('STUDY FORMAT'),
        const SizedBox(height: 10),
        Row(
          children: ['Group', 'Individual']
              .map((s) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: s == 'Group' ? 8 : 0),
                      child: SelectableChip(
                        label: s,
                        selected: _selectedStudyStyles.contains(s),
                        onTap: () => setState(() =>
                            _selectedStudyStyles.contains(s)
                                ? _selectedStudyStyles.remove(s)
                                : _selectedStudyStyles.add(s)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAvailability() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const timeBlocks = [
      'Morning (6am-9pm)',
      'Morning (10am-12pm)',
      'Afternoon (1pm-4pm)',
      'Evening (5pm-8pm)',
      'Night (8pm-11pm)',
      'Late Night (11pm-2am)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('DAYS AVAILABLE'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days
              .map((day) => SelectableChip(
                    label: day.substring(0, 3),
                    selected: _selectedDays.contains(day),
                    onTap: () => setState(() {
                      if (_selectedDays.contains(day)) {
                        _selectedDays.remove(day);
                        _availability.remove(day);
                      } else {
                        _selectedDays.add(day);
                        _availability[day] = {};
                      }
                    }),
                  ))
              .toList(),
        ),
        if (_selectedDays.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionLabel('TIME BLOCKS'),
          const SizedBox(height: 10),
          ...days.where((d) => _selectedDays.contains(d)).map((day) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ...timeBlocks.map((time) {
                    final isSelected =
                        _availability[day]?.contains(time) ?? false;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _availability.putIfAbsent(day, () => {});
                        if (_availability[day]!.contains(time)) {
                          _availability[day]!.remove(time);
                        } else {
                          _availability[day]!.add(time);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.chipSelected
                              : AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              time,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              )),
        ],
      ],
    );
  }

  Widget _labelText(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
          letterSpacing: 0.8,
        ),
      );
}

// ── Local field widgets ────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label, hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.hint,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  hint,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontFamily: 'Poppins'),
                ),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.bgCard,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontFamily: 'Poppins'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(2000),
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
            if (picked != null) onChanged(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppTheme.textMuted, size: 18),
                const SizedBox(width: 10),
                Text(
                  value != null
                      ? '${value!.month.toString().padLeft(2, '0')}/'
                          '${value!.day.toString().padLeft(2, '0')}/'
                          '${value!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: value != null
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StyleOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.chipSelected : AppTheme.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : AppTheme.textMuted, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0,
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
