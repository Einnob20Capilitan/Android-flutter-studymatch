import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  late final TextEditingController _bioCtrl;

  String? _selectedTopic;
  DateTime? _dob;
  String? _selectedGender;
  String? _selectedDepartment;
  late final TextEditingController _degreeCtrl;

  late Set<String> _selectedSubjects;
  late Set<String> _selectedStrengths;
  late Set<String> _selectedWeaknesses;
  late Set<String> _selectedLearningStyles;
  late Set<String> _selectedStudyStyles;
  late Map<String, Set<String>> _availability;
  late Set<String> _selectedDays;
  bool _saving = false;

  // ✅ Photo upload state
  Uint8List? _photoBytes;
  String?    _photoFileName;
  bool       _uploadingPhoto = false;

  static const _subjectList = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English',
    'Computer Science', 'History', 'Geography', 'Economics', 'Psychology',
    'Literature', 'Statistics', 'Calculus', 'Algebra',
    'Organic Chemistry', 'Programming',
  ];
  static const _deptList = ['CTE', 'CAS', 'CET', 'CBE', 'CCJ', 'COAHS'];
  static const _dayList  = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _timeList = [
    'Morning (6am-12pm)', 'Afternoon (12pm-6pm)',
    'Evening (6pm-9pm)',  'Night (9pm-6am)',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser!;
    _nameCtrl   = TextEditingController(text: user.fullName);
    _schoolCtrl = TextEditingController(text: user.school ?? '');
    _bioCtrl    = TextEditingController(text: user.bio ?? '');
    _degreeCtrl = TextEditingController(
        text: user.isTutor ? (user.department ?? '') : '');

    _selectedTopic      = user.topic;
    _dob                = user.dateOfBirth;
    _selectedGender     = user.gender;
    _selectedDepartment = user.isStudent ? user.department : null;

    _selectedSubjects       = Set.from(user.subjects);
    _selectedStrengths      = Set.from(user.strengths);
    _selectedWeaknesses     = Set.from(user.weaknesses);
    _selectedLearningStyles = Set.from(user.learningStyles);
    _selectedStudyStyles    = Set.from(user.studyStyles);
    _availability =
        user.availability.map((k, v) => MapEntry(k, Set<String>.from(v)));
    _selectedDays = Set.from(_availability.keys);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    _bioCtrl.dispose();
    _degreeCtrl.dispose();
    super.dispose();
  }

  bool get _isTutor =>
      context.read<AppState>().currentUser?.role == 'tutor';

  // ✅ Pick photo from gallery or camera
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppTheme.primaryLight),
              title: const Text('Take Photo',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontFamily: 'Poppins')),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (img != null) {
                  final bytes = await img.readAsBytes();
                  setState(() {
                    _photoBytes    = bytes;
                    _photoFileName = img.name;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primaryLight),
              title: const Text('Choose from Gallery',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontFamily: 'Poppins')),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (img != null) {
                  final bytes = await img.readAsBytes();
                  setState(() {
                    _photoBytes    = bytes;
                    _photoFileName = img.name;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final avail = <String, List<String>>{};
    for (final day in _selectedDays) {
      avail[day] = (_availability[day] ?? <String>{}).toList();
    }

    // ✅ Upload photo first if one was picked
    String? photoUrl;
    if (_photoBytes != null && _photoFileName != null) {
      setState(() => _uploadingPhoto = true);
      final uploadResult = await context.read<AppState>().uploadProfilePhoto(
        photoBytes: _photoBytes!,
        fileName:   _photoFileName!,
      );
      setState(() => _uploadingPhoto = false);
      if (uploadResult != null) {
        photoUrl = uploadResult;
      }
    }

    final fields = <String, dynamic>{
      'fullName':      _nameCtrl.text.trim(),
      'school':        _schoolCtrl.text.trim(),
      'bio':           _bioCtrl.text.trim(),
      'topic':         _selectedTopic,
      'dateOfBirth':   _dob?.toIso8601String(),
      'gender':        _selectedGender,
      'department':    _isTutor
          ? _degreeCtrl.text.trim()
          : _selectedDepartment,
      'subjects':      _selectedSubjects.toList(),
      'strengths':     _selectedStrengths.toList(),
      'weaknesses':    _selectedWeaknesses.toList(),
      'learningStyles': _selectedLearningStyles.toList(),
      'studyStyles':   _selectedStudyStyles.toList(),
      'availability':  avail,
    };

    // ✅ Include the new photo URL if upload succeeded
    if (photoUrl != null) {
      fields['profilePhotoUrl'] = photoUrl;
    }

    final error = await context.read<AppState>().saveProfile(fields);

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Profile updated!'),
        backgroundColor: error == null ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (error == null) Navigator.of(context).pop();
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
                  if (_isTutor)
                    _buildSection(
                      icon: Icons.emoji_events_outlined,
                      title: 'Expert Subjects (Can Tutor)',
                      child: _buildStrengths(),
                    ),
                  if (!_isTutor)
                    _buildSection(
                      icon: Icons.help_outline,
                      title: 'Needs Help With',
                      child: _buildWeaknesses(),
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
                      isLoading: _saving || _uploadingPhoto,
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
      title: const Text('Edit Profile',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 18)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: (_saving || _uploadingPhoto)
              ? const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryLight),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
        ),
      ],
    );
  }

  // ✅ Avatar header — now tappable and shows picked image preview
  Widget _buildAvatarHeader() {
    final name    = _nameCtrl.text;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final existingPhotoUrl =
        context.read<AppState>().currentUser?.profilePhotoUrl;

    return GestureDetector(
      onTap: _pickPhoto, // ✅ whole area tappable
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2D1F5E), Color(0xFF1A0A3A)],
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Stack(
              children: [
                // ✅ Show picked photo, existing photo URL, or initials
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: (_photoBytes == null && (existingPhotoUrl == null || existingPhotoUrl.isEmpty))
                        ? const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent])
                        : null,
                    shape: BoxShape.circle,
                    border: _photoBytes != null
                        ? Border.all(color: AppTheme.success, width: 3)
                        : null,
                  ),
                  child: ClipOval(
                    child: _photoBytes != null
                        ? Image.memory(_photoBytes!, fit: BoxFit.cover,
                            width: 88, height: 88)
                        : (existingPhotoUrl != null && existingPhotoUrl.isNotEmpty)
                            ? Image.network(existingPhotoUrl,
                                fit: BoxFit.cover, width: 88, height: 88,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(initial,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36,
                                          fontFamily: 'Poppins')),
                                ))
                            : Center(
                                child: Text(initial,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36,
                                        fontFamily: 'Poppins')),
                              ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _photoBytes != null
                          ? AppTheme.success
                          : AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bgDark, width: 2),
                    ),
                    child: Icon(
                      _photoBytes != null
                          ? Icons.check_rounded
                          : Icons.camera_alt_rounded,
                      color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _photoBytes != null
                  ? 'Photo selected — tap Save to upload'
                  : 'Tap to change photo',
              style: TextStyle(
                  color: _photoBytes != null
                      ? AppTheme.success
                      : AppTheme.textMuted,
                  fontSize: 12,
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
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
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryLight, size: 17),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Padding(padding: const EdgeInsets.all(16), child: child),
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
          validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'School / University',
          hint: 'e.g. University of Mindanao',
          controller: _schoolCtrl,
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Bio (Optional)'),
        const SizedBox(height: 6),
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: _isTutor
                ? 'Tell students about your teaching approach...'
                : 'Tell others about yourself...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
            filled: true,
            fillColor: AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
        const SizedBox(height: 14),
        _DatePickerField(label: 'Date of Birth', value: _dob,
            onChanged: (v) => setState(() => _dob = v)),
        const SizedBox(height: 14),
        _DropdownField(
          label: 'Gender', hint: 'Select gender', value: _selectedGender,
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
        if (_isTutor) ...[
          _fieldLabel('College Degree'),
          const SizedBox(height: 6),
          TextField(
            controller: _degreeCtrl,
            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. BS Computer Science',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
              prefixIcon: const Icon(Icons.workspace_premium_outlined, color: AppTheme.textMuted, size: 20),
              filled: true,
              fillColor: AppTheme.inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary)),
            ),
          ),
        ] else ...[
          _fieldLabel('College Department'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _deptList.map((d) => SelectableChip(
              label: d,
              selected: _selectedDepartment == d,
              onTap: () => setState(() =>
                  _selectedDepartment = _selectedDepartment == d ? null : d),
            )).toList(),
          ),
        ],
        const SizedBox(height: 16),
        _DropdownField(
          label: 'Strand / Track (Optional)',
          hint: 'Select strand or track',
          value: _selectedTopic,
          items: const ['STEM', 'ABM', 'HUMSS', 'GAS', 'TVL'],
          onChanged: (v) => setState(() => _selectedTopic = v),
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('${_selectedSubjects.length} selected',
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontFamily: 'Poppins')),
          ),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => SelectableChip(
            label: s,
            selected: _selectedSubjects.contains(s),
            onTap: () => setState(() => _selectedSubjects.contains(s)
                ? _selectedSubjects.remove(s) : _selectedSubjects.add(s)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStrengths() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Students weak in these subjects will be matched with you',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => SelectableChip(
            label: s,
            selected: _selectedStrengths.contains(s),
            selectedColor: AppTheme.success,
            onTap: () => setState(() => _selectedStrengths.contains(s)
                ? _selectedStrengths.remove(s) : _selectedStrengths.add(s)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildWeaknesses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tutors strong in these subjects will be prioritised in your matches',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _subjectList.map((s) => SelectableChip(
            label: s,
            selected: _selectedWeaknesses.contains(s),
            selectedColor: AppTheme.error,
            onTap: () => setState(() => _selectedWeaknesses.contains(s)
                ? _selectedWeaknesses.remove(s) : _selectedWeaknesses.add(s)),
          )).toList(),
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
          ('Visual',          Icons.visibility_outlined),
          ('Auditory',        Icons.headphones_outlined),
          ('Kinesthetic',     Icons.sports_handball_outlined),
          ('Reading/Writing', Icons.menu_book_outlined),
        ].map((pair) => _StyleOptionTile(
          icon: pair.$2, label: pair.$1,
          selected: _selectedLearningStyles.contains(pair.$1),
          onTap: () => setState(() => _selectedLearningStyles.contains(pair.$1)
              ? _selectedLearningStyles.remove(pair.$1)
              : _selectedLearningStyles.add(pair.$1)),
        )),
        const SizedBox(height: 20),
        _sectionLabel('STUDY FORMAT'),
        const SizedBox(height: 10),
        Row(
          children: ['Group', 'Individual'].map((s) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: s == 'Group' ? 8 : 0),
              child: SelectableChip(
                label: s,
                selected: _selectedStudyStyles.contains(s),
                onTap: () => setState(() => _selectedStudyStyles.contains(s)
                    ? _selectedStudyStyles.remove(s)
                    : _selectedStudyStyles.add(s)),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('DAYS AVAILABLE'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _dayList.map((day) => SelectableChip(
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
          )).toList(),
        ),
        if (_selectedDays.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionLabel('TIME BLOCKS'),
          const SizedBox(height: 10),
          ..._dayList.where((d) => _selectedDays.contains(d)).map((day) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(day,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          fontSize: 13)),
                ),
                ..._timeList.map((time) {
                  final isSelected = _availability[day]?.contains(time) ?? false;
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.chipSelected : AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(time,
                              style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins'));

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
          letterSpacing: 0.8));
}

// ── Shared field widgets ──────────────────────────────────────────────────────

class SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppTheme.divider),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : AppTheme.textSecondary,
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label, hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label, required this.hint, this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13,
                fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
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
                child: Text(hint,
                    style: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins')),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.bgCard,
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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

  const _DatePickerField({required this.label, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13,
                fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
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
                        primary: AppTheme.primary, surface: AppTheme.bgCard)),
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
                const Icon(Icons.calendar_today_outlined, color: AppTheme.textMuted, size: 18),
                const SizedBox(width: 10),
                Text(
                  value != null
                      ? '${value!.month.toString().padLeft(2, '0')}/${value!.day.toString().padLeft(2, '0')}/${value!.year}'
                      : 'Select date',
                  style: TextStyle(
                      color: value != null ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontFamily: 'Poppins', fontSize: 14),
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

  const _StyleOptionTile({required this.icon, required this.label,
      required this.selected, required this.onTap});

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
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : AppTheme.textMuted, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    fontSize: 14)),
            const Spacer(),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0,
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}