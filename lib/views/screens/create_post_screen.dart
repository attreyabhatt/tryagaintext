import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../../services/community_guidelines_service.dart';
import 'blur_editor_screen.dart';
import 'settings_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final String? prefillBody;
  final String? prefillTitle;
  final String? prefillCategory;
  final File? prefillImage;
  final bool prefillPoll;

  const CreatePostScreen({
    super.key,
    this.prefillBody,
    this.prefillTitle,
    this.prefillCategory,
    this.prefillImage,
    this.prefillPoll = false,
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
  bool _isProcessingImage = false;
  bool _isAnonymous = false;
  bool _addPoll = false;

  List<({String value, String label})> _categories(BuildContext context) {
    final l10n = context.l10n;
    return [
      (value: 'help_me_reply', label: l10n.communityCategoryHelpMeReply),
      (value: 'dating_advice', label: l10n.communityCategoryDatingAdvice),
      (value: 'rate_my_profile', label: l10n.communityCategoryRateMyProfile),
      (value: 'wins', label: l10n.communityCategoryWins),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefillBody != null) _bodyController.text = widget.prefillBody!;
    if (widget.prefillTitle != null) {
      _titleController.text = widget.prefillTitle!;
    }
    if (widget.prefillCategory != null) {
      _selectedCategory = widget.prefillCategory;
    }
    if (widget.prefillImage != null && widget.prefillImage!.existsSync()) {
      _image = widget.prefillImage;
    }
    if (widget.prefillPoll) _addPoll = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isProcessingImage) return;
    HapticFeedback.selectionClick();
    setState(() => _isProcessingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;

      // Crop step
      final cropped = await _cropImage(picked.path);
      if (cropped == null || !mounted) return;
      if (!mounted) return;
      setState(() => _image = cropped);
    } catch (_) {
      if (mounted) {
        _showError('Could not process image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  Future<File?> _cropImage(String sourcePath) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: context.l10n.createPostAdjustPhoto,
          toolbarColor: cs.surface,
          toolbarWidgetColor: cs.onSurface,
          activeControlsWidgetColor: cs.primary,
          backgroundColor: cs.surface,
          dimmedLayerColor: cs.scrim.withValues(alpha: isLight ? 0.42 : 0.62),
          cropFrameColor: cs.primary,
          cropGridColor: cs.outline.withValues(alpha: 0.5),
          cropFrameStrokeWidth: 2,
          cropGridStrokeWidth: 1,
          statusBarLight: isLight,
          navBarLight: isLight,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: context.l10n.createPostAdjustPhoto,
          doneButtonTitle: context.l10n.createPostDone,
          cancelButtonTitle: 'Cancel',
          showCancelConfirmationDialog: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );
    if (croppedFile != null) return File(croppedFile.path);
    return null;
  }

  Future<void> _recropCurrentImage() async {
    if (_isProcessingImage || _image == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isProcessingImage = true);
    try {
      final cropped = await _cropImage(_image!.path);
      if (!mounted || cropped == null) return;
      setState(() => _image = cropped);
    } catch (_) {
      if (mounted) {
        _showError('Could not process image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _blurCurrentImage() async {
    if (_isProcessingImage || _image == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isProcessingImage = true);
    try {
      final blurred = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (_) => BlurEditorScreen(imageFile: _image!)),
      );
      if (!mounted || blurred == null) return;
      setState(() => _image = blurred);
    } catch (_) {
      if (mounted) {
        _showError('Could not process image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  Widget _buildImagePreviewActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Future<void> _showSelectedImagePreview() async {
    final image = _image;
    if (image == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () {},
                      child: Image.file(image, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Close image preview',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      _showError(context.l10n.createPostValidationTitle);
      return;
    }
    if (body.isEmpty) {
      _showError(context.l10n.createPostValidationContent);
      return;
    }
    if (_selectedCategory == null) {
      _showError(context.l10n.createPostValidationCategory);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final l10n = context.l10n;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/icons/appstore_transparent.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: tt.headlineSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  l10n.communityTitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                          color: cs.primary.withValues(
                            alpha: isLight ? 0.15 : 0.3,
                          ),
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
                            l10n.createPostPostButton,
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
          IconButton(
            onPressed: _openSettings,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
                color: Colors.transparent,
              ),
              child: Icon(
                Icons.settings_outlined,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
              l10n.createPostCategoryLabel,
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories(context).map((cat) {
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
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
              l10n.createPostTitleLabel,
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
                hintText: l10n.createPostTitleHint,
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
              textInputAction: TextInputAction.next,
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
              l10n.createPostContentLabel,
              style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                hintText: l10n.createPostContentHint,
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
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),

            const SizedBox(height: 24),

            // Image picker
            if (_image != null) ...[
              Stack(
                children: [
                  GestureDetector(
                    onTap: _showSelectedImagePreview,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        _buildImagePreviewActionButton(
                          icon: Icons.crop_outlined,
                          tooltip: l10n.createPostCropPhoto,
                          onTap: _isProcessingImage
                              ? null
                              : _recropCurrentImage,
                        ),
                        const SizedBox(width: 8),
                        _buildImagePreviewActionButton(
                          icon: Icons.blur_on_outlined,
                          tooltip: l10n.createPostBlurSensitiveInfo,
                          onTap: _isProcessingImage ? null : _blurCurrentImage,
                        ),
                      ],
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
              onPressed: _isProcessingImage ? null : _pickImage,
              icon: _isProcessingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_outlined),
              label: Text(
                _isProcessingImage
                    ? l10n.createPostProcessingPhoto
                    : (_image == null ? l10n.createPostAddPhoto : l10n.createPostChangePhoto),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.createPostPhotoTip,
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
              title: Text(l10n.createPostHideUsername, style: tt.bodyMedium),
              subtitle: Text(
                l10n.createPostPostAnonymously,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              secondary: Icon(
                Icons.visibility_off_outlined,
                color: cs.onSurfaceVariant,
              ),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              value: _addPoll,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _addPoll = v);
              },
              title: Text(l10n.createPostAddPoll, style: tt.bodyMedium),
              subtitle: Text(
                l10n.createPostPollSubtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              secondary: Icon(Icons.poll_outlined, color: cs.onSurfaceVariant),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
