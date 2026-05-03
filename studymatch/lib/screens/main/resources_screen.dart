import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/app_theme.dart';
import '../../services/app_state.dart';
import '../../models/models.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  final List<String> _filters = ['All', 'Mathematics', 'Physics', 'Chemistry',
      'Biology', 'Computer Science', 'History', 'Statistics', 'English'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadResources();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    context.read<AppState>().loadResources(
      subject: _filter == 'All' ? null : _filter,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Resource Library',
                            style: TextStyle(color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Poppins')),
                        GestureDetector(
                          onTap: () => _showUploadDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(children: [
                              Icon(Icons.add, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Upload', style: TextStyle(color: Colors.white,
                                  fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
                            decoration: const InputDecoration(
                              hintText: 'Search resources...',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'),
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _search,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Filter chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final f = _filters[i];
                          final sel = _filter == f;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _filter = f);
                              context.read<AppState>().loadResources(
                                subject: f == 'All' ? null : f,
                                search: _searchCtrl.text.trim().isEmpty
                                    ? null : _searchCtrl.text.trim(),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel ? AppTheme.primary : AppTheme.inputBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel ? AppTheme.primary : AppTheme.divider),
                              ),
                              child: Text(f, style: TextStyle(
                                color: sel ? Colors.white : AppTheme.textSecondary,
                                fontFamily: 'Poppins', fontSize: 12,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                              )),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('${state.dbResources.length} Resources',
                        style: const TextStyle(color: AppTheme.textMuted,
                            fontSize: 13, fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (state.loadingResources)
              const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )),
              )
            else if (state.dbResources.isEmpty)
              const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(Icons.library_books_outlined, color: AppTheme.textMuted, size: 48),
                    SizedBox(height: 16),
                    Text('No resources yet.\nBe the first to upload!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted,
                            fontFamily: 'Poppins', height: 1.5)),
                  ]),
                )),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ResourceCard(resource: state.dbResources[i]),
                    ),
                    childCount: state.dbResources.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    String? subject;
    Uint8List? fileBytes;
    String? fileName;
    bool uploading = false;

    final subjects = ['Mathematics','Physics','Chemistry','Biology',
        'Computer Science','English','History','Statistics'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload Resource',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
              const SizedBox(height: 20),
              // Title
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  labelText: 'Title *',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true, fillColor: AppTheme.inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.divider)),
                ),
              ),
              const SizedBox(height: 12),
              // Subject dropdown
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.inputBg, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: subject,
                    hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Select Subject *',
                            style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Poppins'))),
                    isExpanded: true,
                    dropdownColor: AppTheme.bgCard,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setS(() => subject = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Description
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true, fillColor: AppTheme.inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.divider)),
                ),
              ),
              const SizedBox(height: 12),
              // File picker
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
                    withData: true,
                  );
                  if (result != null && result.files.single.bytes != null) {
                    setS(() {
                      fileBytes = result.files.single.bytes;
                      fileName  = result.files.single.name;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: fileBytes != null
                        ? AppTheme.success.withOpacity(0.1) : AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: fileBytes != null ? AppTheme.success : AppTheme.divider),
                  ),
                  child: Row(children: [
                    Icon(
                      fileBytes != null ? Icons.check_circle : Icons.upload_file,
                      color: fileBytes != null ? AppTheme.success : AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      fileName ?? 'Tap to select file (PDF, DOC, DOCX, PPT, TXT)',
                      style: TextStyle(
                        color: fileBytes != null ? AppTheme.success : AppTheme.textMuted,
                        fontFamily: 'Poppins', fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (uploading || fileBytes == null ||
                      titleCtrl.text.trim().isEmpty || subject == null)
                      ? null
                      : () async {
                          setS(() => uploading = true);
                          final result = await context.read<AppState>().uploadResource(
                            title: titleCtrl.text.trim(),
                            subject: subject!,
                            description: descCtrl.text.trim(),
                            fileBytes: fileBytes!,
                            fileName: fileName!,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(result['success'] == true
                                  ? 'Resource uploaded!' : result['message'] ?? 'Upload failed'),
                              backgroundColor: result['success'] == true
                                  ? AppTheme.success : AppTheme.error,
                            ));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: uploading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Upload Resource',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final DBResource resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(resource.subject);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 74,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_typeIcon(resource.fileType), color: color, size: 28),
                const SizedBox(height: 4),
                Text(resource.fileType.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 9,
                        fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.title,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins'),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (resource.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(resource.description,
                      style: const TextStyle(color: AppTheme.textMuted,
                          fontSize: 12, fontFamily: 'Poppins', height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(resource.subject,
                        style: TextStyle(color: color, fontSize: 11,
                            fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Text('by ${resource.uploaderName}',
                      style: const TextStyle(color: AppTheme.textMuted,
                          fontSize: 11, fontFamily: 'Poppins')),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (resource.fileUrl != null)
            IconButton(
              icon: const Icon(Icons.download_outlined, color: AppTheme.textMuted, size: 22),
              onPressed: () {
                // Open file URL
                // You can use url_launcher package:
                // launchUrl(Uri.parse(resource.fileUrl!));
              },
            ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'doc': case 'docx': return Icons.description_outlined;
      case 'ppt': case 'pptx': return Icons.slideshow_outlined;
      case 'txt': return Icons.text_snippet_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _subjectColor(String subject) {
    const colors = [AppTheme.primary, AppTheme.accent, AppTheme.success,
        AppTheme.warning, Color(0xFF3B82F6), Color(0xFFEC4899)];
    return colors[subject.hashCode % colors.length];
  }
}