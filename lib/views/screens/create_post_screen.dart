import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../services/community_guidelines_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String? prefillBody;
  final String? prefillTitle;
  final String? prefillCategory;

  const CreatePostScreen({
    super.key,
    this.prefillBody,
    this.prefillTitle,
    this.prefillCategory,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _api = ApiClient();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? _selectedCategory;
  File? _image;
  bool _isSubmitting = false;
  bool _isAnonymous = false;
  bool _addPoll = false;

  static const _categories = [
    (value: 'help_me_reply', label: 'Help Me Reply 🚨'),
    (value: 'rate_my_profile', label: 'Rate My Profile 📸'),
    (value: 'wins', label: 'Wins 🏆'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillBody != null) _bodyController.text = widget.prefillBody!;
    if (widget.prefillTitle != null) _titleController.text = widget.prefillTitle!;
    if (widget.prefillCategory != null) _selectedCategory = widget.prefillCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      _showError('Please add a title.');
      return;
    }
    if (body.isEmpty) {
      _showError('Please add some content.');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please choose a category.');
      return;
    }

    // EULA gate — first-time posting requires acceptance
    final accepted = await CommunityGuidelinesService.ensureAccepted(context);
    if (!accepted || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final post = await _api.createCommunityPost(
        title: title,
        body: body,
        category: _selectedCategory!,
        image: _image,
        isAnonymous: _isAnonymous,
        hasPoll: _addPoll,
      );
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context, post);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'New Post',
          style: tt.headlineSmall?.copyWith(
            fontSize: 20,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSubmitting
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: isLight ? 0.85 : 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: isLight ? 0.15 : 0.3),
                          blurRadius: isLight ? 8 : 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Post',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category selector
            Text(
              'Category',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat.value;
                return FilterChip(
                  label: Text(cat.label),
                  selected: selected,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat.value);
                  },
                  showCheckmark: false,
                  selectedColor: cs.secondary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: selected ? cs.secondary : cs.onSurfaceVariant,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: selected
                      ? BorderSide(color: cs.secondary.withValues(alpha: 0.3))
                      : BorderSide.none,
                  backgroundColor: cs.surfaceContainerHighest,
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Title',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                counterText: '',
                filled: false,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.secondary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_titleController.text.length}/200',
                style: tt.bodySmall?.copyWith(
                  color: _titleController.text.length > 180
                      ? cs.error
                      : cs.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Body
            Text(
              'What happened?',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                hintText: 'Share your story, tip, or question...',
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                alignLabelWithHint: true,
                filled: false,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.secondary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              minLines: 5,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
            ),

            const SizedBox(height: 24),

            // Image picker
            if (_image != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _image = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_outlined),
              label: Text(_image == null ? 'Add Photo' : 'Change Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.privacy_tip_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tip: Blur or crop out names, numbers, and faces before sharing.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SwitchListTile(
              value: _isAnonymous,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _isAnonymous = v);
              },
              title: Text('Hide my username', style: tt.bodyMedium),
              subtitle: Text(
                'Post anonymously',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              secondary: Icon(Icons.visibility_off_outlined, color: cs.onSurfaceVariant),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              value: _addPoll,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _addPoll = v);
              },
              title: Text('Add Poll', style: tt.bodyMedium),
              subtitle: Text(
                '"Send it" or "Don\'t send it"',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              secondary: Icon(Icons.poll_outlined, color: cs.onSurfaceVariant),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
